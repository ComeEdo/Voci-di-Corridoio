//
//  RegisterView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 10/11/24.
//

import SwiftUI

struct RegisterView: View {
    enum Field: Hashable {
        case name
        case surname
        case username
        case mail
        case password
        case repeatedPassword
    }
    
    private var functions: ViewFunctions = ViewFunctions()
    
    @State private var isAllGood: Bool = true
    
    @State private var name: String = ""
    @State private var surname: String = ""
    @State private var username: String = ""
    @State private var mail: String = ""
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
                                AuthTextField("Nome", text: $name)
                                    .personalFieldStyle($name)
                                    .focused($focusedField, equals: .name)
                                    .focused($isName)
                                    .onChange(of: isName) {
                                        if (isName == false) {
                                            name = validateText(name)
                                        }
                                    }
                                ValidationIcon(isValidInput(name)).validationIconStyle(name.isEmpty)
                            }
                            Divider().dividerStyle(isValidInput(name) || name.isEmpty)
                            Text(isValidInput(name) ? "Nome valido." : "Solo lettere.").validationTextStyle(name.isEmpty, isValid: isValidInput(name))
                        }
                        VStack {
                            HStack{
                                AuthTextField("Cognome", text: $surname)
                                    .personalFieldStyle($surname)
                                    .focused($focusedField, equals: .surname)
                                    .focused($isSurname)
                                    .onChange(of: isSurname) {
                                        if (isSurname == false) {
                                            surname = validateText(surname)
                                        }
                                    }
                                ValidationIcon(isValidInput(surname)).validationIconStyle(surname.isEmpty)
                            }
                            Divider().dividerStyle(isValidInput(surname) || surname.isEmpty)
                            Text(isValidInput(surname) ? "Cognome valido." : "Solo lettere.").validationTextStyle(surname.isEmpty, isValid: isValidInput(surname))
                        }
                    }
                    VStack {
                        HStack {
                            AuthTextField("Username", text: $username)
                                .passwordFieldStyle($username)
                                .focused($focusedField, equals: .username)
                            ValidationIcon(isValidUsername()).validationIconStyle(username.isEmpty)
                        }
                        Divider().dividerStyle(isValidUsername() || username.isEmpty)
                        Text(isValidUsername() ? "Username valido." : "\(username) non è valido, si possono usare solo . _.").validationTextStyle(username.isEmpty, isValid: isValidUsername())
                    }
                    VStack {
                        HStack {
                            AuthTextField("Email", text: $mail)
                                .emailFieldStyle($mail)
                                .focused($focusedField, equals: .mail)
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
                Text("Manca qualcosa").validationTextStyle(isAllGood, alignment: .center)
            }
            .padding(.bottom, keyboardHeight == 0 ? 0 : UIScreen.main.bounds.height - keyboardHeight - 30)
            .animation(.easeOut(duration: 0.3), value: keyboardHeight)
        }
        .getKeyboardYAxis($keyboardHeight)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    private func handleRegister() {
        focusedField = nil
        name = validateText(name)
        surname = validateText(surname)
        isAllGood = isFormValid()
        if (isAllGood) {
            
        } else {
            if(isValidInput(name)) {
                surname = ""
                isSurname = true
            } else {
                name = ""
                isName = true
            }
        }
    }
    
    private func isFormValid() -> Bool {
        return isValidInput(name) &&
        isValidInput(surname) &&
        isValidUsername() &&
        functions.isValidStudentEmail(mail) &&
        functions.isValidPassword(password) &&
        isPasswordsMatch()
    }
    
    private func isPasswordsMatch() -> Bool {
        return password == repeatedPassword
    }
    
    private func isValidInput(_ text: String) -> Bool {
        if (text == "") {
            return false
        }
        let allowedCharacterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzáàéèíìóòúùâêîôûäëïöüãñåæçđðøýÿßẞęÈÉƏÊËĘĖĒEÙÚÛÜŪŨÌÍÎÏĮİĪįÄÖłşğĨǏŁĻĽĶĦĞĠŹŽŻÇĆČĊÑŃŅŇŴĚẼŘȚŤÝŶŸŲŮŰǓŵěẽēėřțťŷųůűūũǔıīĩǐőōõœǒǎāăąșśšďġħķļľźžżćčċńņň ")
        return text.rangeOfCharacter(from: allowedCharacterSet.inverted) == nil
    }
    
    private func isValidUsername() -> Bool {
        let allowedCharacterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._")
        return username.rangeOfCharacter(from: allowedCharacterSet.inverted) == nil
    }
    
    private func validateText(_ text: String) -> String {
        return text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

#Preview {
    RegisterView()
}
