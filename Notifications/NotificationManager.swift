//
//  NotificationManager.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 09/01/25.
//

import SwiftUI

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    struct IsNotificationActive: Codable, DefaultPersistenceProtocol {
        static var 🔑: DefaultPersistence.Saves = .isNotificationActive
        
        var isAlertActive: Bool
        var isBottomActive: Bool
        
        init() {
            self.isAlertActive = true
            self.isBottomActive = true
        }
        
        mutating func reset() {
            self.isAlertActive = true
            self.isBottomActive = true
            
        }
    }
    
    @Published var isNotificationActive: IsNotificationActive {
        didSet {
            DefaultPersistence.save(for: isNotificationActive)
        }
    }
    
    @Published private(set) var AlertViewsQueue: [AlertNotification] = []
    @Published private(set) var AlertShowing: AlertNotification?
    private var isAlertWaiting = false
    
    @Published private(set) var BottomViewsQueue: [BottomNotification] = []
    @Published private(set) var BottomShowing: BottomNotification?
    private var isBottomWaiting = false
    
    private init() {
        isNotificationActive = DefaultPersistence.retrieve() ?? IsNotificationActive()
    }
    
    func reset() {
        while isAlertWaiting {}
        AlertViewsQueue = []
        
        while isBottomWaiting {}
        BottomViewsQueue = []
        
        isNotificationActive.reset()
        DefaultPersistence.delete(type: IsNotificationActive.self)
    }
    
    func showBottom(_ notification: MainNotification.NotificationStructure, duration: TimeInterval = 6, onDismiss: (() -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.BottomShowing == nil && self.isBottomWaiting == false {
                self.BottomShowing = BottomNotification(notification: notification, duration: duration) {
                    onDismiss?()
                    self.nextBottom()
                }
            } else {
                self.BottomViewsQueue.append(BottomNotification(notification: notification, duration: duration) {
                    onDismiss?()
                    self.nextBottom()
                })
            }
        }
    }
    
    private func nextBottom() {
        guard self.BottomShowing != nil else { return }
        guard !BottomViewsQueue.isEmpty else {
            BottomShowing = nil
            return
        }
        self.isBottomWaiting = true
        self.BottomShowing = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.BottomShowing = self.BottomViewsQueue.removeFirst()
            self.isBottomWaiting = false
        }
    }
    
    func showAlert(_ notification: MainNotification.NotificationStructure, dismissButtonTitle: LocalizedStringResource = "DAJE", onDismiss: (() -> Void)? = nil ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.AlertShowing == nil && self.isAlertWaiting == false {
                self.AlertShowing = AlertNotification(notification: notification, dismissButtonTitle: dismissButtonTitle) {
                    onDismiss?()
                    self.nextAlert()
                }
            } else {
                self.AlertViewsQueue.append(AlertNotification(notification: notification, dismissButtonTitle: dismissButtonTitle) {
                    onDismiss?()
                    self.nextAlert()
                })
            }
        }
    }
    
    private func nextAlert() {
        guard self.AlertShowing != nil else { return }
        guard !self.AlertViewsQueue.isEmpty else {
            self.AlertShowing = nil
            return
        }
        self.isAlertWaiting = true
        self.AlertShowing = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.AlertShowing = self.AlertViewsQueue.removeFirst()
            self.isAlertWaiting = false
        }
    }
}

extension View {
    func addAlerts(_ notificationManager: NotificationManager) -> some View {
        self.overlay {
            if notificationManager.isNotificationActive.isAlertActive, let alertView = notificationManager.AlertShowing {
                ZStack {
                    AlertNotificationView(alertView)
                    #if DEBUG
                    HStack {
                        Spacer()
                        Text("\(notificationManager.AlertViewsQueue.count)")
                    }.padding()
                    #endif
                }
            }
        }
    }
    func addBottomNotifications(_ notificationManager: NotificationManager) -> some View {
        return self.overlay {
            if notificationManager.isNotificationActive.isBottomActive, let bottomView = notificationManager.BottomShowing {
                ZStack {
                    BottomNotificationView(bottomView)
                    #if DEBUG
                    HStack {
                        Text("\(notificationManager.BottomViewsQueue.count)")
                        Spacer()
                    }.padding()
                    #endif
                }
            }
        }
    }
}
