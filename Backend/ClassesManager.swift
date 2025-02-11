//
//  ClassesManager.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 18/01/25.
//

import SwiftUI

struct Classs: Codable {
    let id: UUID
    let name: String
}

struct Classes: Codable {
    let classes: [Classs]
}

class ClassesManager: ObservableObject {
    @Published private(set) var classes: [Classs] = []
    
    init() {
        Task {
            do {
                try await fetchAvailableClasses()
            } catch let error as ServerError {
                SSLAlert(error)
            } catch let error as Notifiable {
                Utility.setupBottom(error.notification)
            } catch {
                Utility.setupBottom(MainNotification.NotificationStructure(title: "Errore", message: "\(error.localizedDescription)", type: .error))
            }
        }
    }
    
    @MainActor
    private func fetchAvailableClasses() async throws {
        guard let url = URL(string: "\(UserManager.shared.URN)\(UserManager.APIEndpoints.fetchAvailableClasses)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let (httpResponse, apiResponse): (HTTPURLResponse, ApiResponseData<Classes>) = try checkResponse(data: data, response: response)
            
            let statusCode = httpResponse.statusCode
            
            switch statusCode {
            case 200:
                if let classes = apiResponse.data?.classes {
                    self.classes = classes
                } else {
                    throw ClassesError.noClassesFound
                }
            default:
                throw Codes.code500(message: apiResponse.message)
            }
        } catch {
            throw mapError(error)
        }
    }
}

func mapError(_ error: Error) -> Error {
    switch error {
    case let error as DecodingError:
        return Errors.JSONError(message: error.localizedDescription)
    case let error as URLError:
        if isSSLError(error) {
            return ServerError.sslError
        }
        return error
    case let error as Codes:
        return error
    case let error as Errors:
        return error
    case let error as LoginError:
        return error
    case let error as ServerError:
        return error
    case let error as ClassesError:
        return error
    case let error as AuthError:
        return error
    default:
        return Errors.unknownError(message: error.localizedDescription)
    }
}

func isSSLError(_ error: Error) -> Bool {
    let nsError = error as NSError
    let errorDomain = NSURLErrorDomain
    let errorCode = -1202
    
    if nsError.domain == errorDomain && nsError.code == errorCode {
        return true
    }
    return false
}

func SSLAlert(_ notification: MainNotification.NotificationStructure) {
    NotificationManager.shared.showAlert(notification) {
        if let url = URL(string: "https://\(UserManager.shared.server)\(UserManager.APIEndpoints.SSLCertificate)") {
            DispatchQueue.main.async {
                UIApplication.shared.open(url)
            }
        }
    }
}

func SSLAlert(_ error: ServerError) {
    if error == .sslError {
        SSLAlert(error.notification)
    } else {
        Utility.setupBottom(error.notification)
    }
}

func checkResponse<T: Codable, V: ApiResponseData<T>>(data: Data, response: URLResponse?) throws -> (HTTPURLResponse, V) {
    guard let httpResponse = response as? HTTPURLResponse else {
        throw URLError(.badServerResponse)
    }
    
    if httpResponse.statusCode == 503 {
        if let responseString = String(data: data, encoding: .utf8) {
            let patterns = [
                "<title>503 Service Unavailable</title>",
                "<h1>Service Unavailable</h1>",
                "The server is temporarily unable to service your request"
            ]
            for pattern in patterns {
                if responseString.contains(pattern) {
                    throw ServerError.serviceUnavailable
                }
            }
        }
    }
    
    let apiResponse = try JSONDecoder().decode(V.self, from: data)
    
    if let authResponse = apiResponse as? ApiResponseAuthData<T>, let auth = authResponse.auth {
        if let logOut = auth.logOut, logOut {
            UserManager.shared.logoutUser()
        }
    } else if let userResponse = apiResponse as? ApiResponseUserData<T> {
        if let logOut = userResponse.user?.logOut, logOut {
            UserManager.shared.logoutUser()
        }
        if let updateToken = userResponse.user?.updateToken, updateToken {
            if let userId = UserManager.shared.currentUser?.id {
                Task {
                    do {
                        let alert = try await UserManager.shared.getUserAndToken(userId)
                        Utility.setupBottom(alert.notification)
                    } catch let error as ServerError {
                        SSLAlert(error)
                    } catch let error as Notifiable {
                        print(error.description)
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    return (httpResponse, apiResponse)
}


func checkResponse(data: Data, response: URLResponse?) throws -> (HTTPURLResponse, ApiResponse) {
    guard let httpResponse = response as? HTTPURLResponse else {
        throw URLError(.badServerResponse)
    }
    if httpResponse.statusCode == 503 {
        if let responseString = String(data: data, encoding: .utf8) {
            let patterns = [
                "<title>503 Service Unavailable</title>",
                "<h1>Service Unavailable</h1>",
                "The server is temporarily unable to service your request"
            ]
            for pattern in patterns {
                if responseString.contains(pattern) {
                    throw ServerError.serviceUnavailable
                }
            }
        }
    }
    return (httpResponse, try JSONDecoder().decode(ApiResponse.self, from: data))
}
