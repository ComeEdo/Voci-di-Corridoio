//
//  UserManager.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 02/12/24.
//


import SwiftUI

class ApiResponse: Codable {
    let success: Bool
    let message: String

    init(success: Bool, message: String) {
        self.success = success
        self.message = message
    }
}

class ApiResponseData<T: Codable>: ApiResponse {
    let data: T?

    init(success: Bool, message: String, data: T?) {
        self.data = data
        super.init(success: success, message: message)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try container.decodeIfPresent(T.self, forKey: .data)
        try super.init(from: decoder)
    }
    
    private enum CodingKeys: String, CodingKey {
        case data
    }
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
    
    var description: LocalizedStringResource {
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
    @Published private(set) var userToken: String? = nil
    @Published private(set) var currentUser: User? = nil
    @Published private(set) var role: Roles? = nil
    
    let server = "levoci.local"
    let port = 443
    let URN: String
    
    struct APIEndpoints {
        static let register = "/register"
        static let login = "/login"
        static let auth = "/auth/isAuthTokenValid"
        static let checkUsername = "/check/username"
        static let fetchAvailableClasses = "/classes/registration"
        static let SSLCertificate = "/downloads/certificates"
        static let logUser = "/auth/loginUser"
        
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
            throw Errors.invalidURL(message: "\(URN)\(APIEndpoints.register)")
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
            throw Errors.JSONError(message: error.localizedDescription)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let (httpResponse, apiResponse): (HTTPURLResponse, ApiResponseData<DataFieldRegistration>) = try checkResponse(data: data, response: response)
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
                throw Errors.invalidResponse(message: apiResponse.message)
            }
        } catch {
            throw mapError(error)
        }
    }
    
    @MainActor
    func loginUser(email: String, password: String) async throws -> LoginNotification {
        guard let url = URL(string: "\(URN)\(APIEndpoints.login)") else {
            throw Errors.invalidURL(message: "\(URN)\(APIEndpoints.login)")
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
            throw Errors.JSONError(message: error.localizedDescription)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let (httpResponse, apiResponse): (HTTPURLResponse, ApiResponseData<LoginResponse>) = try checkResponse(data: data, response: response)
            let statusCode = httpResponse.statusCode
            
            switch statusCode {
            case 200:
                guard let logInData = apiResponse.data else {
                    throw Errors.JSONError(message: "non sono riuscito a decodificare i dati")
                }
                
                guard try await isAuth(logInData.authToken) else {
                    throw AuthError.unauthorized(message: apiResponse.message)
                }
                //
                //                print("token approved")
                //
                //                try saveTokenToKeychain(token: logInData.token)
                //                currentUser = logInData.user
                self.authToken = logInData.authToken
                //                self.isAuthenticated = true
                //                ForEach(logInData.roleGroups, id: \.roleId ) { username in
                ////                    print(username)
                //                    ForEach(username.users, id: \.id) { user in
                //                        print(user.description)
                //                    }
                //                }
                return LoginNotification.success(users: logInData.roleGroups)
            case 400:
                throw Codes.code400(message: apiResponse.message)
            case 401:
                throw LoginError.invalidCredentials
            case 403:
                throw LoginError.emailNotVerified
            case 404:
                if apiResponse.success {
                    throw LoginError.userNotFound
                } else {
                    throw Codes.code404(message: apiResponse.message)
                }
            case 500:
                throw Codes.code500(message: apiResponse.message)
            default:
                throw Errors.invalidResponse(message: apiResponse.message)
            }
        } catch {
            throw mapError(error)
        }
    }
    
    func isAuth(_ token: String) async throws -> Bool {
        guard let url = URL(string: "\(URN)\(APIEndpoints.auth)") else {
            throw Errors.invalidURL(message: "\(URN)\(APIEndpoints.auth)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let (httpResponse, apiResponse): (HTTPURLResponse, ApiResponse) = try checkResponse(data: data, response: response)
            let statusCode = httpResponse.statusCode
            
            switch statusCode {
            case 200:
                NotificationManager.shared.showBottom(MainNotification.NotificationStructure(title: "Success", message: "Token is valid.", type: .success))
                return true
            case 400:
                throw Codes.code400(message: apiResponse.message)
            case 401:
                throw AuthError.unauthorized(message: apiResponse.message)
            default:
                throw Errors.unknownError(message: apiResponse.message)
            }
        } catch {
            throw mapError(error)
        }
    }
    
    @MainActor
    func logInUser(_ id: UUID) async throws -> LoginNotification {
        guard let url = URL(string: "\(URN)\(APIEndpoints.logUser)") else {
            throw Errors.invalidURL(message: "\(URN)\(APIEndpoints.logUser)")
        }
        guard let token = authToken else {
            throw AuthError.unauthorized(message: "Token is nil")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body: [String: String] = [
            "userId": id.uuidString
        ]
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch let error {
            throw Errors.JSONError(message: error.localizedDescription)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let (httpResponse, apiResponse): (HTTPURLResponse, ApiResponseData<LoginUser>) = try checkResponse(data: data, response: response)
            let statusCode = httpResponse.statusCode
            
            switch statusCode {
            case 200:
                guard let logInData = apiResponse.data else {
                    throw Errors.JSONError(message: "è tutto rotto")
                }
                
//                guard /*try await isAuth(logInData.authToken)*/false else {
//                    throw AuthError.unauthorized(message: apiResponse.message)     //cambiare il messaggio
//                }
                
                self.currentUser = logInData.user
                self.userToken = logInData.userToken
                self.role = Roles.from(logInData.roleId)
                
                //salvare user e token in locale
                
                self.isAuthenticated = true
                
                return .gotUser(username: logInData.user.username)
            case 400:
                throw Codes.code400(message: apiResponse.message)
            case 401:
                throw AuthError.unauthorized(message: apiResponse.message)
            case 404:
                if apiResponse.success {
                    throw LoginError.userNotFound
                } else {
                    throw Codes.code404(message: apiResponse.message)
                }
            case 500:
                throw Codes.code500(message: apiResponse.message)
            default:
                throw Errors.unknownError(message: apiResponse.message)
            }
        } catch {
            throw mapError(error)
        }
    }


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
           self.userToken = nil
           self.role = nil
           self.isAuthenticated = false

           // Remove token from Keychain
           let keychainQuery: [String: Any] = [
               kSecClass as String: kSecClassGenericPassword,
               kSecAttrAccount as String: "authToken"
           ]
           SecItemDelete(keychainQuery as CFDictionary)
       }
}
