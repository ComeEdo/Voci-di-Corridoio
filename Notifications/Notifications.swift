//
//  Notifications.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 10/01/25.
//

import Foundation
import SwiftUI
import UIKit

protocol Notifiable {
    var notification: MainNotification.NotificationStructure { get }
    var description: String { get }
}

extension Notifiable {
    var description: String {
        "\(notification.title)\n\n\(notification.message)"
    }
}

enum ServerError: Error, Notifiable {
    case serviceUnavailable
    case unexpectedResponse
    case sslError
    
    var notification: MainNotification.NotificationStructure {
        switch self {
        case .serviceUnavailable:
            return MainNotification.NotificationStructure(title: "Errore", message: "Il server è offline.\nRiprova più tardi.", type: .error)
        case .unexpectedResponse:
            return MainNotification.NotificationStructure(title: "Errore", message: "Risposta inaspettata. Riprova più tardi.", type: .error)
        case .sslError:
            return MainNotification.NotificationStructure(title: "Certificato Del Server Non Valido", message: "Il nostro certificato è self-signed, iOS non apprezza.\nPer usare Voci Di Corridoio devi installarlo.\nScaricalo a https://\(UserManager.shared.server)\(UserManager.APIEndpoints.SSLCertificate)", type: .info)
        }
    }
}

enum Codes: Error, Notifiable {
    case code400(message: String)
    case code404(message: String)
    case code409(message: String)
    case code500(message: String)
    
    var notification: MainNotification.NotificationStructure {
        switch self {
        case .code400(let message):
            return MainNotification.NotificationStructure(title: "Errore", message: "Richiesta non completa: \(message)", type: .error)
        case .code409(let message):
            return MainNotification.NotificationStructure(title: "Errore", message: "È stato trovato un conflitto: \(message)", type: .error)
        case .code404(let message):
            return MainNotification.NotificationStructure(title: "Errore", message: "Risorsa non trovata: \(message)", type: .error)
        case .code500(let message):
            return MainNotification.NotificationStructure(title: "Errore", message: "C'è stato un errore del server: \(message)", type: .error)
        }
    }
}

enum Errors: Error, Notifiable {
    case invalidResponse(message: String)
    case unknownError(message: String)
    case JSONError(message: String)
    case invalidURL(message: String)
    
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
        }
    }
}

enum RegistrationNotification: Notifiable {
    case success(username: String)
    case failureUsername(username: String)
    case failureMail(mail: String)
    case failureUsernameMail(username: String, mail: String)
    
    var notification: MainNotification.NotificationStructure {
        switch self {
        case .success(let username):
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

enum ClassesError: Error, Notifiable {
    case noClassesFound
    
    var notification: MainNotification.NotificationStructure {
        switch self {
        case .noClassesFound:
            return MainNotification.NotificationStructure(title: "Dati ricevuti vuoti", message: "Non sono state trovate classi", type: .info)
        }
    }
}

enum LoginNotification: Notifiable {
    case success(users: [LoginResponse.RoleGroup])
    case gotUser(username: String)
    
    var notification: MainNotification.NotificationStructure {
        switch self {
        case .success:
            return MainNotification.NotificationStructure(title: "Successo", message: "Sei stato loggato con successo!", type: .success)
        case .gotUser(let username):
            return MainNotification.NotificationStructure(title: "Success", message: "\(username) sei stato loggato!", type: .success)
        }
    }
}

enum LoginError: Error, Notifiable {
    case emailNotVerified
    case invalidCredentials
    case userNotFound
    
    var notification: MainNotification.NotificationStructure {
        switch self {
        case .emailNotVerified:
            return MainNotification.NotificationStructure(title: "Errore", message: "L'email non è stata verificata, controlla la tua casella postale.", type: .error)
        case .invalidCredentials:
            return MainNotification.NotificationStructure(title: "Errore", message: "Le credenziali non sono corrette.", type: .error)
        case .userNotFound:
            return MainNotification.NotificationStructure(title: "Errore", message: "Non è stato trovato trovato nessun utente alle seguenti credenziali, contattaci.", type: .warning)
        }
    }
}

enum AuthError: Error, Notifiable {
    case unauthorized(message: String)
    case forbidden(message: String)
    
    var notification: MainNotification.NotificationStructure {
        switch self {
        case .unauthorized(let message):
            return MainNotification.NotificationStructure(title: "Errore", message: "Non autorizzato:\n\(message)", type: .error)
        case .forbidden(let message):
            return MainNotification.NotificationStructure(title: "Errore", message: "Accesso negato:\n\(message)", type: .error)
        }
    }
}

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
