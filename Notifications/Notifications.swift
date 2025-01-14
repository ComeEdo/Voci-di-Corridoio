//
//  Notifications.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 10/01/25.
//

enum Codes: Error {
    case code400(message: String)
    case code409(message: String)
    case code500(message: String)
    
    var response: MainNotification.NotificationStructure {
        switch self {
        case .code400(let message):
            return MainNotification.NotificationStructure(title: "Errore", message: "Richiesta non completa: \(message)")
        case .code409(let message):
            return MainNotification.NotificationStructure(title: "Errore", message: "È stato trovato un conflitto: \(message)")
        case .code500(let message):
            return MainNotification.NotificationStructure(title: "Errore", message: "C'è stato un errore del server: \(message)")
        }
    }
}

enum RegistrationNotification: CustomStringConvertible {
    case sucess(username: String)
    case failureUsername(username: String)
    case failureMail(mail: String)
    case failureUsernameMail(username: String, mail: String)
    
    var response: MainNotification.NotificationStructure {
        switch self {
        case .sucess(let username):
            return MainNotification.NotificationStructure(title: "Successo", message: "\(username) sei stato registrato con successo!")
        case .failureUsername(let username):
            return MainNotification.NotificationStructure(title: "Errore", message: "L'username \(username) è già in uso.")
        case .failureMail(let mail):
            return MainNotification.NotificationStructure(title: "Errore", message: "L'email \(mail) è già in uso.")
        case .failureUsernameMail(let username, let mail):
            return MainNotification.NotificationStructure(title: "Errore", message: "L'username \(username) e la email \(mail) sono già in uso.")
        }
    }
    
    var description: String {
        "\(response.title)\n\n\(response.message)"
    }
}

enum RegistrationError: Error {
    case invalidResponse(message: String)
    case unknownError(message: String)
    case JSONError(message: String)
    case invalidURL(message: String)
    
    var message: MainNotification.NotificationStructure {
        switch self {
        case .invalidResponse(let message):
            return MainNotification.NotificationStructure(title: "Errore", message: "Risposta del server non valida: \(message)")
        case .unknownError(let message):
            return MainNotification.NotificationStructure(title: "Errore", message: "Errore riscontrato:\n\(message)")
        case .JSONError(let message):
            return MainNotification.NotificationStructure(title: "Errore", message: "Errore JSON riscontrato:\n\(message)")
        case .invalidURL(let message):
            return MainNotification.NotificationStructure(title: "Errore", message: "L'URL \(message) non è valido")
        }
    }
}

enum LoginNotification: CustomStringConvertible {
    case sucess(username: String)
    case failureUsername(username: String)
    case failureMail(mail: String)
    case failureUsernameMail(username: String, mail: String)
    
    var response: MainNotification.NotificationStructure {
        switch self {
        case .sucess(let username):
            return MainNotification.NotificationStructure(title: "Successo", message: "\(username) sei stato registrato con successo!")
        case .failureUsername(let username):
            return MainNotification.NotificationStructure(title: "Errore", message: "L'username \(username) è già in uso.")
        case .failureMail(let mail):
            return MainNotification.NotificationStructure(title: "Errore", message: "L'email \(mail) è già in uso.")
        case .failureUsernameMail(let username, let mail):
            return MainNotification.NotificationStructure(title: "Errore", message: "L'username \(username) e la email \(mail) sono già in uso.")
        }
    }
    
    var description: String {
        "\(response.title)\n\n\(response.message)"
    }
}
