//
//  HomeTab.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 11/02/25.
//

import SwiftUI

struct HomeTab: View {
    @EnvironmentObject private var userManager: UserManager
    
    @State private var isCopied = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                ColorGradient()
                ScrollView {
                    Text("Authenticated").body()
                    Text("Server \(userManager.URN)").body()
                    Text("imageUUID \(userManager.mainUser?.user.profileImageId)").body()
                    Text("image \(userManager.mainUser?.profileImage)").body()
                    Picker("Server Domain", selection: $userManager.domain) {
                        ForEach(UserManager.ServerDomain.allCases, id: \.self) { domain in
                            Text(domain.rawValue).tag(domain)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    Text(userManager.mainUser?.user.username ?? "user").body()
                    Text(userManager.mainUser?.user.id.uuidString ?? "id").body()
                    Button {
                        for i in 1...10 {
                            Utility.setupBottom(MainNotification.NotificationStructure(title: "SIUM\(i)", message: "matto", type: .info))
                        }
                    } label: {
                        Text("Test bottom notifications").textButtonStyle(true)
                    }
                    Button {
                        for i in 1...3 {
                            Utility.setupAlert(MainNotification.NotificationStructure(title: "SIUM\(i)", message: "matto", type: .warning))
                        }
                    } label: {
                        Text("Test alert notifications").textButtonStyle(true)
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
                            } catch {
                                if let err = mapError(error) {
                                    Utility.setupAlert(err.notification)
                                }
                            }
                        }
                    } label: {
                        Text("Nuovo token di autenticazione.").textButtonStyle(true)
                    }
                    Button {
                        Task {
                            do {
                                try await userManager.getNewUserToken()
                            } catch {
                                if let err = mapError(error) {
                                    Utility.setupAlert(err.notification)
                                }
                            }
                        }
                    } label: {
                        Text("Nuovo token utente.").textButtonStyle(true)
                    }
                    Button {
                        Task {
                            do {
                                try await UserManager.shared.getTimetable()
                            } catch {
                                if let err = mapError(error) {
                                    Utility.setupAlert(err.notification)
                                }
                            }
                        }
                    } label: {
                        Text("Timetable").textButtonStyle(true)
                    }
                    Button {
                        userManager.reInit()
                    } label: {
                        Text("Reinit").textButtonStyle(true)
                    }
                    Button {
                        UIPasteboard.general.string = userManager.URN
                        isCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            isCopied = false
                        }
                    } label: {
                        Label(isCopied ? "Copied!" : "Copy to Clipboard the URN", systemImage: "doc.on.doc")
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
