//
//  UserManager.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 02/12/24.
//


import SwiftUI

class ApiResponse<T: Codable>: Codable {
    let success: Bool
    let message: String
    let data: T?
}

struct DataFieldRegistration: Codable {
    let username: String?
    let email: String?
}

struct DataFieldCheckUsername: Codable {
    let exists: Bool
    let username: String?
}

enum Roles: Int {
    case user = 0
    case admin = 1
    case student = 2
    case teacher = 3
    case principal = 4
    case secretariat = 5
    
    var des: LocalizedStringResource {
        switch self {
        case .user:
            return "user"
        case .admin:
            return "admin"
        case .student:
            return "studente"
        case .teacher:
            return "professore"
        case .principal:
            return "preside"
        case .secretariat:
            return "segreteria"
        }
    }
    
    static func from(_ id: Int) -> Roles {
//        if let role = Roles(rawValue: id) {
//            return role
//        } else {
//            print("Invalid role id: \(id)")
//            return .student
//        }
        return Roles(rawValue: id) ?? .user
    }
    
    static func isRole(_ user: User) -> Roles {
        switch user {
        case is Student:
            return .student
        case is Teacher:
            return .teacher
        case is Admin:
            return .admin
        case is Principal:
            return .principal
        case is Secretariat:
            return .secretariat
        default:
            return .user
        }
    }
    
    static func isType(_ id: Int) -> User.Type {
        let role: Roles = Roles.from(id)
        switch role {
        case .student:
            return Student.self
        case .user:
            return User.self
        case .admin:
            return Admin.self
        case .teacher:
            return Teacher.self
        case .principal:
            return Principal.self
        case .secretariat:
            return Secretariat.self
        }
    }
}

