//
//  User.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 05/12/24.
//

import SwiftUI

struct User: CustomStringConvertible, Equatable, Comparable, Codable {
    var description: String {
        return "\(name)"
    }
    var name: String
    var surname: String
    var username: String
    var mail: String
    
    init(name: String = "", surname: String = "", username: String = "", mail: String = ".stud@itisgalileiroma.it") {
        self.name = name
        self.surname = surname
        self.username = username
        self.mail = mail
    }
    
    static func < (lhs: User, rhs: User) -> Bool {
        //TO DO
        return false
    }
}
