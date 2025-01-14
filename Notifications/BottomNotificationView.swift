//
//  BottomNotificationView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 09/01/25.
//

import SwiftUI

struct BottomNotificationView: View {
    @ObservedObject private var bottom: BottomNotification
    
    private var defaultOffset: CGFloat = 300
    
    @State private var offsetY: CGFloat = 300
    @State private var dismissalTimer: Timer?
    
    private var type: Animation = Animation.bouncy(extraBounce: 0.1)
    
    init(_ notification: MainNotification.NotificationStructure, duration: TimeInterval, onDismiss: @escaping () -> Void) {
        self.bottom = BottomNotification(notification: notification, duration: duration, onDismiss: onDismiss)
        self.offsetY = defaultOffset
    }
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                HStack {
                    VStack() {
                        Image(systemName: "exclamationmark.triangle")
                            .symbolRenderingMode(.multicolor)
                            .fontWeight(.heavy)
                            .font(.system(size: 40))
                    }
                    VStack(alignment: .leading) {
                        Text(bottom.notification.title)
                            .title()
                        Text(bottom.notification.message)
                            .body()
                    }
                    
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .notificationStyle()
                .frame(maxHeight: 101, alignment: .bottom)
                .padding(15)
                .offset(y: offsetY)
                .gesture(dragGesture)
            }
        }
        .ignoresSafeArea(.all, edges: .all)
        .onAppear {
            showNotification()
        }
    }
    
    private func showNotification() {
        withAnimation(type) {
            offsetY = 0
        }
        dismissalTimer = Timer.scheduledTimer(withTimeInterval: bottom.duration, repeats: false) { a in
            self.dismissNotification()
        }
    }
    
    private func dismissNotification() {
        withAnimation(type) {
            offsetY = defaultOffset
        }
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
            self.bottom.onDismiss()
            print("dismissed")
        }
    }
    
    private func cancellationCleanup() {
            dismissalTimer?.invalidate()
            dismissalTimer = nil
        }
    
    // MARK: - Gesture Handling
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.height > 0 {
                    offsetY = value.translation.height
                } else {
                    offsetY = max(-15, value.translation.height)
                }
            }
            .onEnded { value in
                if value.translation.height > 20 {
                    cancellationCleanup()
                    dismissNotification()
                } else {
                    withAnimation(type) {
                        offsetY = 0
                    }
                }
            }
    }
}

#Preview {
    BottomNotificationView(MainNotification.NotificationStructure(title: "aaaaaaaaaaaaaaaaaaaaa", message: "bbbbbbbbbbbbbbbbbbbbbbbbb"), duration: 6, onDismiss: {print("workaa")})
}
