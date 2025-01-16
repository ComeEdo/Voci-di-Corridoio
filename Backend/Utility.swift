//
//  Utility.swift
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

struct ResultLocalized {
    let result: Bool
    let message: LocalizedStringResource
}

struct Utility {
    static let shared = Utility()
    
    let student: String = ".stud"
    let domain: String = "@itisgalileiroma"
    let fine: String = ".it"
    let studentMail: String
    let schoolMail: String
    static let MIN_LENGHT = 2
    static let MIN_LENGHT_INPUT = 1
    static let MAX_LENGHT = 128
    static let MAX_LENGHT_USERNAME = 40
    
    private init() {
        self.studentMail = student + domain + fine
        self.schoolMail = domain + fine
    }
    
    func mailChecker(_ email: String, avoid: [String] = []) -> ResultLocalized {
        guard !avoid.contains(email.lowercased()) else {
            return ResultLocalized(result: false, message: "L'email non è disponibile.")
        }
        guard !isValidStudentEmail(email) else {
            return ResultLocalized(result: true, message: "Email dello studente valida.")
        }
        guard !isValidSchoolEmail(email) else {
            return ResultLocalized(result: true, message: "Email istituzionale valida.")
        }
        /*guard !Utility.isValidEmail(email) else {
         return ResultLocalized(result: true, message: "Email valida.")
         }*/
        return ResultLocalized(result: false, message: "L'email non è valida.")
    }
    
    func isValidStudentEmail(_ email: String) -> Bool {
        let pattern = "^[A-Za-z0-9._-]+\\\(studentMail)$"
        guard !(email.isEmpty || email.hasPrefix(".") || email.contains("..") || email.contains("__") || email.hasPrefix("_") || email.contains("--") || email.hasPrefix("-") || email.count < Utility.MIN_LENGHT || email.count > Utility.MAX_LENGHT) else {
            return false
        }
        if let domainPart = email.split(separator: "@").first {
            let domain = domainPart.split(separator: ".").dropLast().joined(separator: ".")
            guard !(domain.hasSuffix("-") || domain.hasSuffix("_")) else {
                return false
            }
        }
        return email.matches(pattern)
    }
    
    func isValidSchoolEmail(_ email: String) -> Bool {
        let pattern = "^[A-Za-z0-9._-]+\\\(schoolMail)$"
        guard !(email.isEmpty || email.hasPrefix(".") || email.contains("..") || email.contains("__") || email.hasPrefix("_") || email.contains("--") || email.hasPrefix("-") || email.contains(".@") || email.contains("_@") || email.contains("-@") || email.count < Utility.MIN_LENGHT || email.count > Utility.MAX_LENGHT) else {
            return false
        }
        return email.matches(pattern)
    }
    
    static func isValidEmail(_ email: String) -> Bool {
        let validEmailRegex = "^[a-z0-9._-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
        guard !(email.isEmpty || email.contains("..") || email.hasPrefix(".") || email.contains(".@") || email.contains("@.") || email.contains("__") || email.hasPrefix("_") || email.contains("_@") || email.contains("--") || email.hasPrefix("-") || email.contains("-@") || email.contains("@-") || email.count < MIN_LENGHT || email.count > MAX_LENGHT) else {
            return false
        }
        
        if let domainPart = email.split(separator: "@").last {
            let domain = domainPart.split(separator: ".").dropLast().joined(separator: ".")
            guard !(domain.hasSuffix("-")) else {
                return false
            }
        }
        
        return email.matches(validEmailRegex)
    }
    
    static func isValidHardPassword(_ password: String) -> Bool {
        guard !(password.isEmpty || password.count < Utility.MIN_LENGHT || password.count > Utility.MAX_LENGHT) else {
            return false
        }
        
        let characterSet = "^[A-Za-z0-9~`!@#$%^&*()\\-_=\\+\\{\\}\\[\\]|\\\\;:\\\"<>,./?]+$"
        guard password.matches(characterSet) else {
            return false
        }
        
        let uppercasePattern = ".*[A-Z]+.*"
        let lowercasePattern = ".*[a-z]+.*"
        let numberPattern = ".*[0-9]+.*"
        let specialCharacterPattern = ".*[~`!@#$%^&*()\\-_=\\+\\{\\}\\[\\]|\\\\;:\\\"<>,./?]+.*"
        guard password.matches(uppercasePattern), password.matches(lowercasePattern), password.matches(numberPattern), password.matches(specialCharacterPattern) else {
            return false
        }
        
        let alphaNum = "^[A-Za-z0-9]$"
        return String(password.first!).matches(alphaNum) && String(password.last!).matches(alphaNum)
    }
    
    static private func isValidPassword(_ password: String) -> Bool {
        guard !(password.isEmpty || password.count < Utility.MIN_LENGHT || password.count > Utility.MAX_LENGHT) else {
            return false
        }
        
        let validPasswordRegex = "^[A-Za-z0-9~`!@#$%^&*()\\-_+={}\\[\\]|\\\\;:\"<>,./?]+$"
        return password.matches(validPasswordRegex)
    }
    
    func passwordChecker(_ password: String, avoid: [String] = []) -> ResultLocalized {
        guard !avoid.contains(password) else {
            return ResultLocalized(result: false, message: "Password non disponibile.")
        }
        guard !Utility.isValidPassword(password) else {
            return ResultLocalized(result: true, message: "Password valida.")
        }
        return ResultLocalized(result: false, message: "Password non valida.")
    }
}

struct DividerText: View {
    private let result: ResultLocalized
    private let empty: Bool
    
    init(result: ResultLocalized, empty: Bool) {
        self.result = result
        self.empty = empty
    }
    
    var body: some View {
        VStack {
            Divider().dividerStyle(result.result || empty)
            Text(result.message).validationTextStyle(empty, isValid: result.result)
        }
    }
}

struct ValidationIcon: View {
    private let icon: String
    private let color: Color
    
    init(_ isValid: Bool?, correct: String = "checkmark.circle", wrong: String = "xmark.circle") {
        if let isValid = isValid {
            self.icon = isValid ? correct : wrong
            self.color = isValid ? .green : .red
        } else {
            self.icon = ""
            self.color = .clear
        }
    }
    
    var body: some View {
        if icon.isEmpty {
            ProgressView()
        } else {
            Image(systemName: icon)
                .foregroundStyle(color)
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

@frozen
public struct VScrollView<Content>: View where Content: View {
    private let content: () -> Content
    private var VerticalOffset: Binding<CGFloat>?
    
    public init(_ VerticalOffset: Binding<CGFloat>? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.VerticalOffset = VerticalOffset
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                ZStack {
                    GeometryReader { innerGeometry in
                        Color.clear
                            .onChange(of: innerGeometry.frame(in: .global).minY) {
                                VerticalOffset?.wrappedValue = innerGeometry.frame(in: .global).maxY - geometry.frame(in: .global).maxY
                            }
                    }
                    content()
                }
                .frame(width: geometry.size.width)
                .frame(minHeight: geometry.size.height)
            }
        }
    }
}

struct AuthTextField: View {
    private let placeholder: LocalizedStringResource
    @Binding private var text: String
    private let isSecure: Bool
    
    init(_ placeholder: LocalizedStringResource, text: Binding<String>, isSecure: Bool = false) {
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

extension String {
    func matches(_ regex: String) -> Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: self)
    }
}
