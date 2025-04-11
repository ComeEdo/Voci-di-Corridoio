//
//  UserManager.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 02/12/24.
//

import SwiftUI
import Combine

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

class ApiResponseAuthData<T: Codable>: ApiResponseData<T> {
    let auth: AuthData?
    
    init(success: Bool, message: String, data: T?, auth: AuthData?) {
        self.auth = auth
        super.init(success: success, message: message, data: data)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        auth = try container.decodeIfPresent(AuthData.self, forKey: .auth)
        try super.init(from: decoder)
    }
    
    private enum CodingKeys: String, CodingKey {
        case auth
    }
}

struct AuthData: Codable {
    let logOut: Bool?
}

class ApiResponseUserData<T: Codable>: ApiResponseData<T> {
    let user: UserManagment?
    
    init(success: Bool, message: String, data: T?, user: UserManagment?) {
        self.user = user
        super.init(success: success, message: message, data: data)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        user = try container.decodeIfPresent(UserManagment.self, forKey: .user)
        try super.init(from: decoder)
    }
    
    private enum CodingKeys: String, CodingKey {
        case user
    }
}

struct UserManagment: Codable {
    let logOut: Bool?
    let updateUserAndToken: Bool?
}

struct DataFieldRegistration: Codable {
    let username: String?
    let email: String?
}

struct DataFieldCheckUsername: Codable {
    let exists: Bool
    let username: String?
}

struct NewToken: Codable {
    let token: String
}

enum Roles: Int, Codable {
    case user = 0
    case admin = 1
    case student = 2
    case teacher = 3
    case principal = 4
    case secretariat = 5
    
