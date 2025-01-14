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

struct DataFieldLogin: Codable {
    let user: User
    let role: Roles
    let token: String
    
    enum CodingKeys: String, CodingKey {
        case user
        case role
        case token
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        user = try container.decode(User.self, forKey: .user)
        token = try container.decode(String.self, forKey: .token)
        role = Roles.from(try container.decode(Int.self, forKey: .role))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(user, forKey: .user)
        try container.encode(token, forKey: .token)
        try container.encode(role.rawValue, forKey: .role)
    }
}

enum Roles: Int {
    case admin = 1
    case student = 2
    case teacher = 3
    case principal = 4
    case secretariat = 5
    
    var des: LocalizedStringResource {
        switch self {
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
        if let role = Roles(rawValue: id) {
            return role
        } else {
            print("Invalid role id: \(id)")
            return .student
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
    
    private struct APIEndpoints {
        static let register = "/register"
        static let login = "/login"
        static let auth = "/auth"
        
        private init() {}
    }
    
    private init() {
        self.URN = "https://\(server):\(port)/api"
        /*if let token = getTokenFromKeychain() {
            isAuthenticated = true
            Task {
                if await isAuth(token) {
                    //tirare fuori il user
                    authToken = token
                } else {
                    logoutUser()
                }
            }
        }*/
    }
    
    // Register a user
    @MainActor
    func registerUser(user: User, email: String, password: String) async throws -> RegistrationNotification {
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
            "email": email,
            "password": password
        ]
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch let err {
            throw RegistrationError.JSONError(message: err.localizedDescription)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw RegistrationError.invalidResponse(message: "Invalid response from server.")
            }
            
            let statusCode = httpResponse.statusCode
            let apiResponse = try JSONDecoder().decode(ApiResponse<DataFieldRegistration>.self, from: data)
            print("Success: \(apiResponse.success)")
            print("Message: \(apiResponse.message)")
            
            switch statusCode {
            case 201:
                if let username = apiResponse.data?.username {
                    return RegistrationNotification.sucess(username: username)
                } else {
                    return RegistrationNotification.sucess(username: "User") //boh
                }
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
        } catch let error as DecodingError {
            throw RegistrationError.JSONError(message: error.localizedDescription)
        } catch let error as Codes {
            throw error
        } catch let error as RegistrationError {
            throw error
        } catch {
            throw RegistrationError.unknownError(message: error.localizedDescription)
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
            guard let httpResponse = response as? HTTPURLResponse else {
                throw RegistrationError.invalidResponse(message: "Invalid response from server.")
            }
            
            let statusCode = httpResponse.statusCode
            let apiResponse = try JSONDecoder().decode(ApiResponse<DataFieldLogin>.self, from: data)
            
            switch statusCode {
            case 200:
                guard let logInData = apiResponse.data else {
                    throw RegistrationError.JSONError(message: "è tutto rotto")
                }
                
                guard await isAuth(logInData.token) else {
                    throw RegistrationError.unknownError(message: "token fottuto\n\(logInData.token)")
                }
                
                print("token approved")
                
                try saveTokenToKeychain(token: logInData.token)
                currentUser = logInData.user
                self.authToken = logInData.token
                self.isAuthenticated = true
                
                return LoginNotification.sucess(username: currentUser?.username ?? "user") // da cambiare
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
        } catch let error as DecodingError {
            throw RegistrationError.JSONError(message: error.localizedDescription)
        } catch let error as Codes {
            throw error
        } catch let error as RegistrationError {
            throw error
        } catch {
            throw RegistrationError.unknownError(message: error.localizedDescription)
        }
    }
    
    func isAuth(_ token: String) async /*throws*/ -> Bool {
        guard let url = URL(string: "\(URN)\(APIEndpoints.auth)") else {
//            throw RegistrationError.invalidURL(message: "\(URN)\(APIEndpoints.auth)")
            return false
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
