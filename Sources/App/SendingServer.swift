import NIO
import NIOSSL
import AMQPClient
import NIOHTTP1

public struct RabbitMQSenderServer {
    public static func start(eventLoopGroup: EventLoopGroup, connectionString: String) async throws {
        // Create AMQP connection configuration
        let queueName = "test_queue"
        let useTLS = true

        var tlsConfig: TLSConfiguration? = nil
        if useTLS {
            tlsConfig = TLSConfiguration.makeClientConfiguration()
        }

        let config = try AMQPConnectionConfiguration(
            url: connectionString,
            tls: tlsConfig
        )

        // Get an event loop from the group
        let eventLoop = eventLoopGroup.next()

        // Establish a RabbitMQ connection
        let connection = try await AMQPConnection.connect(
            use: eventLoop,
            from: config
        )

        print("[RabbitMQ] Connected to RabbitMQ server.")
        let rabbitChannel = try await connection.openChannel()

        // Start the server with EventLoopGroup
        let server = try ServerBootstrap(group: eventLoopGroup)
            .childChannelInitializer { channel in
                // Add the HTTP handler to the channel pipeline
                channel.pipeline.addHandler(HTTPHandler(rabbitChannel: rabbitChannel, queueName: queueName))
            }
            .bind(host: "0.0.0.0", port: 8081)
        
        // Ensure the server is started before calling wait
        print("[RabbitMQSenderServer] Server is running, awaiting connections...")

        // Wait for the server to keep running
        let _ = try await server.get()
        print("[RabbitMQSenderServer] Server has started successfully.")
    }
}

// Custom HTTP Handler for incoming HTTP requests
final class HTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPRequestHead
    typealias OutboundOut = ByteBuffer

    private let rabbitChannel: AMQPChannel
    private let queueName: String

    init(rabbitChannel: AMQPChannel, queueName: String) {
        self.rabbitChannel = rabbitChannel
        self.queueName = queueName
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let requestHead = self.unwrapInboundIn(data)

        // Handle incoming HTTP request
        print("Received HTTP request: \(requestHead.method) \(requestHead.uri)")

        // Retrieve the message from the URI (for example, using query parameters)
        let message = requestHead.uri

        // Publish the message to RabbitMQ
        let messageData = message.data(using: .utf8)!
        var buffer = context.channel.allocator.buffer(capacity: messageData.count)
        buffer.writeBytes(messageData)

        do {
            try rabbitChannel.basicPublish(
                from: buffer,
                exchange: "",
                routingKey: queueName
            )
            print("[RabbitMQ] Sent message: \(message) to queue: \(queueName)")
        } catch {
            print("[RabbitMQ] Failed to send message to queue: \(error)")
        }

        // Prepare the HTTP response
        let responseHead = HTTPResponseHead(
            version: .http1_1,
            status: .ok,
            headers: HTTPHeaders([("Content-Type", "text/plain")])
        )

        // Convert response head to a ByteBuffer
        var responseHeadBuffer = context.channel.allocator.buffer(capacity: 128)
        responseHeadBuffer.writeString("HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\n")

        // Write the response head and body
        context.write(self.wrapOutboundOut(responseHeadBuffer), promise: nil)
        
        // Prepare the response body
        let responseBody = "Message sent to RabbitMQ queue: \(queueName)".data(using: .utf8)!
        var responseBuffer = context.channel.allocator.buffer(capacity: responseBody.count)
        responseBuffer.writeBytes(responseBody)

        // Send the response body
        context.writeAndFlush(self.wrapOutboundOut(responseBuffer), promise: nil)
        context.flush()
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("[HTTP Handler] Error: \(error.localizedDescription)")
        context.close(promise: nil)
    }
}
