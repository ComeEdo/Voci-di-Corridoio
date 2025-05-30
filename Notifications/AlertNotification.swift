//
//  AlertNotification.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 09/01/25.
//

import SwiftUI

class AlertNotification: MainNotification {
    let dismissButtonTitle: LocalizedStringResource
    
    init(notification: NotificationStructure, dismissButtonTitle: LocalizedStringResource, onDismiss: (() -> Void)?) {
        self.dismissButtonTitle = dismissButtonTitle
        super.init(notification: notification, onDismiss: onDismiss)
    }
}
