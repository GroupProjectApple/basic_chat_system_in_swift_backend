import Foundation

// Function to handle login
func login(username: String, password: String, completion: @escaping (Bool) -> Void) {
    let url = URL(string: "http://localhost:3000/login")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    let body: [String: String] = ["username": username, "password": password]
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    } catch {
        print("Error serializing JSON: \(error)")
        completion(false)
        return
    }
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error during login: \(error)")
            completion(false)
            return
        }
        
        guard let data = data else {
            print("No data received during login")
            completion(false)
            return
        }
        
        // Assuming the server returns a JSON response with a login status
        do {
            let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
            print("Login response: \(jsonResponse)")
            completion(true)
        } catch {
            print("Error parsing response: \(error)")
            completion(false)
        }
    }
    
    task.resume()
}

// Function to add recipient
func addRecipient(recipientUsername: String, completion: @escaping (Bool) -> Void) {
    let url = URL(string: "http://localhost:3000/addRecipient")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    let body: [String: String] = ["recipient": recipientUsername]
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    } catch {
        print("Error serializing JSON: \(error)")
        completion(false)
        return
    }
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error adding recipient: \(error)")
            completion(false)
            return
        }
        
        guard let data = data else {
            print("No data received")
            completion(false)
            return
        }
        
        // Assuming the server returns a JSON response
        do {
            let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
            print("Recipient added: \(jsonResponse)")
            completion(true)
        } catch {
            print("Error parsing response: \(error)")
            completion(false)
        }
    }
    
    task.resume()
}

// Function to send a message
func sendMessage(to recipient: String, from sender: String, message: String, completion: @escaping (Bool) -> Void) {
    let url = URL(string: "http://localhost:3000/sendMessage")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    let body: [String: String] = [
        "sender": sender,
        "recipient": recipient,
        "message": message
    ]
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    } catch {
        print("Error serializing JSON: \(error)")
        completion(false)
        return
    }
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error sending message: \(error)")
            completion(false)
            return
        }
        
        guard let data = data else {
            print("No data received")
            completion(false)
            return
        }
        
        // Assuming the server returns a JSON response
        do {
            let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
            print("Message sent: \(jsonResponse)")
            completion(true)
        } catch {
            print("Error parsing response: \(error)")
            completion(false)
        }
    }
    
    task.resume()
}

// Function to receive messages
func receiveMessages(for user: String, completion: @escaping ([String]) -> Void) {
    let url = URL(string: "http://localhost:3000/receiveMessages?user=\(user)")!
    
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            print("Error receiving messages: \(error)")
            completion([])
            return
        }
        
        guard let data = data else {
            print("No data received")
            completion([])
            return
        }
        
        // Assuming the server returns messages in JSON format
        do {
            let messages = try JSONSerialization.jsonObject(with: data, options: []) as? [String] ?? []
            print("Received messages: \(messages)")
            completion(messages)
        } catch {
            print("Error parsing response: \(error)")
            completion([])
        }
    }
    
    task.resume()
}

// Function to handle user interactions
func handleUserInteraction() {
    print("Enter username:")
    guard let username = readLine() else { return }
    print("Enter password:")
    guard let password = readLine() else { return }
    
    // Asynchronous login
    login(username: username, password: password) { loggedIn in
        if loggedIn {
            print("Login successful!")
            
            // Start the infinite loop for service selection
            var continueRunning = true
            
            while continueRunning {
                print("""
                Select a service:
                1. Add a recipient
                2. Send a message
                3. Receive messages
                4. Exit
                """)
                guard let option = readLine(), let choice = Int(option) else {
                    print("Invalid input. Please select a valid option.")
                    continue
                }

                switch choice {
                case 1:
                    // Add recipient
                    print("Enter recipient username:")
                    guard let recipient = readLine() else { return }
                    addRecipient(recipientUsername: recipient) { success in
                        if success {
                            print("Recipient added successfully!")
                        } else {
                            print("Failed to add recipient.")
                        }
                    }
                    
                case 2:
                    // Send message
                    print("Enter recipient username:")
                    guard let recipient = readLine() else { return }
                    print("Enter your message:")
                    guard let message = readLine() else { return }
                    sendMessage(to: recipient, from: username, message: message) { success in
                        if success {
                            print("Message sent successfully!")
                        } else {
                            print("Failed to send message.")
                        }
                    }
                    
                case 3:
                    // Receive messages
                    print("Checking for new messages...")
                    receiveMessages(for: username) { messages in
                        if !messages.isEmpty {
                            print("New messages: \(messages)")
                        } else {
                            print("No new messages.")
                        }
                    }
                    
                case 4:
                    // Exit
                    print("Exiting the application.")
                    continueRunning = false
                    
                default:
                    print("Invalid option. Please select again.")
                }
            }
            
        } else {
            print("Login failed. Please try again.")
        }
    }
}

// Start the user interaction
handleUserInteraction()

// Keep the program running to handle multiple interactions
RunLoop.main.run()
