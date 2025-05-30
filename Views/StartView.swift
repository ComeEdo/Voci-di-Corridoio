//
//  StartView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 08/11/24.
//

import SwiftUI

enum AuthenticationPath: Hashable {
    case CreateAccount
    case SignIn
}

struct StartView: View {
    @StateObject private var classes: ClassesManager = ClassesManager()
    @State private var path: [AuthenticationPath] = []
    
    init() {}
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                ColorGradient()
                VStack {
                    Text("Voci di Corridoio").title(40, .heavy)
                    #if DEBUG
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
                    #endif
                    Spacer()
                }
                VStack {
                    NavigationLink(value:  AuthenticationPath.SignIn) {
                        Text("Accedi").textButtonStyle(true, width: 200, padding: .vertical)
                    }
                    NavigationLink(value: AuthenticationPath.CreateAccount) {
                        Text("Crea account").textButtonStyle(true, width: 200, padding: .vertical)
                    }
                }
            }
            .navigationTitle("")
            .navigationDestination(for: AuthenticationPath.self) { path in
                switch path {
                case .CreateAccount: CreateAccountView().environmentObject(classes)
                case .SignIn: SignInView()
                }
            }
        }
    }
}

#Preview {
    @Previewable @ObservedObject var userManager = UserManager.shared
    @Previewable @ObservedObject var notificationManager = NotificationManager.shared
    @Previewable @ObservedObject var keyboardManager = KeyboardManager.shared
    
    NavigationStack {
        StartView()
    }
    .addAlerts(notificationManager)
    .addBottomNotifications(notificationManager)
    .foregroundStyle(Color.accentColor)
    .accentColor(Color.accent)
    .environmentObject(userManager)
    .environmentObject(keyboardManager)
}
