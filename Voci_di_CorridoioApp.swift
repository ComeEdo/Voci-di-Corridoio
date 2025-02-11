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
                    ZStack {
                        ColorGradient()
                        VStack {
                            Text("Authenticated").body()
                            Text(UserManager.shared.currentUser?.username ?? "user").body()
                            Text(UserManager.shared.currentUser?.id.uuidString ?? "id").body()
                            Button {
                                for i in 1...10 {
                                    NotificationManager.shared.showBottom(MainNotification.NotificationStructure(title: "SIUM\(i)", message: "matto", type: .info), duration: 3)
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
                                            Utility.setupAlert(error.notification)
                                        }
                                    } catch let error as Notifiable {
                                        Utility.setupAlert(error.notification)
                                    } catch {
                                        print(error.localizedDescription)
                                        Utility.setupAlert(MainNotification.NotificationStructure(title: "Errore", message: "\(error.localizedDescription)", type: .error))
                                    }
                                }
                            } label: {
                                Text("New auth token").textButtonStyle(true)
                            }
                            Button {
                                Task {
                                    do {
                                        try await userManager.getNewUserToken()
                                    } catch let error as ServerError {
                                        if error == .sslError {
                                            SSLAlert(error.notification)
                                        } else {
                                            Utility.setupAlert(error.notification)
                                        }
                                    } catch let error as Notifiable {
                                        Utility.setupAlert(error.notification)
                                    } catch {
                                        print(error.localizedDescription)
                                        Utility.setupAlert(MainNotification.NotificationStructure(title: "Errore", message: "\(error.localizedDescription)", type: .error))
                                    }
                                }
                            } label: {
                                Text("New user token").textButtonStyle(true)
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
    }
}
