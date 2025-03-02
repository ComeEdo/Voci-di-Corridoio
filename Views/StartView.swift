//
//  StartView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 08/11/24.
//

import SwiftUI

struct StartView: View {
    @StateObject private var classes: ClassesManager = ClassesManager()
    
    init() {}
    
    var body: some View {
        ZStack {
            ColorGradient()
            VStack {
                Text("Voci di Corridoio").title(40, .heavy)
                #if DEBUG
                Button {
                    for i in 1...10 {
                        NotificationManager.shared.showBottom(MainNotification.NotificationStructure(title: "SIUM\(i)", message: "matto", type: .info), duration: 3)
                    }
                } label: {
                    Text("Test bottom notifications").textButtonStyle(true)
                }
                Button {
                    for i in 1...3 {
                        NotificationManager.shared.showAlert(MainNotification.NotificationStructure(title: "SIUM\(i)", message: "matto", type: .warning))
                    }
                } label: {
                    Text("Test alert notifications").textButtonStyle(true)
                }
                #endif
                Spacer()
            }
            VStack {
                NavigationLink(destination: SignInView()) {
                    Text("Accedi").textButtonStyle(true, width: 200, padding: .vertical)
                }
                NavigationLink(destination: CreateAccountView().environmentObject(classes)) {
                    Text("Crea account").textButtonStyle(true, width: 200, padding: .vertical)
                }
            }
        }
        .navigationTitle("")
    }
}

#Preview {
    @Previewable @StateObject var userManager = UserManager.shared
    @Previewable @StateObject var notificationManager = NotificationManager.shared
    
    NavigationStack {
        StartView()
    }
    .addAlerts()
    .addBottomNotifications()
    .foregroundStyle(Color.accentColor)
    .environmentObject(userManager)
}
