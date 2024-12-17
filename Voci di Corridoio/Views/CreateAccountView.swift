//
//  CreateAccountView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 10/11/24.
//

import SwiftUI

struct CreateAccountView: View {
    enum Field: Hashable {
        case name
        case surname
        case username
        case mail
        case password
        case repeatedPassword
    }
    
    @StateObject var userManager: UserManager = UserManager()
    
    private var functions: Utility = Utility()
    
    @State private var isAllGood: Bool = true
    
    @State private var user: User = User()
    
    @State private var password: String = ""
    @State private var repeatedPassword: String = ""
    
    @FocusState private var focusedField: Field?
    @FocusState private var isName: Bool
    @FocusState private var isSurname: Bool
    
    @State private var lastTextFieldPosition: CGFloat = .zero
    @State private var buttonPosition: CGFloat = .zero
    @State private var scrollOffset: CGFloat = .zero
    @State private var keyboardHeight: CGFloat = .zero

    var body: some View {
        ZStack {
            ColorGradient()
            VScrollView {
                VStack(spacing: 20) {
                    HStack {
                        VStack {
                            HStack {
                                AuthTextField("Nome", text: $user.name)
                                    .personalFieldStyle($user.name)
                                    .focused($focusedField, equals: .name)
                                    .focused($isName)
                                    .submitLabel(.next)
                                    .onChange(of: isName) {
                                        if (isName == false) {
                                            user.name = validateText(user.name)
                                        }
                                    }
                                    .onSubmit {
                                        focusedField = getFocus()
                                    }
                                ValidationIcon(isValidInput(user.name)).validationIconStyle(user.name.isEmpty)
                            }
                            Divider().dividerStyle(isValidInput(user.name) || user.name.isEmpty)
                            Text(isValidInput(user.name) ? "Nome valido." : "Solo lettere.").validationTextStyle(user.name.isEmpty, isValid: isValidInput(user.name))
                        }
                        VStack {
                            HStack{
                                AuthTextField("Cognome", text: $user.surname)
                                    .personalFieldStyle($user.surname)
                                    .focused($focusedField, equals: .surname)
                                    .focused($isSurname)
                                    .submitLabel(.next)
                                    .onChange(of: isSurname) {
                                        if (isSurname == false) {
                                            user.surname = validateText(user.surname)
                                        }
                                    }
                                    .onSubmit {
                                        focusedField = getFocus()
                                    }
                                ValidationIcon(isValidInput(user.surname)).validationIconStyle(user.surname.isEmpty)
                            }
                            Divider().dividerStyle(isValidInput(user.surname) || user.surname.isEmpty)
                            Text(isValidInput(user.surname) ? "Cognome valido." : "Solo lettere.").validationTextStyle(user.surname.isEmpty, isValid: isValidInput(user.surname))
                        }
                    }
                    VStack {
                        HStack {
                            AuthTextField("Nome utente", text: $user.username)
                                .passwordFieldStyle($user.username)
                                .focused($focusedField, equals: .username)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = getFocus()
                                }
                            ValidationIcon(isValidUsername()).validationIconStyle(user.username.isEmpty)
                        }
                        Divider().dividerStyle(isValidUsername() || user.username.isEmpty)
                        Text(isValidUsername() ? "Username valido." : "\(user.username) non è valido, si possono usare solo . _.").validationTextStyle(user.username.isEmpty, isValid: isValidUsername())
                    }
                    VStack {
                        HStack {
                            AuthTextField("Email", text: $user.mail)
                                .emailFieldStyle($user.mail)
                                .focused($focusedField, equals: .mail)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = getFocus()
                                }
                            ValidationIcon(functions.isValidStudentEmail(user.mail)).validationIconStyle(user.mail.isEmpty)
                        }
                        Divider().dividerStyle(functions.isValidStudentEmail(user.mail) || user.mail.isEmpty)
                        Text(functions.isValidStudentEmail(user.mail) ? "Mail valida." : "La mail deve finire con \(functions.combinedMailEnding).").validationTextStyle(user.mail.isEmpty, isValid: functions.isValidStudentEmail(user.mail))
                    }
                    VStack {
                        HStack {
                            AuthTextField("Password", text: $password, isSecure: true)
                                .passwordFieldStyle($password)
                                .focused($focusedField, equals: .password)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = getFocus()
                                }
                            ValidationIcon(functions.isValidPassword(password)).validationIconStyle(password.isEmpty)
                        }
                        Divider().dividerStyle(functions.isValidPassword(password) || password.isEmpty)
                        Text((functions.isValidPassword(password) || password.isEmpty) ? "Password valida." : "Maiuscola, minuscuola, numero e carattere speciale in mezzo.").validationTextStyle(password.isEmpty, isValid: functions.isValidPassword(password))
                    }
                    VStack {
                        HStack {
                            AuthTextField("Ripeti password", text: $repeatedPassword, isSecure: true)
                                .passwordFieldStyle($repeatedPassword)
                                .focused($focusedField, equals: .repeatedPassword)
                                .submitLabel(.done)
                                .onSubmit {
                                    focusedField = getFocus()
                                }
                            ValidationIcon(isPasswordsMatch()).validationIconStyle(repeatedPassword.isEmpty)
                        }
                        Divider().dividerStyle(isPasswordsMatch() || repeatedPassword.isEmpty)
                        Text(isPasswordsMatch() ? "Password valida." : "Le password sono diverse.")
                            .validationTextStyle(repeatedPassword.isEmpty, isValid: isPasswordsMatch())
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
            VStack() {
                Spacer()
                Button(action: handleRegister) {
                    Text("Crea account").textButtonStyle(isFormValid())
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
                if !isAllGood {
                    Text("Manca qualcosa").validationTextStyle(alignment: .center)
                }
            }
            .padding(.bottom, keyboardHeight == 0 ? 0 : UIScreen.main.bounds.height - keyboardHeight - 30)
            .animation(.easeOut(duration: 0.3), value: keyboardHeight)
        }
        .getKeyboardYAxis($keyboardHeight)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .toolbarBackground(.hidden)
    }
    private func handleRegister() {
        focusedField = nil
        user.name = validateText(user.name)
        user.surname = validateText(user.surname)
        isAllGood = isFormValid()
        if (isAllGood) {
            registerLogic()
        } else {
            if(isValidInput(user.name)) {
                user.surname = ""
                isSurname = true
            } else {
                user.name = ""
                isName = true
            }
        }
    }
    
    private func registerLogic() {
        userManager.currentUser = user
        userManager.registerUser(password: password) { result in
            switch result {
            case .success(let message):
                print(message)
            case .failure(let error):
                print("Registration failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func getFocus() -> Field? {
        if !isValidInput(user.name) {
            return .name
        }
        if !isValidInput(user.surname) {
            return .surname
        }
        if !isValidUsername() {
            return .username
        }
        if !functions.isValidStudentEmail(user.mail) {
            return .mail
        }
        if !functions.isValidPassword(password) {
            return .password
        }
        if !isPasswordsMatch() {
            return .repeatedPassword
        }
        return nil
    }
    
    private func isFormValid() -> Bool {
        return isValidInput(user.name) &&
        isValidInput(user.surname) &&
        isValidUsername() &&
        functions.isValidStudentEmail(user.mail) &&
        functions.isValidPassword(password) &&
        isPasswordsMatch()
    }
    
    private func isPasswordsMatch() -> Bool {
        return password == repeatedPassword
    }
    
    private func isValidInput(_ text: String) -> Bool {
        if text == "" {
            return false
        }
        let allowedCharacterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzáàéèíìóòúùâêîôûäëïöüãñåæçđðøýÿßẞęÈÉƏÊËĘĖĒEÙÚÛÜŪŨÌÍÎÏĮİĪįÄÖłşğĨǏŁĻĽĶĦĞĠŹŽŻÇĆČĊÑŃŅŇŴĚẼŘȚŤÝŶŸŲŮŰǓŵěẽēėřțťŷųůűūũǔıīĩǐőōõœǒǎāăąșśšďġħķļľźžżćčċńņň ")
        return text.rangeOfCharacter(from: allowedCharacterSet.inverted) == nil
    }
    
    private func isValidUsername() -> Bool {
        if user.username == "" {
            return false
        }
        let allowedCharacterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._")
        return user.username.rangeOfCharacter(from: allowedCharacterSet.inverted) == nil
    }
    
    private func validateText(_ text: String) -> String {
        return text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

#Preview {
    CreateAccountView()
}
