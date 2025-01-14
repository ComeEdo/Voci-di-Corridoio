//
//  User.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 05/12/24.
//

import SwiftUI

struct User: CustomStringConvertible, Equatable, Comparable, Codable {
    var description: String {
        return "\(name)\n\(surname)\n\(username)"
    }
    
    var name: String
    var surname: String
    var username: String
    
    init(name: String = "", surname: String = "", username: String = "") {
        self.name = name
        self.surname = surname
        self.username = username
    }
    
    static func < (lhs: User, rhs: User) -> Bool {
        //TO DO
        return false
    }
}
