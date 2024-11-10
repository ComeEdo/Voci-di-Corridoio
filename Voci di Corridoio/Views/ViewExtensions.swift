//
//  ViewExtensions.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 10/11/24.
//

import SwiftUI

let mailEnding: String = ".stud@itisgalileiroma"
let fine: String = ".it"
let combinedMailEnding: String = mailEnding + fine

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
            SecureField("", text: $text, prompt: Text(placeholder).foregroundStyle(.gray))
        } else {
            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(.gray))
        }
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

extension View {
    func personalFieldStyle() -> some View {
        self
            .autocorrectionDisabled()
            .textInputAutocapitalization(.words)
            .padding(.trailing, -10)
    }
    
    func emailFieldStyle() -> some View {
        self
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
            .padding(.trailing, -10)
    }
    
    func passwordFieldStyle() -> some View {
        self
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .padding(.trailing, -10)
    }
    
    func validationIconStyle(_ isEmpty: Bool) -> some View {
        self
            .opacity(isEmpty ? 0.0 : 1.0)
    }
    
    func validationTextStyle(_ isValid: Bool, isEmpty: Bool) -> some View {
        self
            .font(.system(size: 12))
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(isValid ? Color.gray : .red)
            .opacity(isEmpty ? 0.0 : 1.0)
    }
    
    func dividerStyle(_ isValid: Bool) -> some View {
        self
            .overlay(isValid ? Color.gray : Color.red)
    }
    
    func signInButtonStyle(_ isEnabled: Bool) -> some View {
        self
            .fontWeight(.bold)
            .padding()
            .background(.tint, in: RoundedRectangle(cornerRadius: 20))
            .foregroundColor(isEnabled ? Color.white : Color.secondary)
            .disabled(!isEnabled)
    }
}