class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published private(set) var isAuthenticated = false
    @Published private(set) var authToken: String? = nil
    @Published private(set) var currentUser: User? = nil
    @Published private(set) var role: Roles = .student
    
    let server = "levoci.local"
    let port = 443
    let URN: String
    
    struct APIEndpoints {
        static let register = "/register"
        static let login = "/login"
        static let auth = "/auth"
        static let checkUsername = "/check/username"
        static let fetchAvailableClasses = "/classes/registration"
        static let SSLCertificate = "/downloads/certificates"
        
        private init() {}
    }
    
    private init() {
        self.URN = "https://\(server):\(port)/api"
//        if let token = getTokenFromKeychain() {
//            isAuthenticated = true
//            Task {
//                do {
//                    print("siuuu")
//                    if try await isAuth("token") {
//                        //tirare fuori il user
//                        authToken = "token"
//                        print("boh3")
//                    } else {
//                        print("boh2")
////                        logoutUser()
//                    }
//                } catch let error as Notifiable {
//                    print("boh1")
//                    NotificationManager.shared.showBottom(error.notification)
//                } catch {
//                    print("boh")
//                    NotificationManager.shared.showBottom(.init(title: "sium", message: "Errore: \(error.localizedDescription)", type: .error))
//                }
//            }
//        }
    }
    
    // Register a user
    @MainActor
    func registerUser(user: RegistrationData) async throws -> RegistrationNotification {
        guard let url = URL(string: "\(URN)\(APIEndpoints.register)") else {
            throw RegistrationError.invalidURL(message: "\(URN)\(APIEndpoints.register)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "name": user.name,
            "surname": user.surname,
            "username": user.username,
            "email": user.email,
            "password": user.password,
            "classUUID": {
                if case .student(let classGroup) = user.role {
                    return classGroup.uuidString
                } else {
                    return nil
                }
            }()
        ].compactMapValues { $0 }
        
        print("body: \(body)")
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw RegistrationError.JSONError(message: error.localizedDescription)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let (httpResponse, apiResponse): (HTTPURLResponse, ApiResponse<DataFieldRegistration>) = try checkResponse(data: data, response: response)
            let statusCode = httpResponse.statusCode
            print("Success: \(apiResponse.success)")
            print("Message: \(apiResponse.message)")
            
            switch statusCode {
            case 201:
                return RegistrationNotification.success(username: apiResponse.data?.username ?? "User")
            case 400:
                throw Codes.code400(message: apiResponse.message)
            case 409:
                if let username = apiResponse.data?.username, let mail = apiResponse.data?.email {
                    return RegistrationNotification.failureUsernameMail(username: username, mail: mail)
                } else if let username = apiResponse.data?.username {
                    return RegistrationNotification.failureUsername(username: username)
                } else if let mail = apiResponse.data?.email {
                    return RegistrationNotification.failureMail(mail: mail)
                } else {
                    throw Codes.code409(message: apiResponse.message)
                }
            case 500:
                throw Codes.code500(message: apiResponse.message)
            default:
                throw RegistrationError.invalidResponse(message: apiResponse.message)
            }
        } catch {
            throw mapError(error)
        }
    }
    
    @MainActor
    func loginUser(email: String, password: String) async throws -> LoginNotification {
        guard let url = URL(string: "\(URN)\(APIEndpoints.login)") else {
            throw RegistrationError.invalidURL(message: "\(URN)\(APIEndpoints.login)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "email": email,
            "password": password
        ]
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch let error {
            throw RegistrationError.JSONError(message: error.localizedDescription)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let (httpResponse, apiResponse): (HTTPURLResponse, ApiResponse<LoginResponse>) = try checkResponse(data: data, response: response)
            let statusCode = httpResponse.statusCode
            
            switch statusCode {
            case 200:
                guard let logInData = apiResponse.data else {
                    throw RegistrationError.JSONError(message: "è tutto rotto")
                }
                //                guard let logInData = apiResponse.data else {
                //                    throw RegistrationError.JSONError(message: "è tutto rotto")
                //                }
                //
                //                guard try await isAuth(logInData.token) else {
                //                    throw RegistrationError.unknownError(message: "token fottuto\n\(logInData.token)")
                //                }
                //
                //                print("token approved")
                //
                //                try saveTokenToKeychain(token: logInData.token)
                //                currentUser = logInData.user
                //                self.authToken = logInData.token
                //                self.isAuthenticated = true
                //                ForEach(logInData.roleGroups, id: \.roleId ) { username in
                ////                    print(username)
                //                    ForEach(username.users, id: \.id) { user in
                //                        print(user.description)
                //                    }
                //                }
                return LoginNotification.success(users: logInData.roleGroups)
            case 400:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw Codes.code400(message: errorMessage)
            case 500:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw Codes.code500(message: errorMessage)
            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw RegistrationError.invalidResponse(message: errorMessage)
            }
        } catch {
            throw mapError(error)
        }
    }
    
    func isAuth(_ token: String) async throws -> Bool {
        guard let url = URL(string: "\(URN)\(APIEndpoints.auth)") else {
            throw RegistrationError.invalidURL(message: "\(URN)\(APIEndpoints.auth)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response from server.")
                return false
            }
            
            if httpResponse.statusCode == 200 {
                // If token is valid
                print("Token is valid.")
                return true
            } else {
                // Handle invalid token response
                let responseMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("\(httpResponse.statusCode)\nToken invalid or error:\n\(responseMessage)")
                return false
            }
        } catch let error as URLError {
            // Handle specific URL errors
            throw error

            switch error.code {
            case .notConnectedToInternet:
                print("Error: Not connected to the Internet.")
            case .timedOut:
                print("Error: The request timed out.")
            case .cannotFindHost:
                print("Error: Cannot find the host.")
            case .cannotConnectToHost:
                print("Error: Cannot connect to the host.")
            default:
                print("URLError: \(error.localizedDescription)")
            }
            return false
        } catch {
            throw error
            // Handle other errors
            print("Error during token verification:\n\(error.localizedDescription)")
            return false
        }
    }
    
    /*func fetchAvailableClasses(completion: @escaping (Result<[Class], Error>) -> Void) {
        // Define the URL for your API endpoint
        guard let url = URL(string: "http://your-server-url.com/api/classes") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }

        // Create the URL request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Create a data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle errors in the network request
            if let error = error {
                completion(.failure(error))
                return
            }

            // Ensure the response and data are valid
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                  let data = data else {
                completion(.failure(NSError(domain: "Invalid response", code: -1, userInfo: nil)))
                return
            }

            do {
                // Decode the JSON response
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601 // Adjust this based on your backend's date format
                let response = try decoder.decode(ClassesResponse.self, from: data)

                // Pass the fetched classes back to the caller
                completion(.success(response.classes))
            } catch {
                completion(.failure(error))
            }
        }

        // Start the task
        task.resume()
    }*/


       // Save token to Keychain
       func saveTokenToKeychain(token: String) throws {
           let keychainQuery: [String: Any] = [
               kSecClass as String: kSecClassGenericPassword,
               kSecAttrAccount as String: "authToken",
               kSecValueData as String: token.data(using: .utf8) ?? Data()
           ]

           // Delete existing token if it exists
           SecItemDelete(keychainQuery as CFDictionary)

           // Add new token
           let status = SecItemAdd(keychainQuery as CFDictionary, nil)
           if status != errSecSuccess {
               throw NSError(domain: "KeychainError", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to save token to Keychain."])
           }
       }

       // Retrieve token from Keychain
       func getTokenFromKeychain() -> String? {
           let keychainQuery: [String: Any] = [
               kSecClass as String: kSecClassGenericPassword,
               kSecAttrAccount as String: "authToken",
               kSecReturnData as String: true,
               kSecMatchLimit as String: kSecMatchLimitOne
           ]

           var item: CFTypeRef?
           let status = SecItemCopyMatching(keychainQuery as CFDictionary, &item)

           guard status == errSecSuccess, let data = item as? Data else {
               return nil
           }

           return String(data: data, encoding: .utf8)
       }

       // Logout user
       func logoutUser() {
           // Clear authentication data
           self.currentUser = nil
           self.authToken = nil
           self.isAuthenticated = false

           // Remove token from Keychain
           let keychainQuery: [String: Any] = [
               kSecClass as String: kSecClassGenericPassword,
               kSecAttrAccount as String: "authToken"
           ]
           SecItemDelete(keychainQuery as CFDictionary)
       }
}
