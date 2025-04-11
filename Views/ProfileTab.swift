//
//  ProfileTab.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 11/02/25.
//

import SwiftUI

struct ProfileTab: View {
    @EnvironmentObject private var userManager: UserManager
    @EnvironmentObject private var tabsManager: TabsManager
    @EnvironmentObject private var notificationManager: NotificationManager
    
    @State private var editMode: EditMode = .active
    
    @State private var items: [String] = (1...Int.random(in: 100...999)).map { "Item \($0)" }
    
    private var animation: Animation? = Animation.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.25)
    
    init() {}
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollView in
                List() {
                    Toggle(isOn: $notificationManager.isNotificationActive.isBottomActive ) {
                        Label("Bottom notifications", systemImage: "figure.open.water.swim")
                    }
                    Toggle(isOn: $notificationManager.isNotificationActive.isAlertActive) {
                        Label("Alerts", systemImage: "figure.open.water.swim")
                    }
                    Section {
                        Text("Apple")
                        Text("Banana")
                        Text("Orange")
                    } header: {
                        Text("Fruits")
                    }
                    Section {
                        Picker("Server Domain", selection: $userManager.domain) {
                            ForEach(UserManager.ServerDomain.allCases, id: \.self) { domain in
                                Text(domain.rawValue).tag(domain)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    } header: {
                        Label("Server", systemImage: "server.rack")
                    } footer: {
                        Label("Server Domain", systemImage: "server.rack")
                    }

                    ForEach(Array(items.enumerated()), id: \.element) { index, item in
                        HStack {
                            Text(item)
                            Spacer()
                            Image(systemName: "arrow.2.circlepath")
                                .symbolEffect(.rotate, options:.repeat(SymbolEffectOptions.RepeatBehavior.periodic(delay: 0.1)).speed(2))
                                .font(.system(size: 100, weight: .black))
                            Spacer()
                            Image(systemName: "line.3.horizontal")
                                .symbolEffect(.breathe, options:.repeat(SymbolEffectOptions.RepeatBehavior.continuous).speed(1))
                                .font(.system(size: 60, weight: .black))
                        }
                    }
                    .onDelete { indexSet in
                        items.remove(atOffsets: indexSet)
                    }
                    .onMove { indices, newOffset in
                        items.move(fromOffsets: indices, toOffset: newOffset)
                    }
                }
                .onReceive(tabsManager.tabTap) {
                    if tabsManager.selection == .profile {
                        scrollToTop(scrollView: scrollView)
                    }
                }
            }
            .navigationTitle("Profilo")
        }
    }
    private func scrollToTop(scrollView: ScrollViewProxy) {
        withAnimation(animation) {
            let item = items[Int.random(in: 0..<items.count)]
            scrollView.scrollTo(item, anchor: .center)
            print("scrolling to \(item)")
        }
    }
}
