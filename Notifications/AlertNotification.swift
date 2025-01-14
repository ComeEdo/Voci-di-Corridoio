//
//  AlertNotification.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 09/01/25.
//

import SwiftUI

class AlertNotification: MainNotification {
    @Published private(set) var dismissButtonTitle: LocalizedStringResource
    
    init(notification: NotificationStructure, dismissButtonTitle: LocalizedStringResource, type: NotificationType, onDismiss: @escaping () -> Void) {
        self.dismissButtonTitle = dismissButtonTitle
        super.init(notification: notification, type: type, onDismiss: onDismiss)
    }
}
