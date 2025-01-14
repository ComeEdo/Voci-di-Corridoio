//
//  NotificationManager.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 09/01/25.
//

import SwiftUI
import Combine

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published private(set) var AlertViews: [AlertNotificationView] = []
    @Published private(set) var BottomViewsQueue: [BottomNotificationView] = []
    @Published private(set) var BottomShowing: BottomNotificationView?
    private var isWaiting = false
    
    private init() {
    }
    
    func showBottom(_ notification: MainNotification.NotificationStructure, duration: TimeInterval = 6, onDismiss: @escaping () -> Void = {} ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.BottomShowing == nil && self.isWaiting == false {
                self.BottomShowing = BottomNotificationView(notification, duration: duration) {
                    onDismiss()
                    self.nextBottom()
                }
            } else {
                self.BottomViewsQueue.append(BottomNotificationView(notification, duration: duration) {
                    onDismiss()
                    self.nextBottom()
                })
            }
        }
    }
    
    private func nextBottom() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.BottomShowing != nil else { return }
            self.isWaiting = true
            self.BottomShowing = nil
            guard !self.BottomViewsQueue.isEmpty else { return self.isWaiting = false }
            DispatchQueue.main.async {
                self.BottomShowing = self.BottomViewsQueue.removeFirst()
                self.isWaiting = false
            }
        }
    }
    
    func showAlert(_ notification: MainNotification.NotificationStructure, dismissButtonTitle: LocalizedStringResource = "DAJE", onDismiss: @escaping () -> Void = {} ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            withAnimation {
                self.AlertViews.append(AlertNotificationView(notification, dismissButtonTitle: dismissButtonTitle) {
                    onDismiss()
                    self.nextAlert()
                })
            }
        }
    }
    
    private func nextAlert() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, !self.AlertViews.isEmpty else { return }
            self.AlertViews.removeFirst()
        }
    }
}

extension View {
    func addAlerts() -> some View {
        self.overlay {
            Group {
                if let alertView = NotificationManager.shared.AlertViews.first {
                    ZStack {
                        alertView
                        #if DEBUG
                        VStack {
                            Text("\(NotificationManager.shared.AlertViews.count)")
                            Spacer()
                        }
                        #endif
                    }
                }
            }
        }
    }
    func addBottomNotifications() -> some View {
        self.overlay {
            if let bottomView = NotificationManager.shared.BottomShowing {
                ZStack {
                    bottomView
                    #if DEBUG
                    VStack {
                        Text("\(NotificationManager.shared.BottomViewsQueue.count)")
                        Spacer()
                    }
                    #endif
                }
                
            }
        }
    }
}
