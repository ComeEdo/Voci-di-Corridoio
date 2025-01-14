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
    
    init(_ notification: BottomNotification) {
        self.bottom = notification
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
        withAnimation(self.type) {
            self.offsetY = 0
        }
        HapticFeedback.trigger(HapticType.impact(style: .heavy))
        startTimer()
    }

    
    func startTimer() {
        self.dismissalTimer = Timer.scheduledTimer(withTimeInterval: bottom.duration, repeats: false) { [self] _ in
            if NotificationManager.shared.BottomShowing?.id == self.bottom.id {
                self.dismissNotification()
            }
            self.cancellationCleanup()
        }
    }
    
    private func dismissNotification() {
        withAnimation(type) {
            offsetY = defaultOffset
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
            self.bottom.onDismiss()
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
    BottomNotificationView(BottomNotification(notification: MainNotification.NotificationStructure(title: "aaaaaaaaaaaaaaaaaaaaa", message: "bbbbbbbbbbbbbbbbbbbbbbbbb"), duration: 6, type: .error, onDismiss: {print("workaa")}))
}
