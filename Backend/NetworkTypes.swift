//
//  NetworkTypes.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 25/03/25.
//

import SwiftUI

struct LogInResponse: Codable {
    let roleGroups: [RoleGroup]
    let authToken: String
    
    struct RoleGroup: Codable, Identifiable  {
        let id: UUID = UUID()
        
        let role: Roles
        let userModels: [UserModel]
        
        enum CodingKeys: String, CodingKey {
            case role = "roleId"
            case userModels = "users"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            let role = Roles.from(try container.decode(Int.self, forKey: .role))
            
            var users: [User]
            
            switch Roles.isType(role.rawValue) {
            case is Student.Type:
                users = try container.decode([Student].self, forKey: .userModels)
            case is Teacher.Type:
                users = try container.decode([Teacher].self, forKey: .userModels)
            case is Admin.Type:
                users = try container.decode([Admin].self, forKey: .userModels)
            case is Principal.Type:
                users = try container.decode([Principal].self, forKey: .userModels)
            case is Secretariat.Type:
                users = try container.decode([Secretariat].self, forKey: .userModels)
            default:
                users = try container.decode([User].self, forKey: .userModels)
            }
            
            self.userModels = users.map { UserModel(user: $0, role: role) }
            self.role = role
        }
    }
}

struct LoginUser: Codable {
    let userToken: String
    let mainUser: MainUser
    
    enum CodingKeys: String, CodingKey {
        case userToken
        case mainUser
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.userToken = try container.decode(String.self, forKey: .userToken)
        self.mainUser = try container.decode(MainUser.self, forKey: .mainUser)
    }
}

protocol DefaultPersistenceProtocol {
    static var 🔑: DefaultPersistence.Saves { get }
}

struct DefaultPersistence {
    enum Saves: String {
        case mainUser = "MainUser"
        case tab = "Tab"
        case isNotificationActive = "IsNotificationActive"
    }
    
    private init() {}
    
    static func save<T: DefaultPersistenceProtocol & Encodable>(for data: T) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(data) {
            UserDefaults.standard.set(encoded, forKey: T.🔑.rawValue)
        }
    }

    static func retrieve<T: DefaultPersistenceProtocol & Decodable>() -> T? {
        if let savedUserData = UserDefaults.standard.object(forKey: T.🔑.rawValue) as? Data {
            let decoder = JSONDecoder()
            if let loadedData = try? decoder.decode(T.self, from: savedUserData) {
                return loadedData
            }
        }
        return nil
    }
    
    static func delete<T: DefaultPersistenceProtocol>(type: T.Type) {
        UserDefaults.standard.removeObject(forKey: T.🔑.rawValue)
    }
}

extension UIImage {
    func toData() -> Data? {
        self.jpegData(compressionQuality: 1)
    }
}

extension Data {
    func toImage() -> UIImage? {
        UIImage(data: self)
    }
}

extension URL {
    func URLToUIImage() -> UIImage? {
        UIImage(contentsOfFile: self.path())
    }
    func URLToImage() -> Image? {
        if let uiImage = UIImage(contentsOfFile: self.path()) {
            return Image(uiImage: uiImage)
        } else {
            return nil
        }
    }
}

extension FileManager {
    func fileExists(at url: URL) -> Bool {
        self.fileExists(atPath: url.path)
    }
}

struct Timetable: Codable {
    let TimetableEntrys: [TimetableEntry]
    let classe: Classs
    
    enum CodingKeys: String, CodingKey {
        case TimetableEntrys = "timetable"
        case classe = "class"
    }
}

struct TimetableEntry: Codable {
    let id: UUID
    let weekDay: String
    let startTime: String
    let endTime: String
    let subjectIds: [Teacher.Subjectt]
    let teachers: [Teacher]?

    enum CodingKeys: String, CodingKey {
        case id, weekDay, startTime, endTime, subjectIds, teachers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        weekDay = try container.decode(String.self, forKey: .weekDay)
        startTime = try container.decode(String.self, forKey: .startTime)
        endTime = try container.decode(String.self, forKey: .endTime)
        let subjectIntIds = try container.decode([Int].self, forKey: .subjectIds)
        self.subjectIds = subjectIntIds.compactMap { Teacher.Subjectt.from($0) }
        
        teachers = try container.decodeIfPresent([Teacher].self, forKey: .teachers)
    }
}
