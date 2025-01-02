import NIO
import NIOSSL
import AMQPClient

public struct RabbitMQServer {
    // Static function to start the server
    public static func start(eventLoopGroup: EventLoopGroup, connectionString: String) async throws {
        // Create AMQP connection configuration
        let useTLS = true  // Define useTLS to control TLS usage

        var tlsConfig: TLSConfiguration? = nil
        if useTLS {
            tlsConfig = try TLSConfiguration.makeClientConfiguration()  // Use the updated function
        }
        let config = try await AMQPConnectionConfiguration(
            url: connectionString,
            tls: tlsConfig
        )

        // Get an event loop from the event loop group
        let eventLoop = eventLoopGroup.next()

        // Establish a connection (correct argument order)
        let connection = try await AMQPConnection.connect(
            use: eventLoop,  // EventLoop should come first
            from: config      // Configuration should be second
        )

        print("[RabbitMQ] Connected to RabbitMQ server.")

        // Create a channel
        let channel = try await connection.openChannel()  // Update this based on the correct method
        print("[RabbitMQ] Channel created.")

        // Declare a queue
        let queueName = "test_queue"
        try await channel.queueDeclare(name: queueName, passive: false, durable: false)

        print("[RabbitMQ] Waiting for messages on queue: \(queueName)")

        // Start consuming messages, passing an empty dictionary for args
        try await channel.basicConsume(queue: queueName, consumerTag: "", noAck: false, exclusive: false, args: [:], listener: { message in
            if case .success(let message) = message {
                // Directly access the body as it's not an optional
                let body = message.body
                if let bodyData = body.getData(at: 0, length: body.readableBytes) {
                    let messageString = String(data: bodyData, encoding: .utf8) ?? "Unreadable message"
                    print("[RabbitMQ] Received message: \(messageString)")
                } else {
                    print("[RabbitMQ] Failed to extract body data")
                }
            }
        })
    }
}
