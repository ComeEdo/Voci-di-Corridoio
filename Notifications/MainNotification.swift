//
//  MainNotification.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 09/01/25.
//

import SwiftUI

class MainNotification: ObservableObject {
    struct NotificationStructure: CustomStringConvertible {
        let title: LocalizedStringResource
        let message: LocalizedStringResource
        var description: String {
            "\(title)\n\n\(message)"
        }
    }
    
    @Published private(set) var notification: NotificationStructure
    let onDismiss: () -> Void
    
    init(notification: NotificationStructure, onDismiss: @escaping () -> Void) {
        self.notification = notification
        self.onDismiss = onDismiss
    }
}
