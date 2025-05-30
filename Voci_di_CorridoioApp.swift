//
//  Voci_di_CorridoioApp.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 06/11/24.
//

import SwiftUI

@main
struct Voci_di_CorridoioApp: App {
    @ObservedObject private var userManager = UserManager.shared
    @ObservedObject private var notificationManager = NotificationManager.shared
    @ObservedObject private var keyboardManager = KeyboardManager.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if userManager.isAuthenticated {
                    AppView().environmentObject(notificationManager)
                } else {
                    StartView()
                }
            }
            .addAlerts(notificationManager)
            .addBottomNotifications(notificationManager)
            .foregroundStyle(Color.accentColor)
            .tint(Color.accentColor)
            .accentColor(Color.accent)
            .onOpenURL { URL in
                //vocidicorridoio://settings/ssl
                openSettings(with: URL)
            }
        }
        .environmentObject(userManager)
        .environmentObject(keyboardManager)
    }
    func openSettings(with url: URL) {
        if url.host == "settings" && url.path == "/ssl" {
            if let settingsURL = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(settingsURL) {
                UIApplication.shared.open(settingsURL)
            }
        }
    }
}
