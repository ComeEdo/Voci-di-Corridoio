//
//  ClassesManager.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 18/01/25.
//

import SwiftUI

struct Classs: Codable, Comparable, Identifiable {
    let id: UUID
    let name: String
    
    static func < (lhs: Classs, rhs: Classs) -> Bool {
        let left = lhs.extractNumberAndLetter()
        let right = rhs.extractNumberAndLetter()
        
        if left.number != right.number {
            return left.number < right.number
        } else {
            return left.letter > right.letter
        }
    }
    
    private func extractNumberAndLetter() -> (number: Int, letter: String) {
        let regex = try? NSRegularExpression(pattern: "(\\d*)([a-zA-Z0-9]*)")
        let match = regex?.firstMatch(in: name, options: [], range: NSRange(name.startIndex..., in: name))
        
        if let match = match, let numberRange = Range(match.range(at: 1), in: name), let letterRange = Range(match.range(at: 2), in: name) {
            let number = Int(name[numberRange]) ?? 0
            let letter = String(name[letterRange])
            return (number, letter)
        } else {
            return (0, "")
        }
    }
}

class ClassesManager: ObservableObject {
    @Published private(set) var classes: [Classs] = []
    
    init() {
        Task {
            do {
                try await fetchAvailableClasses()
            } catch {
                if let err = mapError(error) {
                    Utility.setupBottom(err.notification)
                }
            }
        }
    }
    
    struct Classes: Codable {
        let classes: [Classs]
    }
    
    @MainActor
    private func fetchAvailableClasses() async throws {
        guard let url = URL(string: "\(UserManager.shared.URN)\(UserManager.APIEndpoints.fetchAvailableClasses)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let (httpResponse, apiResponse): (HTTPURLResponse, ApiResponseData<Classes>) = try checkResponse(response: response, data: data)
        
        let statusCode = httpResponse.statusCode
        
        switch (statusCode, apiResponse.data?.classes) {
        case (200, let classes?):
            self.classes = classes
        case (200, nil):
            throw ClassesError.noClassesFound
        default:
            throw Codes.code500(message: apiResponse.message)
        }
    }
}

func mapError(_ error: Error) -> (Error & Notifiable)? {
    switch error {
    case let error as DecodingError:
        return Errors.JSONError(message: error.localizedDescription)
    case let error as EncodingError:
        return Errors.JSONError(message: error.localizedDescription)
    case let error as URLError where isSSLError(error):
            SSLAlert()
            return nil
    case let error as Error & Notifiable:
        return error
    default:
        return Errors.unknownError(message: error.localizedDescription)
    }
}

fileprivate func isSSLError(_ error: Error) -> Bool {
    let nsError = error as NSError
    let errorDomain = NSURLErrorDomain
    let errorCode = -1202
    
    if nsError.domain == errorDomain && nsError.code == errorCode {
        return true
    }
    return false
}

fileprivate func SSLAlert() {
    NotificationManager.shared.showAlert(ServerError.sslError.notification) {
        if let url = URL(string: "https://\(UserManager.shared.domain.rawValue)\(UserManager.APIEndpoints.SSLCertificate)") {
            DispatchQueue.main.async {
                UIApplication.shared.open(url)
            }
        }
    }
}

fileprivate func isServerOffline(data: Data, httpResponse: HTTPURLResponse) throws {
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
}

func checkResponse<T: Codable, V: ApiResponseData<T>>(response: URLResponse?, data: Data) throws -> (HTTPResponse: HTTPURLResponse, ApiResponse: V) {
    guard let httpResponse = response as? HTTPURLResponse else {
        throw URLError(.badServerResponse)
    }
    
    try isServerOffline(data: data, httpResponse: httpResponse)
    
    let apiResponse = try JSONDecoder().decode(V.self, from: data)
    
    if let authResponse = apiResponse as? ApiResponseAuthData<T>, let auth = authResponse.auth {
        if let logOut = auth.logOut, logOut {
            UserManager.shared.logoutUser()
        }
    } else if let userResponse = apiResponse as? ApiResponseUserData<T> {
        if let logOut = userResponse.user?.logOut, logOut {
            UserManager.shared.logoutUser()
        } else if let updateUserAndToken = userResponse.user?.updateUserAndToken, updateUserAndToken {
            if let userId = UserManager.shared.mainUser?.user.id {
                Task {
                    do {
                        try await UserManager.shared.getAuthUserAndToken(userId)
                    } catch {
                        if let err = mapError(error) {
                            print(err.description)
                        }
                    }
                }
            }
        }
    }
    
    return (httpResponse, apiResponse)
}


func checkResponse(response: URLResponse?, data: Data) throws -> (HTTPResponse: HTTPURLResponse, ApiResponse: ApiResponse) {
    guard let httpResponse = response as? HTTPURLResponse else {
        throw URLError(.badServerResponse)
    }

    try isServerOffline(data: data, httpResponse: httpResponse)
    
    return (httpResponse, try JSONDecoder().decode(ApiResponse.self, from: data))
}
