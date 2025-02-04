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
    
    init(id: UUID, name: String, surname: String, username: String, role: Roles, classe: Classs, studyFieldName: String) {
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
