//
//  AppView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 11/02/25.
//

import SwiftUI

struct AppView: View {
    enum Tabs: Hashable {
        case home
        case profile
        case post
    }
    
    @State private var selection: Tabs = .home
    @State private var isPost = false
    
    var body: some View {
        TabView(selection: $selection) {
            HomeTab().tabItem {
                Label("", systemImage: "house.fill")
            }
            .tag(Tabs.home)
            ProfileTab().tabItem {
                Label("", systemImage: "person.crop.circle.fill")
            }.tag(Tabs.profile)
            
            Text("ww").tabItem {
                Label("Post", systemImage: "plus.circle.fill")
            }
            .tag(Tabs.post)
        }
        .onChange(of: selection) {
            if selection == .post {
                isPost = true
            }
        }
        .fullScreenCover(isPresented: $isPost) {
            CreatePostView() {
                isPost = false
                selection = .home
            }
        }
    }
}

#Preview {
    @Previewable @StateObject var userManager = UserManager.shared
    @Previewable @StateObject var notificationManager = NotificationManager.shared
    
    NavigationStack {
        AppView()
    }
    .addAlerts()
    .addBottomNotifications()
    .foregroundStyle(Color.accentColor)
    .environmentObject(userManager)
}
