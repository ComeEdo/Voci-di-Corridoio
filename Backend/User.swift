//
//  User.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 05/12/24.
//

import SwiftUI

class User: CustomStringConvertible, Equatable, Comparable, Codable, Identifiable {
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
    
    var description: String {
        return "\(name)\n\(surname)\n\(username)"
    }
    
    let id: UUID
    var name: String
    var surname: String
    var username: String
        
    init(name: String = "", surname: String = "", username: String = "", id: UUID = UUID()) {
        self.name = name
        self.surname = surname
        self.username = username
        self.id = id
    }
    
    static func < (lhs: User, rhs: User) -> Bool {
        return lhs.username < rhs.username
    }
}

//class Student: User {
//    var classe: (UUID, String)
//    
//    init(name: String, surname: String, username: String, subjects: [Subject] = []) {
//        self.classe =
//        super.init(name: name, surname: surname, username: username)
//    }
//}
