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
    
    private(set) var AlertViewsQueue: [AlertNotification] = []
    private(set) var AlertShowing: AlertNotification?
    private var isAlertWaiting = false
    
    private(set) var BottomViewsQueue: [BottomNotification] = []
    private(set) var BottomShowing: BottomNotification?
    private var isBottomWaiting = false
    
    private init() {}
    
    func showBottom(_ notification: MainNotification.NotificationStructure, duration: TimeInterval = 6, type: MainNotification.NotificationType, onDismiss: @escaping () -> Void = {} ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.BottomShowing == nil && self.isBottomWaiting == false {
                self.BottomShowing = BottomNotification(notification: notification, duration: duration, type: type) {
                    onDismiss()
                    self.nextBottom()
                }
                objectWillChange.send()
            } else {
                self.BottomViewsQueue.append(BottomNotification(notification: notification, duration: duration, type: type) {
                    onDismiss()
                    self.nextBottom()
                })
            }
        }
    }
    
    private func nextBottom() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.BottomShowing != nil else { return }
            guard !self.BottomViewsQueue.isEmpty else {
                self.BottomShowing = nil
                return objectWillChange.send()
            }
            self.isBottomWaiting = true
            self.BottomShowing = nil
            objectWillChange.send()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.BottomShowing = self.BottomViewsQueue.removeFirst()
                self.objectWillChange.send()
                self.isBottomWaiting = false
            }
        }
    }
    
    func showAlert(_ notification: MainNotification.NotificationStructure, dismissButtonTitle: LocalizedStringResource = "DAJE", type: MainNotification.NotificationType, onDismiss: @escaping () -> Void = {} ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.AlertShowing == nil && self.isAlertWaiting == false {
                self.AlertShowing = AlertNotification(notification: notification, dismissButtonTitle: dismissButtonTitle, type: type) {
                    onDismiss()
                    self.nextAlert()
                }
                withAnimation {
                    self.objectWillChange.send()
                }
            } else {
                self.AlertViewsQueue.append(AlertNotification(notification: notification, dismissButtonTitle: dismissButtonTitle, type: type) {
                    onDismiss()
                    self.nextAlert()
                })
            }
        }
    }
    
    private func nextAlert() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.AlertShowing != nil else { return }
            guard !self.AlertViewsQueue.isEmpty else {
                self.AlertShowing = nil
                return self.objectWillChange.send()
            }
            self.isAlertWaiting = true
            self.AlertShowing = nil
//            withAnimation {
                self.objectWillChange.send()    //needs fine tuning
//            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.AlertShowing = self.AlertViewsQueue.removeFirst()
                withAnimation {
                    self.objectWillChange.send()
                }
                self.isAlertWaiting = false
            }
        }
    }
}

extension View {
    func addAlerts() -> some View {
        self.overlay {
            if let alertView = NotificationManager.shared.AlertShowing {
                ZStack {
                    AlertNotificationView(alertView)
                    #if DEBUG
                    HStack {
                        Spacer()
                        Text("\(NotificationManager.shared.AlertViewsQueue.count)")
                    }.padding()
                    #endif
                }
            }
        }
    }
    func addBottomNotifications() -> some View {
        self.overlay {
            if let bottomView = NotificationManager.shared.BottomShowing {
                ZStack {
                    BottomNotificationView(bottomView)
                    #if DEBUG
                    HStack {
                        Text("\(NotificationManager.shared.BottomViewsQueue.count)")
                        Spacer()
                    }.padding()
                    #endif
                }
                
            }
        }
    }
}