    var description: LocalizedStringResource {
        switch self {
        case .user:
            return "Utente"
        case .admin:
            return "Admin"
        case .student:
            return "Studente"
        case .teacher:
            return "Professore"
        case .principal:
            return "Preside"
        case .secretariat:
            return "Segreteria"
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
    
    static private let keyChainSpace: String = "authToken"
    
    @Published private(set) var isAuthenticated = false
    @Published private(set) var authToken: String? = nil
    @Published private(set) var userToken: String? = nil
    @Published private(set) var mainUser: MainUser? {
        didSet {
            mainUserSubscription = mainUser?.objectWillChange.sink { [weak self] in
                self?.objectWillChange.send()
            }
        }
        willSet {
            mainUserSubscription?.cancel()
            mainUserSubscription = nil
        }
    }
    @Published private(set) var mainUserSubscription: AnyCancellable?
    
    @Published private(set) var isAuthLoading: Bool = false
    
    enum ServerDomain: String, CaseIterable {
        case VDC = "VDC.local:443"
        case levoci = "levoci.local:443"
        case MacBookPro = "Edoardos-MacBook-Pro.local:3000"
    }
    
    @Published var domain: ServerDomain = .VDC
    var URN: String {
        "https://\(domain.rawValue)/api"
    }
    
    struct APIEndpoints {
        static let user = "/user"
        static let auth = "/auth"
        static let register = "/register"
        static let login = "/login"
        static let isAuthTokenValid = "\(auth)/isAuthTokenValid"
        static let checkUsername = "/check/username"
        static let fetchAvailableClasses = "/classes/registration"
        static let SSLCertificate = "/downloads/certificates"
        static let userAndToken = "\(auth)/getTokenAndUser"
        static let newAuthToken = "\(auth)/refreshAuthToken"
        static let isUserTokenValid = "\(user)/isUserTokenValid"
        static let newUserToken = "\(user)/refreshUserToken"
        static let timetable = "\(user)/getTimetable"
        static let profileImage = "/profileImage"
        
        private init() {}
    }
    
    private var isGettingNewUserToken = false
    private var isGettingNewAuthToken = false
    
    private init() {
        reInit()
    }
    
    func waitUntilAuthLoadingCompletes() async {
        while isAuthLoading {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
    }
    
    
    func reInit() {
        if let token = getTokenFromKeychain(), let userPersistance: MainUser = DefaultPersistence.retrieve() {
            isAuthLoading = true
            mainUser = userPersistance
            authToken = token
            isAuthenticated = true
            Task {
                do {
                    guard try await isAuth(token) else {
                        return
                    }
                    let alert = try await getAuthUserAndToken(userPersistance.user.id)
                    Utility.setupBottom(alert.notification)
                } catch {
                    if let err = mapError(error) {
                        Utility.setupBottom(err.notification)
                    }
                }
                await MainActor.run {
                    isAuthLoading = false
                }
            }
        }
    }
    
    @MainActor
    func registerUser(user: RegistrationData) async throws -> RegistrationNotification {
        guard let url = URL(string: "\(URN)\(APIEndpoints.register)") else {
            throw Errors.invalidURL(url: "\(URN)\(APIEndpoints.register)")
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
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let (httpResponse, apiResponse): (HTTPURLResponse, ApiResponseData<DataFieldRegistration>) = try checkResponse(response: response, data: data)
        let statusCode = httpResponse.statusCode
        
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
    }
    
    @MainActor
    func logInUser(email: String, password: String) async throws -> LoginNotification {
        guard let url = URL(string: "\(URN)\(APIEndpoints.login)") else {
            throw Errors.invalidURL(url: "\(URN)\(APIEndpoints.login)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "email": email,
            "password": password
        ]
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let (httpResponse, apiResponse): (HTTPURLResponse, ApiResponseData<LogInResponse>) = try checkResponse(response: response, data: data)
        let statusCode = httpResponse.statusCode
        
        switch statusCode {
        case 200:
            guard let logInData = apiResponse.data else {
                throw Errors.JSONError(message: "non sono riuscito a decodificare i dati")
            }
            guard try await isAuth(logInData.authToken) else {
                throw AuthError.unauthorized(message: apiResponse.message)
            }
            self.authToken = logInData.authToken
            Task {
                for roleGroup in logInData.roleGroups {
                    for userModel in roleGroup.userModels {
                        do {
                            try await userModel.fetchProfileImage()
                        } catch {
                            if let err = mapError(error) {
                                Utility.setupBottom(err.notification)
                                print("Failed to fetch profile image:", err.description)
                            }
                        }
                    }
                }
            }
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
    }
    
    @MainActor
    func isAuth(_ token: String) async throws -> Bool {
        guard let url = URL(string: "\(URN)\(APIEndpoints.isAuthTokenValid)") else {
            throw Errors.invalidURL(url: "\(URN)\(APIEndpoints.isAuthTokenValid)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let (httpResponse, apiResponse): (HTTPURLResponse, ApiResponseAuthData<Bool>) = try checkResponse(response: response, data: data)
        let statusCode = httpResponse.statusCode
        
        switch statusCode {
        case 200:
            Utility.setupBottom(MainNotification.NotificationStructure(title: "Successo", message: "Il token di autenticazione è valido.", type: .success))
            return true
        case 400:
            throw Codes.code400(message: apiResponse.message)
        case 401:
            throw AuthError.unauthorized(message: apiResponse.message)
        case 403:
            throw AuthError.forbidden(message: apiResponse.message)
        default:
            throw Errors.unknownError(message: apiResponse.message)
        }
    }
    
    @MainActor
    func isUser(_ token: String) async throws -> Bool {
        guard let url = URL(string: "\(URN)\(APIEndpoints.isUserTokenValid)") else {
            throw Errors.invalidURL(url: "\(URN)\(APIEndpoints.isUserTokenValid)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let (httpResponse, apiResponse): (HTTPURLResponse, ApiResponseUserData<Bool>) = try checkResponse(response: response, data: data)
        let statusCode = httpResponse.statusCode
        
        switch statusCode {
        case 200:
            Utility.setupBottom(MainNotification.NotificationStructure(title: "Successo", message: "Il token dell'utente è valido.", type: .success))
            return true
        case 400:
            throw Codes.code400(message: apiResponse.message)
        case 401:
            throw AuthError.unauthorized(message: apiResponse.message)
        case 403:
            throw AuthError.forbidden(message: apiResponse.message)
        default:
            throw Errors.unknownError(message: apiResponse.message)
        }
    }
    
    @MainActor
    func getNewAuthToken() async throws {
        guard !isGettingNewAuthToken else {
            return
        }
        isGettingNewAuthToken = true
        defer {
            isGettingNewAuthToken = false
        }
        guard let url = URL(string: "\(URN)\(APIEndpoints.newAuthToken)") else {
            throw Errors.invalidURL(url: "\(URN)\(APIEndpoints.newAuthToken)")
        }
        guard let token = authToken else {
            throw AuthError.unauthorized(message: "Token is nil")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let (httpResponse, apiResponse): (HTTPURLResponse, ApiResponseAuthData<NewToken>) = try checkResponse(response: response, data: data)
        let statusCode = httpResponse.statusCode
        
        switch statusCode {
        case 200:
            guard let newToken = apiResponse.data?.token else {
                throw Errors.JSONError(message: "è tutto rotto")
            }
            guard try await isAuth(newToken) else {
                throw AuthError.unauthorized(message: apiResponse.message)
            }
            self.authToken = newToken
            Utility.setupBottom(MainNotification.NotificationStructure(title: "Successo", message: "Nuovo token di autenticazione.", type: .success))
        case 400:
            throw Codes.code400(message: apiResponse.message)
        case 401:
            throw AuthError.unauthorized(message: apiResponse.message)
        case 403:
            throw AuthError.forbidden(message: apiResponse.message)
        default:
            throw Errors.unknownError(message: apiResponse.message)
        }
    }
    
    @MainActor
    func getNewUserToken() async throws {
        guard !isGettingNewUserToken else {
            return
        }
        isGettingNewUserToken = true
        defer {
            isGettingNewUserToken = false
        }
        guard let url = URL(string: "\(URN)\(APIEndpoints.newUserToken)") else {
            throw Errors.invalidURL(url: "\(URN)\(APIEndpoints.newUserToken)")
        }
        await waitUntilAuthLoadingCompletes()
        guard let token = userToken else {
            throw AuthError.unauthorized(message: "Token is nil")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let (httpResponse, apiResponse): (HTTPURLResponse, ApiResponseUserData<NewToken>) = try checkResponse(response: response, data: data)
        let statusCode = httpResponse.statusCode
        
        switch statusCode {
        case 200:
            guard let newToken = apiResponse.data?.token else {
                throw Errors.JSONError(message: "è tutto rotto")
            }
            guard try await isUser(newToken) else {
                throw AuthError.unauthorized(message: apiResponse.message)
            }
            self.userToken = newToken
            Utility.setupBottom(MainNotification.NotificationStructure(title: "Successo", message: "Nuovo token utente.", type: .success))
        case 400:
            throw Codes.code400(message: apiResponse.message)
        case 401:
            throw AuthError.unauthorized(message: apiResponse.message)
        case 403:
            throw AuthError.forbidden(message: apiResponse.message)
        default:
            throw Errors.unknownError(message: apiResponse.message)
        }
    }
    
    @MainActor
    func getAuthUserAndToken(_ id: UUID) async throws -> LoginNotification {
        guard let url = URL(string: "\(URN)\(APIEndpoints.userAndToken)") else {
            throw Errors.invalidURL(url: "\(URN)\(APIEndpoints.userAndToken)")
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
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let (httpResponse, apiResponse): (HTTPURLResponse, ApiResponseAuthData<LoginUser>) = try checkResponse(response: response, data: data)
        let statusCode = httpResponse.statusCode
        
        switch statusCode {
        case 200:
            guard let logInData = apiResponse.data else {
                throw Errors.JSONError(message: "è tutto rotto")
            }
            guard try await isUser(logInData.userToken) else {
                throw AuthError.unauthorized(message: apiResponse.message)
            }
            
            try saveTokenToKeychain(token: token)
            
            self.userToken = logInData.userToken
            
            setMainUser(with: logInData.mainUser)
            
            self.isAuthenticated = true
            
            return .gotUser(userModel: logInData.mainUser)
        case 400:
            throw Codes.code400(message: apiResponse.message)
        case 401:
            throw AuthError.unauthorized(message: apiResponse.message)
        case 403:
            throw AuthError.forbidden(message: apiResponse.message)
        case 404 where apiResponse.success:
            throw LoginError.userNotFound
        case 404 where !apiResponse.success:
            throw Codes.code404(message: apiResponse.message)
        case 500:
            throw Codes.code500(message: apiResponse.message)
        default:
            throw Errors.unknownError(message: apiResponse.message)
        }
    }
    
    private func setMainUser(with newMainUser: MainUser) {
        switch (mainUser, newMainUser) {
        case (nil, _):
            load()
        case let (current?, new) where current == new:
            return
        case let (current?, new) where current.user.profileImageId != nil && new.user.profileImageId == nil:
            new.setImage(for: nil)
            load()
        case let (current?, new) where current.user.profileImageId != new.user.profileImageId:
            load()
        case (_, let new):
            self.mainUser = new
        }
        
        DefaultPersistence.save(for: newMainUser)
        
        func load() {
            self.mainUser = newMainUser
            Task {
                do {
                    try await self.mainUser?.fetchProfileImage()
                } catch {
                    if let err = mapError(error) {
                        Utility.setupBottom(err.notification)
                    }
                }
            }
        }
    }
    
    
    // Save token to Keychain
    private func saveTokenToKeychain(token: String) throws {
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: UserManager.keyChainSpace,
            kSecValueData as String: token.data(using: .utf8) ?? Data()
        ]
        
        // Delete existing token if it exists
        SecItemDelete(keychainQuery as CFDictionary)
        
        // Add new token
        let status = SecItemAdd(keychainQuery as CFDictionary, nil)
        if status != errSecSuccess {
            throw KeychainError.unableToSave(what: "token")
        }
    }
    
    // Retrieve token from Keychain
    private func getTokenFromKeychain() -> String? {
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: UserManager.keyChainSpace,
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
        self.isAuthenticated = false
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: UserManager.keyChainSpace
        ]
        SecItemDelete(keychainQuery as CFDictionary)
        
        DefaultPersistence.delete(type: AppView.Tabs.self)
        DefaultPersistence.delete(type: MainUser.self)
        NotificationManager.shared.reset()
        
        self.authToken = nil
        self.userToken = nil
        
        self.mainUser?.deleteFileProfileImage()
        self.mainUser = nil
    }
    
    @MainActor @discardableResult
    func getTimetable() async throws -> Timetable {
        guard let url = URL(string: "\(URN)\(APIEndpoints.timetable)") else {
            throw Errors.invalidURL(url: "\(URN)\(APIEndpoints.timetable)")
        }
        await waitUntilAuthLoadingCompletes()
        guard let token = userToken else {
            throw AuthError.unauthorized(message: "Token is nil")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let (httpResponse, apiResponse): (HTTPURLResponse, ApiResponseUserData<Timetable>) = try checkResponse(response: response, data: data)
        let statusCode = httpResponse.statusCode
        
        switch statusCode {
        case 200:
            guard let timetable = apiResponse.data else {
                throw Errors.JSONError(message: "è tutto rotto")
            }
            Utility.setupAlert(MainNotification.NotificationStructure(title: "Successo", message: "spacchettato.", type: .success))
            return timetable
        case 400:
            throw Codes.code400(message: apiResponse.message)
        case 401:
            throw AuthError.unauthorized(message: apiResponse.message)
        case 403:
            throw AuthError.forbidden(message: apiResponse.message)
        case 500:
            throw Codes.code500(message: apiResponse.message)
        default:
            throw Errors.unknownError(message: apiResponse.message)
        }
    }
}


struct TokenValidator {
    static func isTokenRefreshable(authToken: String) -> Bool {
        guard let issuedAt = extractIssuedAt(from: authToken) else {
            return false
        }
        
        let currentTime = Date()
        let oneDayInSeconds: TimeInterval = 24 * 60 * 60
        let timeSinceIssue = currentTime.timeIntervalSince(issuedAt)
        
        return timeSinceIssue >= oneDayInSeconds
    }
    
    private static func extractIssuedAt(from token: String) -> Date? {
        let segments = token.split(separator: ".")
        guard segments.count == 3,
              let payloadData = base64UrlDecode(String(segments[1])),
              let json = try? JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any],
              let iat = json["iat"] as? TimeInterval else {
            return nil
        }
        print(iat)
        print(Date(timeIntervalSince1970: iat))
        return Date(timeIntervalSince1970: iat)
    }
    
    private static func base64UrlDecode(_ base64: String) -> Data? {
        var base64 = base64
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let paddingLength = 4 - (base64.count % 4)
        if paddingLength < 4 {
            base64.append(String(repeating: "=", count: paddingLength))
        }
        
        return Data(base64Encoded: base64)
    }
}
