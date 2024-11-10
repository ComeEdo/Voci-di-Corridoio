//
//  SignInView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 10/11/24.
//


import SwiftUI

struct SignInView: View {
    @State private var mail: String = ""
    @State private var password: String = ""
    
    private var noSpacesBinding: Binding<String> {
            Binding(
                get: { mail },
                set: { newValue in
                    // Rimuove gli spazi dal nuovo valore
                    mail = newValue.replacingOccurrences(of: " ", with: "")
                }
            )
        }

    var body: some View {
        VStack(spacing: 20) {
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
            Button("Accedi") {
                // Action
            }.signInButtonStyle(isFormValid())
        }.padding(.horizontal, 30)
    }
    private func isFormValid() -> Bool {
        return isValidStudentEmail(mail) &&
        isValidPassword(password)
    }
}

#Preview {
    SignInView()
}
