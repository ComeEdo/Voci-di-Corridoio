//
//  Voci_di_CorridoioApp.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 06/11/24.
//

import SwiftUI

@main
struct Voci_di_CorridoioApp: App {
    @StateObject private var userManager = UserManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if userManager.isAuthenticated {
                    AppView()
                } else {
                    StartView()
                }
            }
            .addAlerts()
            .addBottomNotifications()
            .foregroundStyle(Color.accentColor)
        }
        .environmentObject(userManager)
    }
}
