//
//  SignInView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 10/11/24.
//

import SwiftUI


struct SignInView: View {
    enum Field: Hashable {
        case mail
        case password
    }
    
    private var functions: Utility = Utility()
    
    @State private var user: User = User()
    @State private var password: String = ""
    
    @FocusState private var focusedField: Field?
    
    @State private var lastTextFieldPosition: CGFloat = .zero
    @State private var buttonPosition: CGFloat = .zero
    @State private var scrollOffset: CGFloat = .zero
    @State private var keyboardHeight: CGFloat = .zero
    
    var body: some View {
        ZStack {
            ColorGradient()
            VStack {
                Divider().offset(y: lastTextFieldPosition)
                Spacer()
            }.ignoresSafeArea()
                .zIndex(10)
            VScrollView {
                VStack(spacing: 20) {
                    VStack {
                        HStack {
                            AuthTextField("Email", text: $user.mail)
                                .emailFieldStyle($user.mail)
                                .focused($focusedField, equals: .mail)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = getFocus()
                                }
                            ValidationIcon(functions.mailChecker(user.mail).result).validationIconStyle(user.mail.isEmpty)
                        }
                        DividerText(result: functions.mailChecker(user.mail), empty: user.mail.isEmpty)
                    }
                    VStack {
                        HStack {
                            AuthTextField("Password", text: $password, isSecure: true)
                                .passwordFieldStyle($password)
                                .focused($focusedField, equals: .password)
                                .submitLabel(.done)
                                .onSubmit {
                                    focusedField = getFocus()
                                }
                            ValidationIcon(functions.passwordChecker(password).result).validationIconStyle(password.isEmpty)
                        }
                        DividerText(result: functions.passwordChecker(password), empty: password.isEmpty)
                            .overlay(GeometryReader { localGeometry in
                                Color.clear
                                    .onAppear {
                                        functions.updateTextFieldPosition(localGeometry, textFieldPosition: &lastTextFieldPosition, offset: &scrollOffset, buttonPosition: buttonPosition, keyboardHeight: keyboardHeight)
                                    }
                                    .onChange(of: buttonPosition) {
                                        functions.updateTextFieldPosition(localGeometry, textFieldPosition: &lastTextFieldPosition, offset: &scrollOffset, buttonPosition: buttonPosition, keyboardHeight: keyboardHeight)
                                    }
                            })
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.never)
            .padding(.horizontal, 30)
            .padding(.bottom, scrollOffset*2)
            .animation(.easeOut(duration: 0.3), value: scrollOffset)
            .zIndex(0)
            VStack {
                Spacer()
                Button(action: handleLogin) {
                    Text("Accedi").textButtonStyle(isFormValid())
                }
                .disabled(!isFormValid())
                .overlay(GeometryReader { localGeometry in
                        Color.clear
                            .onAppear {
                                functions.updateButtonPosition(localGeometry, button: &buttonPosition)
                            }
                            .onChange(of: keyboardHeight) {
                                functions.updateButtonPosition(localGeometry, button: &buttonPosition)
                            }
                    })
            }
            .zIndex(1)
            .padding(.bottom, keyboardHeight == 0 ? 0 : UIScreen.main.bounds.height - keyboardHeight - 30)
            .animation(.easeOut(duration: 0.3), value: keyboardHeight)
        }
        .getKeyboardYAxis($keyboardHeight)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .toolbarBackground(.hidden)
    }
    private func handleLogin() {
        focusedField = nil
        if isFormValid() {
            // Handle successful login
        } else {
            // Handle login failure
        }
    }
    
    private func getFocus() -> Field? {
        if !functions.mailChecker(user.mail).result {
            return .mail
        }
        if !functions.passwordChecker(password).result {
            return .password
        }
        return nil
    }
    
    private func isFormValid() -> Bool {
        return functions.mailChecker(user.mail).result && functions.passwordChecker(password).result
    }
}

#Preview {
    SignInView()
}
