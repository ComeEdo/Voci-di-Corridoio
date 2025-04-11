//
//  BottomNotificationView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 09/01/25.
//

import SwiftUI

struct BottomNotificationView: View {
    @ObservedObject private var bottom: BottomNotification
    @EnvironmentObject private var keyboardManager: KeyboardManager
    
    private var defaultOffset: CGFloat = 300
    
    @State private var offsetY: CGFloat = 300
    
    private var animationType: Animation = Animation.bouncy(extraBounce: 0.1)
    
    init(_ notification: BottomNotification) {
        self.bottom = notification
    }
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                HStack {
                    VStack() {
                        bottom.notification.type.icon.font(.system(size: 40, weight: .heavy))
                    }
                    VStack(alignment: .leading) {
                        Text(bottom.notification.title)
                            .title()
                        Text(bottom.notification.message)
                            .body()
                    }
                    
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(15)
                .notificationStyle(bottom.notification.type.color)
                .frame(maxHeight: 101, alignment: .bottom)
                .padding(15)
                .offset(y: keyboardManager.keyboardHeight != 0 ? offsetY - keyboardManager.keyboardHeight : offsetY)
                .gesture(dragGesture)
            }
        }
        .ignoresSafeArea(.all, edges: .all)
        .onAppear {
            showNotification()
        }
    }
    
    private func showNotification() {
        withAnimation(animationType) {
            self.offsetY = .zero
        }
        HapticFeedback.trigger(bottom.notification.type.hapticFeedback)
        startTimer()
    }
    
    
    func startTimer() {
        Timer.scheduledTimer(withTimeInterval: bottom.duration, repeats: false) { _ in
            if NotificationManager.shared.BottomShowing == self.bottom {
                self.dismissNotification()
            }
        }
    }
    
    private func dismissNotification() {
        withAnimation(animationType) {
            offsetY = defaultOffset
        }
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
            bottom.onDismiss()
        }
    }
    
    // MARK: - Gesture Handling
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offsetY = value.translation.height.progessionAsitotic(50, 100)
            }
            .onEnded { value in
                if value.translation.height >= 20 {
                    dismissNotification()
                } else {
                    withAnimation(animationType) {
                        offsetY = .zero
                    }
                }
            }
    }
}

#Preview {
    BottomNotificationView(BottomNotification(notification: MainNotification.NotificationStructure(title: "aaaaaaaaaaaaaaaaaaaaaa", message: "bbbbbbbbbbbbbbbbbbbbbbbbb", type: .info), duration: 6, onDismiss: { print("workaa") } ))
}
