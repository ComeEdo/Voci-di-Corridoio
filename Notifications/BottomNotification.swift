//
//  BottomNotification.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 09/01/25.
//

import SwiftUI

class BottomNotification: MainNotification {
    let duration: TimeInterval
    
    init(notification: NotificationStructure, duration: TimeInterval, type: NotificationType, onDismiss: @escaping () -> Void) {
        self.duration = duration
        super.init(notification: notification, type: type, onDismiss: onDismiss)
    }
}
