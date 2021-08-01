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
        do {
            let index = self.controllers.count
            let websocketHandler = try WebSocketHandler(index: index-1, onClose: { [weak self] in
                guard let self = self else {
                    return
                }
                self.controllers.remove(at: index-1)
            })
            return channel.pipeline.addHandler(websocketHandler)
        } catch {
            fatalError(error.localizedDescription)
        }
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
            .childChannelOption(ChannelOptions.socketOption(.tcp_nodelay), value: 1)
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

private final class WebSocketHandler: NSObject, ChannelInboundHandler {
    typealias InboundIn = WebSocketFrame
    typealias OutboundOut = WebSocketFrame

    private let id = UUID()
    private let index: Int
    private var outputStream: OutputStream
    private var onClose: () -> Void

    private var awaitingClose: Bool = false
    
    init(index: Int, onClose: @escaping () -> Void) throws {
        self.index = index
        self.onClose = onClose
        
        guard let applicationSupport = try? FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
        ) else {
            fatalError("Failed to find application support directory")
        }
//        guard let bundleId = Bundle.main.bundleIdentifier else {
//            fatalError("Failed to find application support directory")
//        }
        
        let pipesFolder = applicationSupport
            .appendingPathComponent("Dolphin")
            .appendingPathComponent("Pipes")
        if !FileManager.default.fileExists(atPath: pipesFolder.path) {
            try FileManager.default.createDirectory(
                at: pipesFolder,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        let pipeUrl = pipesFolder.appendingPathComponent("ctrl\(index+1)")
//        mkfifo(pipeUrl.path, 0o644)
        guard let outputStream = OutputStream(url: pipeUrl, append: true) else {
            fatalError("Failed to create outputstream")
        }
        self.outputStream = outputStream
        
        super.init()
        
        self.outputStream.delegate = self
        outputStream.open()
        print("created websocket handler")
    }
    
    deinit {
        self.outputStream.close()
    }

    public func handlerAdded(context: ChannelHandlerContext) {
        print("handler added", id)
        self.ping(context: context)
    }
    
    func handlerRemoved(context: ChannelHandlerContext) {
        print("handler removed", id)
        onClose()
    }
    
    private static var newline: UInt8 = 0x0A

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let frame = self.unwrapInboundIn(data)

        switch frame.opcode {
        case .connectionClose:
            self.receivedClose(context: context, frame: frame)
        case .pong:
            self.pong(context: context, frame: frame)
        case .text:
            self.streamText(buffer: frame.unmaskedData)
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
        let buffer = context.channel.allocator.buffer(string: "\(self.index),\(self.id)")
        let frame = WebSocketFrame(fin: true, opcode: .ping, data: buffer)
        context.writeAndFlush(self.wrapOutboundOut(frame), promise: nil)
    }

    private func pong(context: ChannelHandlerContext, frame: WebSocketFrame) {
        // noop
    }
    
    private func streamText(buffer: ByteBuffer) {
        var data = buffer
        var written = data.readableBytes
        while written > 0 {
            written -= data.readWithUnsafeReadableBytes({ pointer in
                self.outputStream.write(pointer.baseAddress!.assumingMemoryBound(to: UInt8.self), maxLength: written)
            })
            self.outputStream.write(&WebSocketHandler.newline, maxLength: 1)
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

extension WebSocketHandler: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        print("stream event: \(eventCode)")
    }
}
