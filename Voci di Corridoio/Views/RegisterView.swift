//
//  RegisterView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 10/11/24.
//


import SwiftUI

struct RegisterView: View {
    @State private var name: String = ""
    @State private var surname: String = ""
    @State private var username: String = ""
    @State private var mail: String = ""
    @State private var password: String = ""
    @State private var repeatedPassword: String = ""

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack {
                    HStack {
                        AuthTextField("Nome", text: $name).personalFieldStyle()
                        ValidationIcon(isValidName(name)).validationIconStyle(name.isEmpty)
                    }
                    Divider().dividerStyle(isValidName(name) || name.isEmpty)
                    Text(isValidName(name) ? "Nome valido." : "No caratteri spaciali.").validationTextStyle(isValidName(name), isEmpty: name.isEmpty)
                }
                VStack {
                    HStack{
                        AuthTextField("Cognome", text: $surname).personalFieldStyle()
                        ValidationIcon(isValidName(surname)).validationIconStyle(surname.isEmpty)
                    }
                    Divider().dividerStyle(isValidName(surname) || surname.isEmpty)
                    Text(isValidName(surname) ? "Cognome valido." : "No caratteri spaciali.").validationTextStyle(isValidName(surname), isEmpty: surname.isEmpty)
                }
            }
            VStack {
                HStack {
                    AuthTextField("Username", text: $username).passwordFieldStyle()
                    ValidationIcon(isValidUsername()).validationIconStyle(username.isEmpty)
                }
                Divider().dividerStyle(isValidUsername() || username.isEmpty)
                Text(isValidUsername() ? "Username valido." : "\(username) non è valido, si possono usare solo . _.").validationTextStyle(isValidUsername(), isEmpty: username.isEmpty)
            }
            VStack {
                HStack {
                    AuthTextField("Email", text: $mail).emailFieldStyle()
                    ValidationIcon(isValidStudentEmail(mail)).validationIconStyle(mail.isEmpty)
                }
                Divider().dividerStyle(isValidStudentEmail(mail) || mail.isEmpty)
                Text(isValidStudentEmail(mail) ? "Mail valida." : "La mail deve finire con \(combinedMailEnding).").validationTextStyle(isValidStudentEmail(mail), isEmpty: mail.isEmpty)
            }
            VStack {
                HStack {
                    AuthTextField("Password", text: $password, isSecure: true).passwordFieldStyle()
                    ValidationIcon(isValidPassword(password)).validationIconStyle(password.isEmpty)
                }
                Divider().dividerStyle(isValidPassword(password) || password.isEmpty)
                Text(isValidPassword(password) ? "Password valida" : "Maiuscola, minuscuola, numero e carattere speciale in mezzo.").validationTextStyle(isValidPassword(password), isEmpty: password.isEmpty)
            }
            VStack {
                HStack {
                    AuthTextField("Ripeti password", text: $repeatedPassword, isSecure: true).passwordFieldStyle()
                    ValidationIcon(isPasswordsMatch()).validationIconStyle(repeatedPassword.isEmpty)
                }
                Divider().dividerStyle(isPasswordsMatch() || repeatedPassword.isEmpty)
                Text(isPasswordsMatch() ? "Password valida" : "Le password sono diverse").validationTextStyle(isPasswordsMatch(), isEmpty: repeatedPassword.isEmpty)
            }
            Button("Registrati") {
                // Registration logic here
            }.signInButtonStyle(isFormValid())
        }.padding(.horizontal, 30)
    }
    private func isFormValid() -> Bool {
        return isValidName(name) &&
        isValidName(surname) &&
        isValidUsername() &&
        isValidStudentEmail(mail) &&
        isValidPassword(password) &&
        isPasswordsMatch()
    }
    private func isPasswordsMatch() -> Bool {
        return password == repeatedPassword
    }
    private func isValidName(_ name: String) -> Bool {
        let allowedCharacterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789áàéèíìóòúùâêîôûäëïöüãñåæçđðøýÿßẞęÈÉƏÊËĘĖĒEÙÚÛÜŪŨÌÍÎÏĮİĪįÄÖłşğĨǏŁĻĽĶĦĞĠŹŽŻÇĆČĊÑŃŅŇŴĚẼŘȚŤÝŶŸŲŮŰǓŵěẽēėřțťŷųůűūũǔıīĩǐőōõœǒǎāăąșśšďġħķļľźžżćčċńņň ")
        return name.rangeOfCharacter(from: allowedCharacterSet.inverted) == nil
    }
    private func isValidUsername() -> Bool {
        let allowedCharacterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._")
        return username.rangeOfCharacter(from: allowedCharacterSet.inverted) == nil
    }
}

#Preview {
    RegisterView()
}
