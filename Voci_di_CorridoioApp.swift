//
//  Voci_di_CorridoioApp.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 06/11/24.
//

import SwiftUI

@main
struct Voci_di_CorridoioApp: App {
    let persistenceController = PersistenceController.shared
    @ObservedObject private var notificationManager = NotificationManager.shared
    @ObservedObject private var userManager = UserManager.shared
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if userManager.isAuthenticated {
                    ColorGradient()
                    VStack {
                        Text("Authenticated")
                        Button {
                            for i in 1...10 {
                                notificationManager.showBottom(MainNotification.NotificationStructure(title: "SIUM\(i)", message: "matto", type: .info), duration: 3)
                            }
                        } label: {
                            Text("Test bottom notifications").textButtonStyle(true)
                        }
                        Button {
                            userManager.logoutUser()
                        } label: {
                            Text("Log out").textButtonStyle(true)
                        }
                    }
                } else {
                    StartView()
                }
            }
            .addAlerts()
            .addBottomNotifications()
            .foregroundStyle(Color.accentColor)
        }
        .environmentObject(userManager)
        .environmentObject(notificationManager)
    }
}
