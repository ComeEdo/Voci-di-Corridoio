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
        case success,
             error,
             warning,
             info
        @ViewBuilder
        var icon: some View {
            switch self {
            case .success:
                Image(systemName: "checkmark.circle").foregroundStyle(.green)
            case .error:
                Image(systemName: "xmark.circle").symbolRenderingMode(.multicolor)
            case .info:
                Image(systemName: "info.circle").symbolRenderingMode(.multicolor)
            case .warning:
                Image(systemName: "exclamationmark.triangle").symbolRenderingMode(.multicolor)
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
