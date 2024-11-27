//
//  ViewUtility.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 27/11/24.
//

import SwiftUI

struct ColorGradient: View {
    private let gradientColors: [Color] = [
        .gradientTop,
        .cyan,
        .cyan,
        .gradientBottom
    ]
    var body: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .top,
            endPoint: .bottom
        ).ignoresSafeArea()
    }
}

struct ViewFunctions {
    let mailEnding: String = ".stud@itisgalileiroma"
    let fine: String = ".it"
    let combinedMailEnding: String
    
    init() {
        self.combinedMailEnding = mailEnding + fine
    }

    func isValidStudentEmail(_ email: String) -> Bool {
        if email.hasPrefix(".") || email.contains("..") {
            return false
        }
        let pattern = "^[A-Za-z0-9._+-]+\\\(mailEnding)\\\(fine)$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return emailPredicate.evaluate(with: email)
    }

    func isValidPassword(_ password: String) -> Bool {
        if password.count < 4 {
            return false
        }
        let allowedCharacterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789~`!@#$%^&*()-_+={}[]|\\;:\"<>,./?")
        if password.rangeOfCharacter(from: allowedCharacterSet.inverted) != nil {
            return false
        }
        let uppercasePattern = ".*[A-Z]+.*"
        let lowercasePattern = ".*[a-z]+.*"
        let numberPattern = ".*[0-9]+.*"
        let specialCharacterPattern = ".*[~`!@#$%^&*()\\-_=\\+\\{\\}\\[\\]|\\\\;:\\\"<>,./?]+.*"
        let uppercaseTest = NSPredicate(format: "SELF MATCHES %@", uppercasePattern)
        let lowercaseTest = NSPredicate(format: "SELF MATCHES %@", lowercasePattern)
        let numberTest = NSPredicate(format: "SELF MATCHES %@", numberPattern)
        let specialCharacterTest = NSPredicate(format: "SELF MATCHES %@", specialCharacterPattern)
        
        if !(uppercaseTest.evaluate(with: password) &&
             lowercaseTest.evaluate(with: password) &&
             numberTest.evaluate(with: password) &&
             specialCharacterTest.evaluate(with: password)) {
            return false
        }
        
        let firstCharacter = password.first!
        let lastCharacter = password.last!
        
        let alphanumericCharacterSet = CharacterSet.alphanumerics
        
        return alphanumericCharacterSet.contains(firstCharacter.unicodeScalars.first!) &&
        alphanumericCharacterSet.contains(lastCharacter.unicodeScalars.first!)
    }
    
    func updateTextFieldPosition(_ localGeometry: GeometryProxy, textFieldPosition: inout CGFloat, offset: inout CGFloat, buttonPosition: CGFloat, keyboardHeight: CGFloat) {
        textFieldPosition = localGeometry.frame(in: .global).maxY + offset
        
        if textFieldPosition > buttonPosition, buttonPosition > .zero {
            offset = textFieldPosition - buttonPosition
            textFieldPosition -= offset
        } else if keyboardHeight == .zero && offset != .zero {
            offset = .zero
        }
    }

    func updateButtonPosition(_ localGeometry: GeometryProxy, button: inout CGFloat) {
        button = localGeometry.frame(in: .global).minY
    }
}

struct ValidationIcon: View {
    private let correct: String
    private let wrong: String
    private let isValid: Bool
    
    init(_ isValid: Bool, correct: String = "checkmark.circle", wrong: String = "xmark.circle") {
        self.correct = correct
        self.wrong = wrong
        self.isValid = isValid
    }
    
    var body: some View {
        Image(systemName: isValid ? correct : wrong)
            .foregroundStyle(isValid ? Color.green : Color.red)
    }
}

struct CommonSpacer: View {
    private let height: CGFloat
    
    init(_ height: CGFloat = 15) {
        self.height = height
    }
    
    var body: some View {
        Spacer().frame(height: height)
    }
}

@frozen
public struct VScrollView<Content>: View where Content: View {
    private let content: () -> Content
    
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                content()
                    .frame(width: geometry.size.width)
                    .frame(minHeight: geometry.size.height)
            }
        }
    }
}

struct AuthTextField: View {
    private let placeholder: String
    @Binding private var text: String
    private let isSecure: Bool
    
    init(_ placeholder: String, text: Binding<String>, isSecure: Bool = false) {
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
    }
    
    var body: some View {
        if isSecure {
            SecureField("", text: $text, prompt: Text(placeholder).textColor())
        } else {
            TextField("", text: $text, prompt: Text(placeholder).textColor())
        }
    }
}
