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

struct GradientView: View {
    
    let style: any ShapeStyle
    
    var direction: Axis = .vertical
    
    var height: CGFloat? = nil
    
    var width: CGFloat? = nil
    
    /// The start point of the gradient.
    ///
    /// This value can be `.top` or .`bottom`.
    let startPoint: UnitPoint
    
    var endPoint: UnitPoint {
        if direction == .horizontal {
            return startPoint == .leading ? .trailing : .leading
        } else {
            return startPoint == .top ? .bottom : .top
        }
    }
    
    var body: some View {
        Rectangle()
            .fill(AnyShapeStyle(style))
            .frame(width: width, height: height)
            .mask( LinearGradient(gradient: Gradient(colors: [.black, .clear]), startPoint: startPoint, endPoint: endPoint) )
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
        let email = email.lowercased()
        let escapedStudentMail = studentMail
            .replacingOccurrences(of: ".", with: "\\.")
            .replacingOccurrences(of: "@", with: "\\@")
        let pattern = "^[a-z0-9._-]+\(escapedStudentMail)$"
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
        let email = email.lowercased()
        let escapedSchoolMail = schoolMail
            .replacingOccurrences(of: ".", with: "\\.")
            .replacingOccurrences(of: "@", with: "\\@")
        let pattern = "^[a-z0-9._-]+\(escapedSchoolMail)$"
        guard !(email.isEmpty || email.hasPrefix(".") || email.contains("..") || email.contains("__") || email.hasPrefix("_") || email.contains("--") || email.hasPrefix("-") || email.contains(".@") || email.contains("_@") || email.contains("-@") || email.count < Utility.MIN_LENGHT || email.count > Utility.MAX_LENGHT) else {
            return false
        }
        return email.matches(pattern)
    }
    
    static func isValidEmail(_ email: String) -> Bool {
        let email = email.lowercased()
        let validEmailRegex = "^[a-z0-9._-]+@[a-z0-9.-]+\\.[a-z]{2,}$"
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
    
    static private func isValidHardPassword(_ password: String) -> Bool {
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
    
    static func setupAlert(_ alert: MainNotification.NotificationStructure) {
        NotificationManager.shared.showAlert(alert)
    }
    static func setupAlert(_ error: Error) {
        NotificationManager.shared.showAlert(MainNotification.NotificationStructure(title: "Errore", message: "\(error.localizedDescription)", type: .error))
    }
    static func setupBottom(_ alert: MainNotification.NotificationStructure) {
        NotificationManager.shared.showBottom(alert)
    }
    static func setupBottom(_ error: Error) {
        NotificationManager.shared.showBottom(MainNotification.NotificationStructure(title: "Errore", message: "\(error.localizedDescription)", type: .error))
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
    private var VerticalOffset: Binding<CGFloat>
    private let spacing: CGFloat
    
    init(_ VerticalOffset: Binding<CGFloat> = .constant(0), spacing: CGFloat, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.VerticalOffset = VerticalOffset
        self.spacing = spacing
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                ZStack {
                    GeometryReader { innerGeometry in
                        EmptyView()
                            .onChange(of: innerGeometry.frame(in: .global).minY) {
                                VerticalOffset.wrappedValue = innerGeometry.frame(in: .global).maxY - geometry.frame(in: .global).maxY
                            }
                    }
                    VStack(spacing: spacing) {
                        content()
                    }
                }
                .frame(width: geometry.size.width)
                .frame(minHeight: geometry.size.height)
            }
        }
    }
}

struct TitleOnView: View {
    var title: String
    
    init(_ title: String) {
        self.title = title
    }
    
    var body: some View {
        VStack {
            Text(title).title(30, .heavy)
            Spacer()
        }
        .padding(.top, 58)
        .ignoresSafeArea()
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

extension CGFloat {
    func progessionAsitotic(_ asintoto: CGFloat, _ k: CGFloat) -> CGFloat {
        if (self > 0 && asintoto < 0) || (self < 0 && asintoto > 0) {
            return -asintoto * (1 - exp(self / k))
        } else {
            return self
        }
    }
}
