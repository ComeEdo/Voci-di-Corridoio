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
            } catch let error as Notifiable {
                NotificationManager.shared.showBottom(error.notification)
            } catch {
                NotificationManager.shared.showBottom(MainNotification.NotificationStructure(title: "Errore", message: "\(error.localizedDescription)", type: .error))
            }
        }
    }
    
    @MainActor
    private func fetchAvailableClasses() async throws {
        guard let url = URL(string: "https://levoci.local/api/classes/registration") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            let statusCode = httpResponse.statusCode
            let apiResponse = try JSONDecoder().decode(ApiResponse<Classes>.self, from: data)
            
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
    case let error as Codes:
        return error
    case let error as URLError:
        return error
    default:
        return RegistrationError.unknownError(message: error.localizedDescription)
    }
}
