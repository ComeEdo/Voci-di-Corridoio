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
    
    let notification: NotificationStructure
    let id = UUID()
    let onDismiss: () -> Void
    
    init(notification: NotificationStructure, onDismiss: @escaping () -> Void) {
        self.notification = notification
        self.onDismiss = onDismiss
    }
}
