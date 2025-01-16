//
//  StartView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 08/11/24.
//

import SwiftUI

struct StartView: View {
    @EnvironmentObject private var notificationManager: NotificationManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                ColorGradient()
                VStack {
                    #if DEBUG
                    Button {
                        for i in 1...10 {
                            notificationManager.showBottom(MainNotification.NotificationStructure(title: "SIUM\(i)", message: "matto"), duration: 1, type: .success)
                        }
                    } label: {
                        Text("Test bottom notifications").textButtonStyle(true)
                    }
                    Button {
                        for i in 1...3 {
                            notificationManager.showAlert(MainNotification.NotificationStructure(title: "SIUM\(i)", message: "matto"), type: MainNotification.NotificationType.info)
                        }
                    } label: {
                        Text("Test alert notifications").textButtonStyle(true)
                    }
                    #endif
                    Text("Benvenuto")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .padding()
                    Spacer()
                }
                VStack {
                    NavigationLink(destination: SignInView()) {
                        Text("Accedi")
                            .fontWeight(.bold)
                            .frame(width: 200)
                            .padding(.vertical)
                            .background(.tint, in: RoundedRectangle(cornerRadius: 20))
                            .foregroundStyle(Color.white)
                    }
                    NavigationLink(destination: CreateAccountView()) {
                        Text("Crea account")
                            .fontWeight(.bold)
                            .frame(width: 200)
                            .padding(.vertical)
                            .background(.tint, in: RoundedRectangle(cornerRadius: 20))
                            .foregroundStyle(Color.white)
                    }
                }
            }
            .navigationTitle("")
        }
        .foregroundStyle(Color.accentColor)
    }
}

#Preview {
    StartView().environmentObject(NotificationManager.shared)
}
