//
//  MainNotification.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 09/01/25.
//

import SwiftUI

class MainNotification: ObservableObject, Identifiable, Equatable {
    struct NotificationStructure: CustomStringConvertible, Equatable {
        static func == (lhs: MainNotification.NotificationStructure, rhs: MainNotification.NotificationStructure) -> Bool {
            return lhs.title == rhs.title &&
                lhs.message == rhs.message &&
                lhs.type == rhs.type
        }
        
        let title: LocalizedStringResource
        let message: LocalizedStringResource
        let type: NotificationType
        
        var description: String {
            "\(title)\n\n\(message)\n\n\(type)"
        }
    }
    
    enum NotificationType {
        case success,
             error,
             warning,
             info
        
        @ViewBuilder
        var icon: some View {
            switch self {
            case .success:
                Image(systemName: "checkmark.circle").foregroundStyle(Color.green)
            case .error:
                Image(systemName: "xmark.circle").symbolRenderingMode(.multicolor)
            case .warning:
                Image(systemName: "exclamationmark.triangle").symbolRenderingMode(.multicolor)
            case .info:
                Image(systemName: "info.circle").symbolRenderingMode(.multicolor)
            }
        }
        
        var hapticFeedback: HapticFeedback.HapticType {
            switch self {
            case .success: return .notification(type: .success)
            case .error: return .notification(type: .error)
            case .warning: return .notification(type: .warning)
            case .info: return .impact(style: .heavy)
            }
        }
        var color: Color {
            switch self {
            case .success: return Color.green
            case .error: return Color.red
            case .warning: return Color.yellow
            case .info: return Color.blue
            }
        }
    }
    
    static func == (lhs: MainNotification, rhs: MainNotification) -> Bool {
        return lhs.id == rhs.id && lhs.notification == rhs.notification
    }
    
    let notification: NotificationStructure
    let id = UUID()
    let onDismiss: (() -> Void)?
    
    init(notification: NotificationStructure, onDismiss: (() -> Void)?) {
        self.notification = notification
        self.onDismiss = onDismiss
    }
}
