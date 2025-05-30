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
        case postPicker = "PostPicker"
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
    let TimetableEntries: [TimetableEntry]
    let classe: Classs
    
    enum CodingKeys: String, CodingKey {
        case TimetableEntries = "timetable"
        case classe = "class"
    }
}

struct TimetableEntry: Codable, Identifiable {
    let id: UUID
    let weekDay: WeekDay
    let startTime: Date
    let endTime: Date
    let subjectModels: [SubjectModel]
    let teachers: [Teacher]?
    
    init(id: UUID = UUID(), weekDay: WeekDay, startTime: Date, endTime: Date, subjectModels: [SubjectModel], teachers: [Teacher]? = nil) {
        self.id = id
        self.weekDay = weekDay
        self.startTime = startTime
        self.endTime = endTime
        self.subjectModels = subjectModels
        self.teachers = teachers
    }
    init?(id: UUID = UUID(), weekDay: WeekDay, startTime: String, endTime: String, subjectModels: [SubjectModel], teachers: [Teacher]? = nil) {
        self.id = id
        self.weekDay = weekDay
        
        guard let s = TimetableEntry.timeFormatter.date(from: startTime) else {
            print("Invalid time format for startTime: \(startTime)")
            return nil
        }
        self.startTime = s
        
        guard let e = TimetableEntry.timeFormatter.date(from: endTime) else {
            print("Invalid time format for endTime: \(endTime)")
            return nil
        }
        self.endTime = e
        
        self.subjectModels = subjectModels
        self.teachers = teachers
    }
    init(timetableEntry entry: TimetableEntry, date: Date) {
        self.id = entry.id
        self.weekDay = entry.weekDay
        self.startTime = date.settingTime(from: entry.startTime)!
        self.endTime = date.settingTime(from: entry.endTime)!
        self.subjectModels = entry.subjectModels
        self.teachers = entry.teachers
    }
    
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()
    
    enum CodingKeys: String, CodingKey {
        case id
        case weekDay
        case startTime
        case endTime
        case subjectModels = "subjects"
        case teachers
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        
        weekDay = try container.decode(WeekDay.self, forKey: .weekDay)
        
        let startStr = try container.decode(String.self, forKey: .startTime)
        guard let s = TimetableEntry.timeFormatter.date(from: startStr) else {
            throw DecodingError.dataCorruptedError(forKey: .startTime, in: container, debugDescription: "Invalid time format: \(startStr)")
        }
        startTime = s
        
        let endStr = try container.decode(String.self, forKey: .endTime)
        guard let e = TimetableEntry.timeFormatter.date(from: endStr) else {
            throw DecodingError.dataCorruptedError(forKey: .endTime, in: container, debugDescription: "Invalid time format: \(endStr)")
        }
        endTime = e
        
        self.subjectModels = try container.decode([SubjectModel].self, forKey: .subjectModels)
        
        teachers = try container.decodeIfPresent([Teacher].self, forKey: .teachers)
    }
}

enum WeekDay: String, Codable {
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    case sunday = "Sunday"
    
    init?(calendarWeekday: Int) {
        switch calendarWeekday {
        case 1:
            self = .sunday
        case 2:
            self = .monday
        case 3:
            self = .tuesday
        case 4:
            self = .wednesday
        case 5:
            self = .thursday
        case 6:
            self = .friday
        case 7:
            self = .saturday
        default:
            return nil
        }
    }
}
