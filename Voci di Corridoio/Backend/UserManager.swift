//
//  UserManager.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 02/12/24.
//


import SwiftUI

let server = "levoci.local"
let port = 3000
let URN = "https://\(server):\(port)"

enum RegistrationError: Error {
    case invalidResponse(message: String)
    case unknownError(message: String)
    case JSONError(message: String)
    case invalidURL(message: String)
    
    var message: AlertResponse {
        switch self {
        case .invalidResponse(let message):
            return AlertResponse(title: "Errore", message: "Risposta del server non valida: \(message)")
        case .unknownError(let message):
            return AlertResponse(title: "Errore", message: "Errore riscontrato:\n\(message)")
        case .JSONError(let message):
            return AlertResponse(title: "Errore", message: "Errore JSON riscontrato:\n\(message)")
        case .invalidURL(let message):
            return AlertResponse(title: "Errore", message: "L'URL \(message) non è valido")
        }
    }
}

enum Codes: Error {
    case code400(message: String)
    case code409(message: String)
    case code500(message: String)
    
    var response: AlertResponse {
        switch self {
        case .code400(let message):
            return AlertResponse(title: "Errore", message: "Richiesta non completa: \(message)")
        case .code409(let message):
            return AlertResponse(title: "Errore", message: "È stato trovato un conflitto: \(message)")
        case .code500(let message):
            return AlertResponse(title: "Errore", message: "C'è stato un errore del server: \(message)")
        }
    }
}

enum Alert {
    case sucess(username: String)
    case failureUsername(username: String)
    case failureMail(mail: String)
    case failureUsernameMail(username: String, mail: String)
    
    var response: AlertResponse {
        switch self {
        case .sucess(let username):
            return AlertResponse(title: "Successo", message: "\(username) sei stato registrato con successo!")
        case .failureUsername(let username):
            return AlertResponse(title: "Errore", message: "L'username \(username) è già in uso.")
        case .failureMail(let mail):
            return AlertResponse(title: "Errore", message: "L'email \(mail) è già in uso.")
        case .failureUsernameMail(let username, let mail):
            return AlertResponse(title: "Errore", message: "L'username \(username) e la email \(mail) sono già in uso.")
        }
    }
}

struct ApiResponse: Codable {
    let success: Bool
    let message: String
    let data: DataField?
}

struct DataField: Codable {
    let exists: Bool?
    let username: String?
    let email: String?
}


class UserManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var authToken: String? = nil
    @Published var currentUser: User? = nil
    
    // Register a user
    @MainActor
    func registerUser(password: String) async throws -> Alert {
        guard let url = URL(string: "\(URN)/register") else {
            throw RegistrationError.invalidURL(message: "\(URN)/register")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create the registration payload
        let registrationPayload: [String: Any] = [
            "name": currentUser?.name ?? "",
            "surname": currentUser?.surname ?? "",
            "username": currentUser?.username ?? "",
            "email": currentUser?.mail ?? "",
            "password": password
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: registrationPayload)
        } catch let err {
            throw RegistrationError.JSONError(message: err.localizedDescription)
        }
        
        let session = URLSession.shared
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw RegistrationError.invalidResponse(message: "Invalid response from server.")
            }
            
            let statusCode = httpResponse.statusCode
            let apiResponse = try JSONDecoder().decode(ApiResponse.self, from: data)
            print("Success: \(apiResponse.success)")
            print("Message: \(apiResponse.message)")
            
            switch statusCode {
            case 201:
                if let username = apiResponse.data?.username {
                    return Alert.sucess(username: username)
                } else {
                    return Alert.sucess(username: "User") //boh
                }
            case 400:
                throw Codes.code400(message: apiResponse.message)
            case 409:
                if let username = apiResponse.data?.username, let mail = apiResponse.data?.email {
                    return Alert.failureUsernameMail(username: username, mail: mail)
                } else if let username = apiResponse.data?.username {
                    return Alert.failureUsername(username: username)
                } else if let mail = apiResponse.data?.email {
                    return Alert.failureMail(mail: mail)
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
        } catch {
            throw RegistrationError.unknownError(message: error.localizedDescription)
        }
    }
    /*
    // Login user and get a token
    func loginUser(user: User, completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "\(URN)/login")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "email": user.mail,
            "password": user.password
        ]
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            completion(.failure(error))
            return
        }
        
        let session = URLSession.shared
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let token = json["token"] as? String,
                   let userInfo = json["user"] as? [String: String] {
                    
                    let user = User(
                        name: userInfo["name"] ?? "",
                        surname: userInfo["surname"] ?? "",
                        username: userInfo["username"] ?? "",
                        mail: user.mail,
                        password: user.password // Store securely if needed
                    )
                    DispatchQueue.main.async {
                        self.currentUser = user
                        self.authToken = token
                        self.isAuthenticated = true
                    }
                    completion(.success(token))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to parse token"])))
                }
            } else {
                let errorMessage = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
            }
        }.resume()
    }*/
    
    // Save token securely
    func saveToken(token: String) {
        UserDefaults.standard.setValue(token, forKey: "authToken")
    }
    
    // Retrieve token from UserDefaults
    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: "authToken")
    }
}
