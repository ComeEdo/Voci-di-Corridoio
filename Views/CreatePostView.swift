//
//  CreatePostView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 18/02/25.
//

import SwiftUI

struct CreatePostView: View {
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedUser: User? = nil
    
    @Namespace private var namespace
    @State private var navigationPath: [NavigationSelectionNode] = []
    
    @StateObject private var timetableManager = TimetableManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    
    let onDismiss: () -> Void   //probabilmente non serve
    @Environment(\.dismiss) private var dismiss
    
    init(_ onDismiss: @escaping () -> Void = {}) {
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                HStack(alignment: .bottom) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.system(size: 50, weight: .light))
                    }.offset(y: -3)
                    Spacer()
                    Button {
                        print("Post")
                    } label: {
                        Text("Post").textButtonStyle(true)
                    }
                    .padding(.trailing, 10)
                }
                .padding(.bottom, 3)
                ScrollView(showsIndicators: false) {
                    bb(namespace: namespace)
                        .navigationDestination(in: namespace, selectedUser: $selectedUser, navigationPath: $navigationPath)
                        .environmentObject(timetableManager)
                    TextField("", text: $title, prompt: Text("Titolo").textColor(), axis: .vertical)
                        .foregroundStyle(Color.white)
                        .font(.system(size: 30, weight: .bold))
                        .padding(.horizontal)
                    TextField("", text: $content, prompt: Text("Corpo").textColor(), axis: .vertical)
                        .foregroundStyle(Color.white)
                        .font(.system(size: 20, weight: .bold))
                        .padding()
                }.scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Recensione \(timetableManager.timetable?.classe.name ?? "")")
        }
        .onAppear() {
            timetableManager.fetchUsers() // forse da spostare ma funziona
        }
    }
}

#Preview {
    @Previewable @StateObject var userManager = UserManager.shared
    @Previewable @StateObject var notificationManager = NotificationManager.shared
    @Previewable @StateObject var keyboardManager = KeyboardManager.shared
    
    NavigationStack {
        CreatePostView()
    }
    .addAlerts(notificationManager)
    .addBottomNotifications(notificationManager)
    .foregroundStyle(Color.accentColor)
    .environmentObject(userManager)
    .environmentObject(keyboardManager)
}
