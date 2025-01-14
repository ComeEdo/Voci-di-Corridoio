//
//  AlertNotificationView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 09/01/25.
//

import SwiftUI

struct AlertNotificationView: View {
    @ObservedObject private(set) var alert: AlertNotification
    
    init(_ notification: MainNotification.NotificationStructure, dismissButtonTitle: LocalizedStringResource, onDismiss: @escaping () -> Void) {
        self.alert = AlertNotification(notification: notification, dismissButtonTitle: dismissButtonTitle, onDismiss: onDismiss)
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    alert.onDismiss()
                }
            VStack(spacing: 20) {
                Text(alert.notification.title)
                    .title()
                
                Text(alert.notification.message)
                    .body()
                    .multilineTextAlignment(.center)
                
                Button(action: alert.onDismiss) {
                    Text(alert.dismissButtonTitle)
                        .textButtonStyle(true)
                }
            }
            .alertStyle()
        }
        .transition(.blurReplace)
    }
}

#Preview {
    AlertNotificationView(MainNotification.NotificationStructure(title: "Test", message: "Prova Prova Prova Prova Prova Prova Prova Prova"), dismissButtonTitle: "DAJE", onDismiss: {
        print("test")
    })
}
