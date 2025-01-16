//
//  Notifications.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 10/01/25.
//

import Foundation

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

/*
extension URLError {
    
    var response: MainNotification.NotificationStructure{
        switch self.code {
        case .notConnectedToInternet:
            return MainNotification.NotificationStructure(title: "No Internet", message: "Please check your internet connection and try again.")
        case .timedOut:
            return MainNotification.NotificationStructure(title: "Request Timeout", message: "The request timed out. Please try again later.")
        case .cannotFindHost:
            return MainNotification.NotificationStructure(title: "Host Not Found", message: "Unable to find the host. Please check the URL or try again later.")
        case .cannotConnectToHost:
            return MainNotification.NotificationStructure(title: "Cannot Connect to Host", message: "Unable to connect to the host. Please check the server or your network.")
        case .badServerResponse:
            return MainNotification.NotificationStructure(title: "Server Error", message: "The server responded with an error. Please try again later.")
        case .unsupportedURL:
            return MainNotification.NotificationStructure(title: "Invalid URL", message: "The provided URL is not valid.")
        default:
            return MainNotification.NotificationStructure(title: "Unknown Error", message: "An unknown error occurred. Please try again.")
        }
    }
}*/

extension URLError {
    
    var response: MainNotification.NotificationStructure {
        switch self.code {
        case .notConnectedToInternet:
            return MainNotification.NotificationStructure(title: "Nessuna Connessione Internet", message: "Controlla la tua connessione internet e riprova.")
        case .timedOut:
            return MainNotification.NotificationStructure(title: "Timeout Richiesta", message: "La richiesta ha impiegato troppo tempo. Riprova più tardi.")
        case .cannotFindHost:
            return MainNotification.NotificationStructure(title: "Host Non Trovato", message: "Impossibile trovare l'host. Controlla l'URL o riprova più tardi.")
        case .cannotConnectToHost:
            return MainNotification.NotificationStructure(title: "Impossibile Connettersi all'Host", message: "Impossibile connettersi all'host. Controlla il server o la tua rete.")
        case .badServerResponse:
            return MainNotification.NotificationStructure(title: "Errore del Server", message: "Il server ha risposto con un errore. Riprova più tardi.")
        case .unsupportedURL:
            return MainNotification.NotificationStructure(title: "URL Non Supportato", message: "L'URL fornito non è valido.")
        default:
            return MainNotification.NotificationStructure(title: "Errore Sconosciuto", message: "Si è verificato un errore sconosciuto. Riprova.")
        }
    }
}
