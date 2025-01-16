//
//  SignInView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 10/11/24.
//

import SwiftUI


struct SignInView: View {
    enum Field {
        case mail
        case password
    }
    
    @Environment(\.presentationMode) private var presentationMode
    
    private var exit: () -> Void { return { presentationMode.wrappedValue.dismiss() } }
    
    @EnvironmentObject private var userManager: UserManager
    @EnvironmentObject private var notificationManager: NotificationManager
    
    private var functions: Utility = Utility.shared
    
    @State private var isOperationFinished: Bool = true
    
    @State private var email: String = ".stud@itisgalileiroma.it"
    @State private var password: String = ""
    
    @FocusState private var focusedField: Field?
    
    @State private var keyboardHeight: CGFloat = .zero
    @State private var scroll: CGFloat = .zero
    
    init() {}
    
    var body: some View {
        ZStack {
            ColorGradient().zIndex(0)
            VStack(spacing: 0) {
                VScrollView($scroll) {
                    VStack(spacing: 20) {
                        if keyboardHeight != 0  {
                            Spacer()
                        }
                        emailView()
                        passwordView()
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .scrollIndicators(.never)
                .padding(.horizontal, 30)
                buttonView()
                    .padding(keyboardHeight == 0 ? 0 : 10)
                    .offset(y: keyboardHeight == 0 ? min(20, scroll) : min(10, scroll))
            }
        }
        .getKeyboardYAxis($keyboardHeight)
        .toolbarBackground(.hidden)
        .navigationBarBackButtonHidden(!isOperationFinished)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if !isOperationFinished {
                    Image(systemName: "arrow.2.circlepath")
                        .rotateIt()
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    private func emailView() -> some View {
        VStack {
            HStack {
                AuthTextField("Email", text: $email)
                    .emailFieldStyle($email)
                    .focused($focusedField, equals: .mail)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = getFocus()
                    }
                ValidationIcon(functions.mailChecker(email).result).validationIconStyle(email.isEmpty)
            }
            DividerText(result: functions.mailChecker(email), empty: email.isEmpty)
        }
    }
    
    private func passwordView() -> some View {
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
        }
    }
    
    private func buttonView() -> some View {
        VStack {
            Button(action: handleLogin) {
                Text("Accedi").textButtonStyle(isFormValid())
            }
            .disabled(!isFormValid() || !isOperationFinished)
        }
    }
    
    private func handleLogin() {
        focusedField = nil
        if isFormValid() {
            logInLogic()
        } else {
            print("cose starne")
            // Handle login failure
        }
    }
    
    private func logInLogic() {
        isOperationFinished = false
        Task {
            //ordine esecuzione 2
            do {
                let alert = try await userManager.loginUser(email: email, password: password)
                setupAlert(alert.response)
            } catch let error as RegistrationError {
                setupAlert(error.message)
            } catch let error as Codes {
                setupAlert(error.response)
            } catch {
                print(error.localizedDescription)
                setupAlert(error)
            }
            //ordine esecuzione 3
            isOperationFinished = true
        }
        //ordine esecuzione 1
    }
    
    private func setupAlert(_ alert: MainNotification.NotificationStructure) {
        notificationManager.showAlert(alert, type: .error)
    }
    private func setupAlert(_ error: Error) {
        notificationManager.showAlert(MainNotification.NotificationStructure(title: "Errore", message: "\(error.localizedDescription)"), type: .success)
    }
                                                            
    private func getFocus() -> Field? {
        if !functions.mailChecker(email).result {
            return .mail
        }
        if !functions.passwordChecker(password).result {
            return .password
        }
        return nil
    }
    
    private func isFormValid() -> Bool {
        return functions.mailChecker(email).result && functions.passwordChecker(password).result
    }
}

#Preview {
    SignInView()
}
