//
//  Notifications.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 10/01/25.
//

import Foundation

protocol Notifiable {
    var notification: MainNotification.NotificationStructure { get }
    var description: String { get }
}

extension Notifiable {
    var description: String {
        "\(notification.title)\n\n\(notification.message)"
    }
}

enum Codes: Error, Notifiable {
    case code400(message: String)
    case code409(message: String)
    case code500(message: String)
    
    var notification: MainNotification.NotificationStructure {
        switch self {
        case .code400(let message):
            return MainNotification.NotificationStructure(title: "Errore", message: "Richiesta non completa: \(message)", type: .error)
        case .code409(let message):
            return MainNotification.NotificationStructure(title: "Errore", message: "È stato trovato un conflitto: \(message)", type: .error)
        case .code500(let message):
            return MainNotification.NotificationStructure(title: "Errore", message: "C'è stato un errore del server: \(message)", type: .error)
        }
    }
}

enum RegistrationNotification: CustomStringConvertible, Notifiable {
    case sucess(username: String)
    case failureUsername(username: String)
    case failureMail(mail: String)
    case failureUsernameMail(username: String, mail: String)
    
    var notification: MainNotification.NotificationStructure {
        switch self {
        case .sucess(let username):
            return MainNotification.NotificationStructure(title: "Successo", message: "\(username) sei stato registrato con successo!", type: .success)
        case .failureUsername(let username):
            return MainNotification.NotificationStructure(title: "Errore", message: "L'username \(username) è già in uso.", type: .error)
        case .failureMail(let mail):
            return MainNotification.NotificationStructure(title: "Errore", message: "L'email \(mail) è già in uso.", type: .error)
        case .failureUsernameMail(let username, let mail):
            return MainNotification.NotificationStructure(title: "Errore", message: "L'username \(username) e la email \(mail) sono già in uso.", type: .error)
        }
    }
}

enum RegistrationError: Error, Notifiable {
    case invalidResponse(message: String)
    case unknownError(message: String)
    case JSONError(message: String)
    case invalidURL(message: String)
    case noClassesFound
    
    var notification: MainNotification.NotificationStructure {
        switch self {
        case .invalidResponse(let message):
            return MainNotification.NotificationStructure(title: "Errore", message: "Risposta del server non valida: \(message)", type: .error)
        case .unknownError(let message):
            return MainNotification.NotificationStructure(title: "Errore", message: "Errore riscontrato:\n\(message)", type: .error)
        case .JSONError(let message):
            return MainNotification.NotificationStructure(title: "Errore", message: "Errore JSON riscontrato:\n\(message)", type: .error)
        case .invalidURL(let message):
            return MainNotification.NotificationStructure(title: "Errore", message: "L'URL \(message) non è valido", type: .error)
        case .noClassesFound:
            return MainNotification.NotificationStructure(title: "Dati ricevuti vuoti", message: "Non sono state trovate classi", type: .info)
        }
    }
}

enum LoginNotification: CustomStringConvertible, Notifiable {
    case sucess(username: String)
    case failureUsername(username: String)
    case failureMail(mail: String)
    case failureUsernameMail(username: String, mail: String)
    
    var notification: MainNotification.NotificationStructure {
        switch self {
        case .sucess(let username):
            return MainNotification.NotificationStructure(title: "Successo", message: "\(username) sei stato registrato con successo!", type: .success)
        case .failureUsername(let username):
            return MainNotification.NotificationStructure(title: "Errore", message: "L'username \(username) è già in uso.", type: .error)
        case .failureMail(let mail):
            return MainNotification.NotificationStructure(title: "Errore", message: "L'email \(mail) è già in uso.", type: .error)
        case .failureUsernameMail(let username, let mail):
            return MainNotification.NotificationStructure(title: "Errore", message: "L'username \(username) e la email \(mail) sono già in uso.", type: .error)
        }
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

extension URLError: Notifiable {
    
    var notification: MainNotification.NotificationStructure {
        switch self.code {
        case .notConnectedToInternet:
            return MainNotification.NotificationStructure(title: "Nessuna Connessione Internet", message: "Controlla la tua connessione internet e riprova.", type: .error)
        case .timedOut:
            return MainNotification.NotificationStructure(title: "Timeout Richiesta", message: "La richiesta ha impiegato troppo tempo. Riprova più tardi.", type: .error)
        case .cannotFindHost:
            return MainNotification.NotificationStructure(title: "Host Non Trovato", message: "Impossibile trovare l'host. Controlla l'URL o riprova più tardi.", type: .error)
        case .cannotConnectToHost:
            return MainNotification.NotificationStructure(title: "Impossibile Connettersi all'Host", message: "Impossibile connettersi all'host. Controlla il server o la tua rete.", type: .error)
        case .badServerResponse:
            return MainNotification.NotificationStructure(title: "Errore del Server", message: "Il server ha risposto con un errore. Riprova più tardi.", type: .error)
        case .unsupportedURL:
            return MainNotification.NotificationStructure(title: "URL Non Supportato", message: "L'URL fornito non è valido.", type: .error)
        case .badURL:
            return MainNotification.NotificationStructure(title: "URL Non Valido", message: "L'URL fornito non è valido.", type: .error)
        default:
            return MainNotification.NotificationStructure(title: "Errore Sconosciuto", message: "Si è verificato un errore sconosciuto. Riprova.", type: .error)
        }
    }
}
