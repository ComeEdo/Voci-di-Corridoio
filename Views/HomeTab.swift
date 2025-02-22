//
//  HomeTab.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 11/02/25.
//

import SwiftUI

struct HomeTab: View {
    @State private var isCopied = false
    var body: some View {
        NavigationStack {
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
                        UserManager.shared.logoutUser()
                    } label: {
                        Text("Log out").textButtonStyle(true)
                    }
                    Button {
                        Task {
                            do {
                                try await UserManager.shared.getNewAuthToken()
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
                                try await UserManager.shared.getNewUserToken()
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
                    Button {
                        Task {
                            do {
                                try await UserManager.shared.getTimetable()
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
                        Text("Timetable").textButtonStyle(true)
                    }
                    Button {
                        UserManager.shared.reInit()
                    } label: {
                        Text("Reinit").textButtonStyle(true)
                    }
                    Button {
                        UIPasteboard.general.string = UserManager.shared.userToken
                        isCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            isCopied = false
                        }
                    } label: {
                        Label(isCopied ? "Copied!" : "Copy to Clipboard", systemImage: "doc.on.doc")
                            .fontWeight(.bold)
                            .padding()
                            .background(isCopied ? Color.green :  Color.accentColor, in: RoundedRectangle(cornerRadius: 20))
                            .foregroundColor(isCopied ? Color.secondary : Color.white)
                            .transition(.blurReplace)
                            .animation(.smooth, value: isCopied)
                    }.disabled(isCopied)
                }
            }.navigationTitle("Home")
        }
    }
}

#Preview {
    HomeTab()
}
