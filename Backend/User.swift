//
//  User.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 05/12/24.
//

import SwiftUI

struct LoginResponse: Codable {
    let roleGroups: [RoleGroup]
    let authToken: String
    
    struct RoleGroup: Codable {
        let roleId: Int
        let users: [User]
        
        enum CodingKeys: String, CodingKey {
            case roleId
            case users
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.roleId = try container.decode(Int.self, forKey: .roleId)
            
            let userType = Roles.isType(roleId)
            
            switch userType {
            case is Student.Type:
                self.users = try container.decode([Student].self, forKey: .users)
            case is Teacher.Type:
                self.users = try container.decode([Teacher].self, forKey: .users)
            case is Admin.Type:
                self.users = try container.decode([Admin].self, forKey: .users)
            case is Principal.Type:
                self.users = try container.decode([Principal].self, forKey: .users)
            case is Secretariat.Type:
                self.users = try container.decode([Secretariat].self, forKey: .users)
            default:
                self.users = try container.decode([User].self, forKey: .users)
            }
        }
    }
}

struct LoginUser: Codable {
    let userToken: String
    let roleId: Int
    let user: User
    
    enum CodingKeys: String, CodingKey {
        case userToken
        case roleId
        case user
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.userToken = try container.decode(String.self, forKey: .userToken)
        self.roleId = try container.decode(Int.self, forKey: .roleId)
        
        let userType = Roles.isType(roleId)
        
        switch userType {
        case is Student.Type:
            self.user = try container.decode(Student.self, forKey: .user)
        case is Teacher.Type:
            self.user = try container.decode(Teacher.self, forKey: .user)
        case is Admin.Type:
            self.user = try container.decode(Admin.self, forKey: .user)
        case is Principal.Type:
            self.user = try container.decode(Principal.self, forKey: .user)
        case is Secretariat.Type:
            self.user = try container.decode(Secretariat.self, forKey: .user)
        default:
            self.user = try container.decode(User.self, forKey: .user)
        }
    }
}

struct UserPersistance: Codable {
    let user: User
    let role: Roles
    
    init(user: User, role: Roles) {
        self.user = user
        self.role = role
    }
    
    enum CodingKeys: String, CodingKey {
        case role
        case user
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.role = Roles(rawValue: try container.decode(Int.self, forKey: .role))!
        
        switch Roles.isType(role.rawValue) {
        case is Student.Type:
            self.user = try container.decode(Student.self, forKey: .user)
        case is Teacher.Type:
            self.user = try container.decode(Teacher.self, forKey: .user)
        case is Admin.Type:
            self.user = try container.decode(Admin.self, forKey: .user)
        case is Principal.Type:
            self.user = try container.decode(Principal.self, forKey: .user)
        case is Secretariat.Type:
            self.user = try container.decode(Secretariat.self, forKey: .user)
        default:
            self.user = try container.decode(User.self, forKey: .user)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role.rawValue, forKey: .role)
        
        switch user {
        case let student as Student:
            try container.encode(student, forKey: .user)
        case let teacher as Teacher:
            try container.encode(teacher, forKey: .user)
        case let admin as Admin:
            try container.encode(admin, forKey: .user)
        case let principal as Principal:
            try container.encode(principal, forKey: .user)
        case let secretariat as Secretariat:
            try container.encode(secretariat, forKey: .user)
        default:
            try container.encode(user, forKey: .user)
        }
    }
    
    static func saveUserPersistance(userPersistance: UserPersistance) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(userPersistance) {
            UserDefaults.standard.set(encoded, forKey: "UserPersistance")
        }
    }

    static func retrieveUserPersistance() -> UserPersistance? {
        if let savedUserData = UserDefaults.standard.object(forKey: "UserPersistance") as? Data {
            let decoder = JSONDecoder()
            if let loadedUserPersistance = try? decoder.decode(UserPersistance.self, from: savedUserData) {
                return loadedUserPersistance
            }
        }
        return nil
    }
    
    static func deleteUserPersistance() {
        UserDefaults.standard.removeObject(forKey: "UserPersistance")
    }
}

struct Timetable: Codable {
    let TimetableEntrys: [TimetableEntry]
    
    enum CodingKeys: String, CodingKey {
        case TimetableEntrys = "timetable"
    }
}

struct TimetableEntry: Codable, Hashable {
    let id: UUID
    let weekDay: String
    let startTime: String
    let endTime: String
    let subjectIds: [Teacher.Subject]
    let teachers: [Teacher]?

    // Custom decoding to remove null values
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
        self.subjectIds = subjectIntIds.compactMap { Teacher.Subject.from($0) }
        
        teachers = try container.decodeIfPresent([Teacher].self, forKey: .teachers)
    }
}


