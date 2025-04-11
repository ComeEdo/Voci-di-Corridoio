//
//  AppView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 11/02/25.
//

import SwiftUI
import Combine

class TabsManager: ObservableObject {
    @AppStorage(AppView.Tabs.🔑.rawValue) var selection: AppView.Tabs = .home
    
    let tabTap = PassthroughSubject<Void, Never>()
    
    init() {}
    
    func notifyTap() {
        tabTap.send()
    }
}

struct AppView: View {
    enum Tabs: String, Hashable, Codable, DefaultPersistenceProtocol {
        case home
        case profile
        case post
        case testPhoto
        
        static let 🔑: DefaultPersistence.Saves = .tab
    }
    
    @EnvironmentObject private var userManager: UserManager
    @EnvironmentObject private var notificationManager: NotificationManager
    
    @StateObject private var tabsManager: TabsManager = TabsManager()
    
    @State private var isPost = false
    
    init() {}
    
    var body: some View {
        VStack {
            TabView(selection: tabSelection()) {
                Tab("", systemImage: "house.fill", value: Tabs.home) {
                    HomeTab()
                }
                Tab("", systemImage: "person.crop.circle.fill", value: Tabs.profile) {
                    ProfileTab()
                }
                if let user = userManager.mainUser, user.role == .student {
                    Tab("Post", systemImage: "plus.circle.fill", value: Tabs.post) {
                    }
                }
                Tab("", systemImage: "photo.artframe.circle.fill", value: Tabs.testPhoto) {
                    if let user = userManager.mainUser {
                        ProfileView(for: AnyUser(for: user))
                    }
                }
            }
            .onChange(of: tabsManager.selection) { oldValue, newValue in
                if newValue == .post {
                    tabsManager.selection = oldValue
                    isPost = true
                }
            }
            .fullScreenCover(isPresented: $isPost) {
                CreatePostView()
                    .addAlerts(notificationManager)
                    .addBottomNotifications(notificationManager)
            }
        }.environmentObject(tabsManager)
    }
    private func tabSelection() -> Binding<Tabs> {
        Binding {
            tabsManager.selection
        } set: { tappedTab in
            if tabsManager.selection == tappedTab {
                tabsManager.notifyTap()
            }
            self.tabsManager.selection = tappedTab
        }
    }
}

#Preview {
    @Previewable @StateObject var userManager = UserManager.shared
    @Previewable @StateObject var notificationManager = NotificationManager.shared
    @Previewable @StateObject var keyboardManager = KeyboardManager.shared
    
    
    AppView()
        .environmentObject(notificationManager)
        .addAlerts(notificationManager)
        .addBottomNotifications(notificationManager)
        .foregroundStyle(Color.accentColor)
        .environmentObject(userManager)
        .environmentObject(keyboardManager)
}
