import Combine
import Foundation
import NIO
import NIOHTTP1
import NIOWebSocket

public class Client: ObservableObject {
    private let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    public var channel: Channel? = nil {
        didSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    @Published var controllerIndex: Int? = nil
    
    private var bootstrap: ClientBootstrap {
        ClientBootstrap(group: self.group)
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .channelInitializer { channel in
                let httpHandler = HTTPInitialRequestHandler(host: "192.168.1.39", port: 12345)
                let websocketUpgrader = NIOWebSocketClientUpgrader(requestKey: "testingTODO") { channel, _ in
                    let websocketHandler = ControllerClientWebsocketHandler(delegate: self)
                    return channel.pipeline.addHandler(websocketHandler)
                }
                let config: NIOHTTPClientUpgradeConfiguration = (
                    upgraders: [websocketUpgrader],
                    completionHandler: { _ in
                        channel.pipeline.removeHandler(httpHandler, promise: nil)
                    }
                )
                return channel.pipeline.addHTTPClientHandlers(withClientUpgrade: config).flatMap {
                    channel.pipeline.addHandler(httpHandler)
                }
            }
    }
    
    func connect() -> AnyPublisher<Never, Error> {
        let publisher = PassthroughSubject<Never, Error>()
        if channel?.isActive == true {
            return publisher.eraseToAnyPublisher()
        }
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let channel = try self.bootstrap.connect(host: "192.168.1.39", port: 12345).wait()
                self.channel = channel
                print("\(channel.localAddress?.description ?? "<unknown>") is now open")
                try channel.closeFuture.wait()
            } catch {
                publisher.send(completion: .failure(error))
                print("error: ", error)
            }
            publisher.send(completion: .finished)
            self.channel = nil
            print("Closed")
        }
        return publisher.eraseToAnyPublisher()
    }
    
    func send(_ content: String) {
        guard let channel = self.channel, channel.isActive else { return }

        let buffer = channel.allocator.buffer(string: content)
        let frame = WebSocketFrame(fin: true, opcode: .text, data: buffer)
        channel.writeAndFlush(frame, promise: nil)
    }
    
    func disconnect() -> AnyPublisher<Never, Error> {
        let publisher = PassthroughSubject<Never, Error>()
        _ = self.channel?.close().whenComplete({ result in
            if case .failure(let error) = result {
                publisher.send(completion: .failure(error))
            } else {
                publisher.send(completion: .finished)
            }
            self.channel = nil
        })
        return publisher.eraseToAnyPublisher()
    }
}

private final class HTTPInitialRequestHandler: ChannelInboundHandler, RemovableChannelHandler {
    public typealias InboundIn = HTTPClientResponsePart
    public typealias OutboundOut = HTTPClientRequestPart

    public let host: String
    public let port: Int

    public init(host: String, port: Int) {
        self.host = host
        self.port = port
    }
    
    public func channelActive(context: ChannelHandlerContext) {
        print("Client connected to \(context.remoteAddress!)")

        // We are connected. It's time to send the message to the server to initialize the upgrade dance.
        var headers = HTTPHeaders()
        headers.add(name: "Host", value: "\(host):\(port)")
        headers.add(name: "Content-Type", value: "text/plain; charset=utf-8")
        headers.add(name: "Content-Length", value: "\(0)")
        
        let requestHead = HTTPRequestHead(
            version: .http1_1,
            method: .GET,
            uri: "/",
            headers: headers
        )
        
        context.write(self.wrapOutboundOut(.head(requestHead)), promise: nil)
        let body = HTTPClientRequestPart.body(.byteBuffer(ByteBuffer()))
        context.write(self.wrapOutboundOut(body), promise: nil)
        context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
    }
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let clientResponse = self.unwrapInboundIn(data)
        
        print("Upgrade failed")
        
        switch clientResponse {
        case .head(let responseHead):
            print("Received status: \(responseHead.status)")
        case .body(let byteBuffer):
            let string = String(buffer: byteBuffer)
            print("Received: '\(string)' back from the server.")
        case .end:
            print("Closing channel.")
            context.close(promise: nil)
        }
    }
    
    public func handlerRemoved(context: ChannelHandlerContext) {
        print("HTTP handler removed")
    }
    
    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("error: ", error)
        
        // As we are not really interested getting notified on success or failure
        // we just pass nil as promise to reduce allocations.
        context.close(promise: nil)
    }
}

protocol ControllerClientWebsocketHandlerDelegate {
    func didConnect(index: Int)
    func didDisconnect()
}

extension Client: ControllerClientWebsocketHandlerDelegate {
    func didConnect(index: Int) {
        DispatchQueue.main.sync {
            self.controllerIndex = index
        }
    }
    
    func didDisconnect() {
        DispatchQueue.main.sync {
            self.controllerIndex = nil
        }
    }
}

private final class ControllerClientWebsocketHandler: ChannelInboundHandler {
    typealias InboundIn = WebSocketFrame
    typealias OutboundOut = WebSocketFrame
    
    var delegate: ControllerClientWebsocketHandlerDelegate
    
    init(delegate: ControllerClientWebsocketHandlerDelegate) {
        self.delegate = delegate
    }
    
    public func handlerAdded(context: ChannelHandlerContext) {
        print("WebSocket handler added.")
    }

    public func handlerRemoved(context: ChannelHandlerContext) {
        print("WebSocket handler removed.")
        delegate.didDisconnect()
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let frame = self.unwrapInboundIn(data)
        
        switch frame.opcode {
        case .ping:
            self.handlePing(context: context, frame: frame)
        case .text:
            var data = frame.unmaskedData
            let text = data.readString(length: data.readableBytes) ?? ""
            print("Websocket: Received \(text)")
        case .connectionClose:
            self.receivedClose(context: context, frame: frame)
        case .binary, .continuation, .pong:
            // We ignore these frames.
            break
        default:
            // Unknown frames are errors.
            self.closeOnError(context: context)
        }
    }
    
    public func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
    }

    private func receivedClose(context: ChannelHandlerContext, frame: WebSocketFrame) {
        // Handle a received close frame. We're just going to close.
        print("Received Close instruction from server")
        context.close(promise: nil)
    }
    
    private func handlePing(context: ChannelHandlerContext, frame: WebSocketFrame) {
        print("Ping")
        var frameData = frame.data
        if let frameDataString = frameData.readString(length: 18) {
            print("Websocket: Received: \(frameDataString)")
            if let substr = frameDataString.split(separator: ",").first,
               let index = Int(String(substr)) {
                print("You're controller number \(index+1)")
                delegate.didConnect(index: index)
            }
        }
        
        let maskingKey = frame.maskKey

        if let maskingKey = maskingKey {
            frameData.webSocketUnmask(maskingKey)
        }

        let responseFrame = WebSocketFrame(fin: true, opcode: .pong, data: frameData)
        context.write(self.wrapOutboundOut(responseFrame), promise: nil)
    }
    
    private func closeOnError(context: ChannelHandlerContext) {
        // We have hit an error, we want to close. We do that by sending a close frame and then
        // shutting down the write side of the connection. The server will respond with a close of its own.
        var data = context.channel.allocator.buffer(capacity: 2)
        data.write(webSocketErrorCode: .protocolError)
        let frame = WebSocketFrame(fin: true, opcode: .connectionClose, data: data)
        context.write(self.wrapOutboundOut(frame)).whenComplete { (_: Result<Void, Error>) in
            context.close(mode: .output, promise: nil)
        }
    }
}
