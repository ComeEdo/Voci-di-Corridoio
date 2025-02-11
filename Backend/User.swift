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
}

class User: CustomStringConvertible, Equatable, Comparable, Codable, Identifiable {
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
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
    override var description: String {
        return super.description + "\nRole: Teacher"
    }
}


class Admin: User {}
class Principal: User {}
class Secretariat: User {}
