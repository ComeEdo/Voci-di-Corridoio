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
    func title(_ size: CGFloat = 22, _ weight: Font.Weight = .bold) -> Text {
        self.font(.system(size: size, weight: weight))
    }
    func body(_ size: CGFloat = 18) -> Text {
        self.font(.system(size: size, weight: .semibold))
    }
    func textTag(_ size: CGFloat? = nil, weight: Font.Weight = .regular) -> some View {
        self.font(.caption)
            .fontWeight(weight)
            .padding(.horizontal, weight.horizontalPadding)
            .padding(.vertical, weight.verticalPadding)
            .background(Capsule().stroke(lineWidth: weight.strokeWidth))
    }
}

extension Font.Weight {
    var strokeWidth: CGFloat {
        switch self {
        case .ultraLight: return 0.25
        case .thin: return 0.5
        case .light: return 0.75
        case .regular: return 1
        case .medium: return 1.25
        case .semibold: return 1.5
        case .bold: return 1.75
        case .heavy: return 2
        case .black: return 2.25
        default: return 1
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .ultraLight: return 4
        case .thin: return 5
        case .light: return 6
        case .regular: return 8
        case .medium: return 9
        case .semibold: return 10
        case .bold: return 11
        case .heavy: return 12
        case .black: return 13
        default: return 8
        }
    }
    
    var verticalPadding: CGFloat {
        switch self {
        case .ultraLight: return 1
        case .thin: return 1.5
        case .light: return 2
        case .regular: return 3
        case .medium: return 4
        case .semibold: return 5
        case .bold: return 6
        case .heavy: return 7
        case .black: return 8
        default: return 3
        }
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
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 20))
            .foregroundColor(isEnabled ? Color.white : Color.secondary)
    }
    
    func notificationStyle(_ accent: Color? = nil) -> some View {
        self
            .background(RoundedRectangle(cornerRadius: 40, style: .continuous)
                .inset(by: 5)
                .stroke(lineWidth: 3)
                .fill((accent != nil ? accent! : Color.gray.opacity(0.5)))
            )
            .background(RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color.black)
                .stroke(accent ?? Color.accent)
                .shadow(color: accent ?? Color.accent, radius: 3))
    }
    
    func alertStyle() -> some View {
        self
            .padding()
            .notificationStyle()
            .padding(.horizontal, 60)
    }
}

fileprivate struct NoSpaceModifier: ViewModifier {
    @Binding private var text: String
    
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

final class KeyboardManager: ObservableObject {
    static let shared = KeyboardManager()
    
    @Published private(set) var keyboardHeight: CGFloat = .zero
    var isZero: Bool {
        if keyboardHeight == .zero {
            return true
        } else {
            return false
        }
    }
    
    private init() {
        addKeyboardObservers()
    }
    
    private func addKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                DispatchQueue.main.async {
                    withAnimation {
                        self.keyboardHeight = keyboardFrame.height
                    }
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            DispatchQueue.main.async {
                withAnimation {
                    self.keyboardHeight = .zero
                }
            }
        }
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
