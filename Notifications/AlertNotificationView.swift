//
//  AlertNotificationView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 09/01/25.
//

import SwiftUI

struct AlertNotificationView: View {
    @ObservedObject private(set) var alert: AlertNotification
    
    init(_ notification: AlertNotification) {
        self.alert = notification
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
                
                Button() {
                    alert.onDismiss()
                } label: {
                    Text(alert.dismissButtonTitle)
                        .textButtonStyle(true)
                }
            }
            .alertStyle()
        }
    }
}

#Preview {
    AlertNotificationView(AlertNotification(notification: MainNotification.NotificationStructure(title: "Test", message: "Prova Prova Prova Prova Prova Prova Prova Prova"), dismissButtonTitle: "DAJE", type: .error, onDismiss: {
        print("test")
    }))
}
