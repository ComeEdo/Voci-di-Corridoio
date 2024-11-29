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
    
    private var functions: ViewFunctions = ViewFunctions()
    
    @State private var mail: String = ""
    @State private var password: String = ""
    
    @FocusState private var focusedField: Field?
    
    @State private var lastTextFieldPosition: CGFloat = .zero
    @State private var buttonPosition: CGFloat = .zero
    @State private var scrollOffset: CGFloat = .zero
    @State private var keyboardHeight: CGFloat = .zero
    
    var body: some View {
        ZStack {
            ColorGradient()
            VScrollView {
                VStack(spacing: 20) {
                    VStack {
                        HStack {
                            AuthTextField("Email", text: $mail)
                                .emailFieldStyle($mail)
                                .focused($focusedField, equals: .mail)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = getFocus()
                                }
                            ValidationIcon(functions.isValidStudentEmail(mail)).validationIconStyle(mail.isEmpty)
                        }
                        Divider().dividerStyle(functions.isValidStudentEmail(mail) || mail.isEmpty)
                        Text(functions.isValidStudentEmail(mail) ? "Mail valida." : "La mail deve finire con \(functions.combinedMailEnding).").validationTextStyle(mail.isEmpty, isValid: functions.isValidStudentEmail(mail))
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
                            ValidationIcon(functions.isValidPassword(password)).validationIconStyle(password.isEmpty)
                        }
                        Divider().dividerStyle(functions.isValidPassword(password) || password.isEmpty)
                        Text(functions.isValidPassword(password) ? "Password valida." : "Maiuscola, minuscuola, numero e carattere speciale in mezzo.")
                            .validationTextStyle(password.isEmpty, isValid: functions.isValidPassword(password))
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
            //            .offset(y: -scrollOffset)
            .padding(.bottom, scrollOffset*2)
            .animation(.easeOut(duration: 0.3), value: scrollOffset)
            .zIndex(0)
            VStack {
                Spacer()
                Button(action: handleLogin) {
                    Text("Accedi").textButtonStyle(isFormValid())
                }
                .disabled(!isFormValid())
                .overlay(
                    GeometryReader { localGeometry in
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
        if !functions.isValidStudentEmail(mail) {
            return .mail
        }
        if !functions.isValidPassword(password) {
            return .password
        }
        return nil
    }
    
    private func isFormValid() -> Bool {
        return functions.isValidStudentEmail(mail) && functions.isValidPassword(password)
    }
}

#Preview {
    SignInView()
}