class User: CustomStringConvertible, Equatable, Comparable, Codable, Identifiable, Hashable {
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var description: String {
        return "\(name) \(surname)\nUsername: \(username)"
    }
    
    let id: UUID
    var name: String
    var surname: String
    var username: String
    
    init(id: UUID, name: String, surname: String, username: String) {
        self.id = id
        self.name = name
        self.surname = surname
        self.username = username
    }
    
    static func < (lhs: User, rhs: User) -> Bool {
        return lhs.username < rhs.username
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.surname = try container.decode(String.self, forKey: .surname)
        self.username = try container.decode(String.self, forKey: .username)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id = "userId"
        case name = "firstName"
        case surname = "lastName"
        case username = "username"
    }
}

class Student: User {
    var classe: Classs
    var studyFieldName: String
    
    init(id: UUID, name: String, surname: String, username: String, classe: Classs, studyFieldName: String) {
        self.classe = classe
        self.studyFieldName = studyFieldName
        super.init(id: id, name: name, surname: surname, username: username)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.classe = try container.decode(Classs.self, forKey: .classe)
        self.studyFieldName = try container.decode(String.self, forKey: .studyFieldName)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(classe, forKey: .classe)
        try container.encode(studyFieldName, forKey: .studyFieldName)
        try super.encode(to: encoder)
    }
    
    private enum CodingKeys: String, CodingKey {
        case classe = "class"
        case studyFieldName = "studyFieldName"
    }
    
    override var description: String {
        return super.description + "\nClass: \(classe.name) (ID: \(classe.id))\nStudy Field: \(studyFieldName)"
    }
}

class Teacher: User {
    enum Subject: Int, Codable {
        case matematica         = 1
        case lettere            = 2
        case informatica        = 3
        case tpsit              = 4
        case inglese            = 5
        case educazioneFisica   = 6
        case religione          = 7
        case sistemiEReti       = 8
        case gpoi               = 9
        case tutor              = 10
        case ricreazione        = 11
        case informaticaLab     = 12
        case sistemiERetiLab    = 13
        case tpsitLab           = 14
        case gpoiLab            = 15
        case automazione        = 16
        case cnc                = 17
        
        static func from(_ id: Int) -> Subject {
            return Subject(rawValue: id) ?? .ricreazione
        }

        var name: String {
            switch self {
            case .matematica: return "Matematica"
            case .lettere: return "Lettere"
            case .informatica: return "Informatica"
            case .tpsit: return "TPSIT"
            case .inglese: return "Inglese"
            case .educazioneFisica: return "Educazione fisica"
            case .religione: return "Religione"
            case .sistemiEReti: return "Sistemi e Reti"
            case .gpoi: return "G.P.O.I"
            case .tutor: return "Tutor"
            case .ricreazione: return "Ricreazione"
            case .informaticaLab: return "Informatica Lab"
            case .sistemiERetiLab: return "Sistemi e Reti Lab"
            case .tpsitLab: return "TPSIT Lab"
            case .gpoiLab: return "G.P.O.I Lab"
            case .automazione: return "Automazione"
            case .cnc: return "CNC"
            }
        }

        var description: String {
            switch self {
            case .matematica: return "Studio dei numeri, delle equazioni e delle funzioni."
            case .lettere: return "Studi letterari, la grammatica e la cultura delle lingue."
            case .informatica: return "Studio dei concetti e delle tecniche dell'informatica."
            case .tpsit: return "Tecnologie per la produzione di sistemi informatici e telematici."
            case .inglese: return "Studio della lingua e cultura inglese."
            case .educazioneFisica: return "Attività fisica e sportiva per il benessere."
            case .religione: return "Studio delle tradizioni religiose e della loro cultura."
            case .sistemiEReti: return "Studio delle infrastrutture e dei sistemi informatici."
            case .gpoi: return "Gestione e organizzazione di sistemi informatici e reti."
            case .tutor: return "Attività di supporto e assistenza agli studenti."
            case .ricreazione: return "Momento di svago e gioco."
            case .informaticaLab: return "Laboratorio per l'applicazione pratica dei concetti di informatica."
            case .sistemiERetiLab: return "Laboratorio per l'applicazione pratica delle infrastrutture e dei sistemi informatici e delle reti."
            case .tpsitLab: return "Laboratorio per l'applicazione pratica delle tecnologie per la produzione di sistemi informatici e telematici."
            case .gpoiLab: return "Laboratorio per l'applicazione pratica della gestione di sistemi informatici e reti."
            case .automazione: return "Studio dei processi automatizzati e della loro applicazione industriale."
            case .cnc: return "Studio e gestione delle macchine a controllo numerico per la produzione industriale."
            }
        }
    }

    
    override var description: String {
        return super.description + "\nRole: Teacher"
    }
}


class Admin: User {}
class Principal: User {}
class Secretariat: User {}
