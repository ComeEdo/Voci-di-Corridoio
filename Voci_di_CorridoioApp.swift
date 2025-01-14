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
                } else {
                    StartView()
                }
            }
            .addAlerts()
            .addBottomNotifications()
        }
        .environmentObject(userManager)
        .environmentObject(notificationManager)
    }
}
