//
//  ViewExtensions.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 10/11/24.
//

import SwiftUI

extension Text {
    func textColor() -> Text {
        self.foregroundStyle(.accent)
    }
    func title() -> Text {
        self
            .textColor()
            .font(.title2)
            .fontWeight(.bold)
    }
    func body() -> Text {
        self
            .textColor()
            .font(.body)
            .fontWeight(.semibold)
    }
}

extension View {
    func rotateIt() -> some View {
        self.modifier(RotatingModifier())
    }
    
    func personalFieldStyle(_ cleanText: Binding<String>) -> some View {
        self
            .autocorrectionDisabled()
            .textInputAutocapitalization(.words)
            .padding(.trailing, -10)
    }
    
    func emailFieldStyle(_ text: Binding<String>) -> some View {
        self
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
            .padding(.trailing, -10)
            .modifier(NoSpaceModifier(text))
    }
    
    func passwordFieldStyle(_ text: Binding<String>) -> some View {
        self
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .padding(.trailing, -10)
            .modifier(NoSpaceModifier(text))
    }
    
    func validationIconStyle(_ isEmpty: Bool) -> some View {
        self.opacity(isEmpty ? 0 : 1)
    }
    
    func validationTextStyle(_ isEmpty: Bool = false, isValid: Bool = false, alignment: Alignment = .leading) -> some View {
        self
            .font(.system(size: 12))
            .frame(maxWidth: .infinity, alignment: alignment)
            .foregroundStyle(isValid ? Color.accentColor : Color.red)
            .opacity(isEmpty ? 0 : 1)
    }
    
    func dividerStyle(_ isValid: Bool) -> some View {
        self.overlay(isValid ? Color.accentColor : Color.red)
    }
    
    func textButtonStyle(_ isEnabled: Bool, width: CGFloat? = nil, padding: Edge.Set = .all) -> some View {
        self
            .fontWeight(.bold)
            .frame(width: width)
            .padding(padding)
            .background(.tint, in: RoundedRectangle(cornerRadius: 20))
            .foregroundColor(isEnabled ? Color.white : Color.secondary)
    }
    
    func getKeyboardYAxis(_ height: Binding<CGFloat>) -> some View {
        self.modifier(KeyboardPosition(height))
    }
    
    func alertStyle() -> some View {
        self
            .padding()
            .background(Color.white, in: RoundedRectangle(cornerRadius: 20).inset(by: -10))
            .padding(.horizontal, 60)
            .shadow(radius: 100)
    }
}

fileprivate struct NoSpaceModifier: ViewModifier {
    @Binding var text: String
    
    init(_ text: Binding<String>) {
        self._text = text
    }
    
    func body(content: Content) -> some View {
        content
            .onChange(of: text) {
                if text.contains(" ") {
                    text = text.replacingOccurrences(of: " ", with: "")
                }
            }
    }
}

struct KeyboardPosition: ViewModifier{
    @Binding var keyboardHeight: CGFloat
        
    init(_ height: Binding<CGFloat>) {
        self._keyboardHeight = height
    }
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                addKeyboardObservers()
            }
            .onDisappear {
                removeKeyboardObservers()
            }
    }

    private func addKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardFrame.minY
            }
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            keyboardHeight = .zero
        }
    }
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

private struct RotatingModifier: ViewModifier {
    @State private var rotation: Double = 0
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .onAppear() {
                withAnimation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
            .onDisappear() {
                withAnimation(Animation.easeInOut(duration: 1)) {
                    rotation = 0
                }
            }
    }
}
