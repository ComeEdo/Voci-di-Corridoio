//
//  ClassesManager.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 18/01/25.
//

import SwiftUI

struct Classes: Codable {
    let classes: [UUID: String]
    
    enum CodingKeys: String, CodingKey {
        case classes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let classesDict = try container.decode([String: String].self, forKey: .classes)
        
        var uuidClasses = [UUID: String]()
        for (key, value) in classesDict {
            if let uuid = UUID(uuidString: key) {
                uuidClasses[uuid] = value
            }
        }
        self.classes = uuidClasses
    }
}

class ClassesManager: ObservableObject {
    @Published private(set) var classes: [UUID: String] = [:]
    
    init() {
        Task {
            do {
                try await fetchAvailableClasses()
            } catch let error as ServerError {
                SSLAlert(error)
            } catch let error as Notifiable {
                NotificationManager.shared.showBottom(error.notification)
            } catch {
                NotificationManager.shared.showBottom(MainNotification.NotificationStructure(title: "Errore", message: "\(error.localizedDescription)", type: .error))
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
            
            let (httpResponse, apiResponse): (HTTPURLResponse, ApiResponse<Classes>) = try checkResponse(data: data, response: response)
            
            let statusCode = httpResponse.statusCode
            
            switch statusCode {
            case 200:
                if let classes = apiResponse.data?.classes {
                    self.classes = classes
                } else {
                    throw RegistrationError.noClassesFound
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
        return RegistrationError.JSONError(message: error.localizedDescription)
    case let error as URLError:
        if isSSLError(error) {
            return ServerError.sslError
        }
        return error
    case let error as Codes:
        return error
    case let error as ServerError:
        return error
    default:
        return RegistrationError.unknownError(message: error.localizedDescription)
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
        NotificationManager.shared.showBottom(error.notification)
    }
}

func checkResponse<T: Codable>(data: Data, response: URLResponse?) throws -> (HTTPURLResponse, ApiResponse<T>) {
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
    return (httpResponse, try JSONDecoder().decode(ApiResponse<T>.self, from: data))
}
