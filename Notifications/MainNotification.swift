//
//  MainNotification.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 09/01/25.
//

import SwiftUI

class MainNotification: ObservableObject, Identifiable {
    struct NotificationStructure: CustomStringConvertible {
        let title: LocalizedStringResource
        let message: LocalizedStringResource
        var description: String {
            "\(title)\n\n\(message)"
        }
    }
    enum NotificationType {
        case success, error, info

        var backgroundColor: Color {
            switch self {
            case .success: return Color.green
            case .error: return Color.red
            case .info: return Color.blue
            }
        }

        var iconName: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }

        var iconColor: Color {
            return .white
        }
    }
    
    let notification: NotificationStructure
    let type: NotificationType
    let id = UUID()
    let onDismiss: () -> Void
    
    init(notification: NotificationStructure, type: NotificationType, onDismiss: @escaping () -> Void) {
        self.notification = notification
        self.type = type
        self.onDismiss = onDismiss
    }
}
