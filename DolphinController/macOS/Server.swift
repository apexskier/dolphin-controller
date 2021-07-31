import Foundation
import NIO
import NIOHTTP1
import NIOWebSocket

enum ServerError: Error {
    case noOpenControllerPorts
}

public class Server {
    private let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    private var upgrader: NIOWebSocketServerUpgrader? = nil
    
    private var host: String
    private var port: Int
    
    private var controllers: [Channel] = []
    
    init(host: String, port: Int) {
        self.host = host
        self.port = port
        
        self.upgrader = NIOWebSocketServerUpgrader(
            shouldUpgrade: { (channel: Channel, head: HTTPRequestHead) in
                channel.eventLoop.makeSucceededFuture(HTTPHeaders())
            },
            upgradePipelineHandler: self.upgradePipelineHandler
        )
    }
    
    func upgradePipelineHandler(channel: Channel, _: HTTPRequestHead) -> EventLoopFuture<Void> {
        self.controllers.append(channel)
        return channel.pipeline.addHandler(WebSocketHandler(index: self.controllers.count-1))
    }
    
    func run() throws {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let channel = try self.serverBootstrap.bind(host: self.host, port: self.port).wait()
                print("\(channel.localAddress!) is now open")
                try channel.closeFuture.wait()
            } catch {
                print("Error: ", error)
            }
        }
    }
    
    func shutdown() throws {
        try group.syncShutdownGracefully()
        print("Server closed")
    }
    
    private var serverBootstrap: ServerBootstrap {
        ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                let httpHandler = WebsocketUpgradeHandler(controllers: &self.controllers)
                let config: NIOHTTPServerUpgradeConfiguration = (
                    upgraders: [self.upgrader!],
                    completionHandler: { _ in
                        channel.pipeline.removeHandler(httpHandler, promise: nil)
                    }
                )
                return channel.pipeline.configureHTTPServerPipeline(withServerUpgrade: config).flatMap {
                    channel.pipeline.addHandler(httpHandler)
                }
            }
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
    }
}

public class WebsocketUpgradeHandler: ChannelInboundHandler, RemovableChannelHandler {
    public typealias InboundIn = HTTPServerRequestPart
    public typealias OutboundOut = HTTPServerResponsePart
    
    private var controllers: [Channel]
    
    init(controllers: inout [Channel]) {
        self.controllers = controllers
    }
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let reqPart = self.unwrapInboundIn(data)
        
        // We're not interested in request bodies here: we're just serving up GET responses
        // to get the client to initiate a websocket request.
        guard case .head(let head) = reqPart else {
            return
        }
        
        guard case .GET = head.method else {
            self.respond405(context: context)
            return
        }
        
        if self.controllers.count >= 4 {
            self.respond409(context: context)
            return
        }
        
        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: "text/html")
        headers.add(name: "Content-Length", value: "0")
        headers.add(name: "Connection", value: "close")
        let responseHead = HTTPResponseHead(version: .http1_1, status: .ok, headers: headers)
        context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
        context.write(self.wrapOutboundOut(.end(nil))).whenComplete { _ in
            context.close(promise: nil)
        }
        context.flush()
    }
    
    private func respond405(context: ChannelHandlerContext) {
        var headers = HTTPHeaders()
        headers.add(name: "Connection", value: "close")
        headers.add(name: "Content-Length", value: "0")
        let head = HTTPResponseHead(
            version: .http1_1,
            status: .methodNotAllowed,
            headers: headers
        )
        context.write(self.wrapOutboundOut(.head(head)), promise: nil)
        context.write(self.wrapOutboundOut(.end(nil))).whenComplete { _ in
            context.close(promise: nil)
        }
        context.flush()
    }
    
    private func respond409(context: ChannelHandlerContext) {
        var headers = HTTPHeaders()
        headers.add(name: "Connection", value: "close")
        headers.add(name: "Content-Length", value: "0")
        let head = HTTPResponseHead(
            version: .http1_1,
            status: .conflict,
            headers: headers
        )
        context.write(self.wrapOutboundOut(.head(head)), promise: nil)
        context.write(self.wrapOutboundOut(.end(nil))).whenComplete { _ in
            context.close(promise: nil)
        }
        context.flush()
    }
    
    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("error: ", error)
        context.close(promise: nil)
    }
}

private final class WebSocketHandler: ChannelInboundHandler {
    typealias InboundIn = WebSocketFrame
    typealias OutboundOut = WebSocketFrame

    private let id = UUID()
    private let index: Int

    private var awaitingClose: Bool = false
    
    init(index: Int) {
        self.index = index
    }

    public func handlerAdded(context: ChannelHandlerContext) {
        print("handler added", id)
        self.ping(context: context)
    }
    
    func handlerRemoved(context: ChannelHandlerContext) {
        print("handler removed", id)
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let frame = self.unwrapInboundIn(data)

        switch frame.opcode {
        case .connectionClose:
            self.receivedClose(context: context, frame: frame)
        case .pong:
            self.pong(context: context, frame: frame)
        case .text:
            var data = frame.unmaskedData
            let text = data.readString(length: data.readableBytes) ?? ""
            print(id, text)
        case .binary, .continuation, .ping:
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
        // Handle a received close frame. In websockets, we're just going to send the close
        // frame and then close, unless we already sent our own close frame.
        if awaitingClose {
            // Cool, we started the close and were waiting for the user. We're done.
            context.close(promise: nil)
        } else {
            // This is an unsolicited close. We're going to send a response frame and
            // then, when we've sent it, close up shop. We should send back the close code the remote
            // peer sent us, unless they didn't send one at all.
            var data = frame.unmaskedData
            let closeDataCode = data.readSlice(length: 2) ?? ByteBuffer()
            let closeFrame = WebSocketFrame(fin: true, opcode: .connectionClose, data: closeDataCode)
            _ = context.write(self.wrapOutboundOut(closeFrame)).map { () in
                context.close(promise: nil)
            }
        }
    }
    
    private func ping(context: ChannelHandlerContext) {
        print("Ping")
        let buffer = context.channel.allocator.buffer(string: "\(self.index),\(self.id)")
        let frame = WebSocketFrame(fin: true, opcode: .ping, data: buffer)
        context.writeAndFlush(self.wrapOutboundOut(frame), promise: nil)
    }

    private func pong(context: ChannelHandlerContext, frame: WebSocketFrame) {
        print("Pong")
//        var frameData = frame.data
//        let maskingKey = frame.maskKey
//
//        if let maskingKey = maskingKey {
//            frameData.webSocketUnmask(maskingKey)
//        }
//
//        let responseFrame = WebSocketFrame(fin: true, opcode: .pong, data: frameData)
//        context.write(self.wrapOutboundOut(responseFrame), promise: nil)
        
        var frameData = frame.data
        if let frameDataString = frameData.readString(length: 18) {
            print("Websocket: Received: \(frameDataString)")
        }
    }

    private func closeOnError(context: ChannelHandlerContext) {
        // We have hit an error, we want to close. We do that by sending a close frame and then
        // shutting down the write side of the connection.
        var data = context.channel.allocator.buffer(capacity: 2)
        data.write(webSocketErrorCode: .protocolError)
        let frame = WebSocketFrame(fin: true, opcode: .connectionClose, data: data)
        context.write(self.wrapOutboundOut(frame)).whenComplete { (_: Result<Void, Error>) in
            context.close(mode: .output, promise: nil)
        }
        awaitingClose = true
    }
}
