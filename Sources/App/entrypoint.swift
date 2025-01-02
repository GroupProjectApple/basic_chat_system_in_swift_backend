import Vapor
import Logging
import NIOCore
import NIOPosix

@main
enum Entrypoint {
    static func main() async throws {
        // Detect environment and bootstrap logging
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
       
        // Initialize the app
        let app = try await Application.make(env)
       
        // RabbitMQ connection string
        let rabbitMQConnectionString = "amqps://tkmzwfdi:L8M8wKlnoUA37hyz1GRrlch8ufJY3mys@fuji.lmq.cloudamqp.com/tkmzwfdi"
       
        // Set up the event loop group with multiple threads
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
       
        // Start RabbitMQ server and sender concurrently using async tasks
        //async let rabbitMQServerTask = try startRabbitMQServer(eventLoopGroup: eventLoopGroup, connectionString: rabbitMQConnectionString)
        Task{
         do {
            try await RabbitMQSenderServer.start(eventLoopGroup: eventLoopGroup, connectionString: rabbitMQConnectionString)
        } catch {
            print("Failed to start RabbitMQ sender server: \(error)")
        }
        }
        Task{
         do {
            try await RabbitMQServer.start(eventLoopGroup: eventLoopGroup, connectionString: rabbitMQConnectionString)
        } catch {
            print("Failed to start RabbitMQ server: \(error)")
        }
        }
       
        do {
            // Run the Vapor app and configure it
            try await configure(app)
        } catch {
            app.logger.report(error: error)
            try? await app.asyncShutdown()
            throw error
        }
       
        // Wait for both RabbitMQ server and sender to finish
        //try await rabbitMQServerTask
        //try await rabbitMQSenderServerTask
       
        // Shutdown the app
        try await app.execute()
        try await app.asyncShutdown()
    }
   
    // Function to start RabbitMQ server
    /*static func startRabbitMQServer(eventLoopGroup: EventLoopGroup, connectionString: String) async throws {
        do {
            try await RabbitMQServer.start(eventLoopGroup: eventLoopGroup, connectionString: connectionString)
        } catch {
            print("Failed to start RabbitMQ server: \(error)")
        }
    }*/
   
    // Function to start RabbitMQ sender server
    /*static func startRabbitMQSenderServer(eventLoopGroup: EventLoopGroup, connectionString: String) async throws {
        do {
            try await RabbitMQSenderServer.start(eventLoopGroup: eventLoopGroup, connectionString: connectionString)
        } catch {
            print("Failed to start RabbitMQ sender server: \(error)")
        }
    }*/
}

