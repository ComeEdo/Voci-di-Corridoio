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
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var userManager = UserManager.shared
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if userManager.isAuthenticated {
                    ZStack {
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
                            Button {
                                Task {
                                    do {
                                        try await userManager.getNewAuthToken()
                                    } catch let error as ServerError {
                                        if error == .sslError {
                                            SSLAlert(error.notification)
                                        } else {
                                            notificationManager.showAlert(error.notification)
                                        }
                                    } catch let error as Notifiable {
                                        notificationManager.showAlert(error.notification)
                                    } catch {
                                        print(error.localizedDescription)
                                        notificationManager.showAlert(MainNotification.NotificationStructure(title: "Errore", message: "\(error.localizedDescription)", type: .error))
                                    }
                                }
                            } label: {
                                Text("New token").textButtonStyle(true)
                            }
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
