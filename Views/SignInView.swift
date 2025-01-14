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
    
    @State private var isOperationFinished: Bool = true
    
    @State private var isAlertVisible: Bool = false
    @State private var alert: MainNotification.NotificationStructure = MainNotification.NotificationStructure(title: "", message: "")
    
    private var functions: Utility = Utility.shared
    
    @State private var email: String = ".stud@itisgalileiroma.it"
    @State private var password: String = ""
    
    @FocusState private var focusedField: Field?
    
    @State private var lastTextFieldPosition: CGFloat = .zero
    @State private var buttonPosition: CGFloat = .zero
    @State private var scrollOffset: CGFloat = .zero
    @State private var keyboardHeight: CGFloat = .zero
    
    init() {}
    
    var body: some View {
        ZStack {
            ColorGradient().zIndex(0)
            VScrollView {
                VStack(spacing: 20) {
                    emailView()
                    passwordView()
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.never)
            .padding(.horizontal, 30)
            .padding(.bottom, scrollOffset*2)
            .animation(.easeOut(duration: 0.3), value: scrollOffset)
            .zIndex(1)
            VStack {
                Spacer()
                Button(action: handleLogin) {
                    Text("Accedi").textButtonStyle(isFormValid())
                }
                .disabled(!isFormValid() || !isOperationFinished)
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
            .padding(.bottom, keyboardHeight == 0 ? 0 : UIScreen.main.bounds.height - keyboardHeight - 30)
            .animation(.easeOut(duration: 0.3), value: keyboardHeight)
            .zIndex(2)
        }
        .getKeyboardYAxis($keyboardHeight)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .toolbarBackground(.hidden)
        .navigationBarBackButtonHidden(!isOperationFinished || isAlertVisible)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if !isOperationFinished || isAlertVisible {
                    Image(systemName: "arrow.2.circlepath")
                        .rotateIt()
                        .fontWeight(.bold)
                }
            }
        }
        .overlay(
            Group {
                if isAlertVisible {
                    /*AlertView(alert) {
                        if userManager.isAuthenticated {
                            exit()
                        } else {
                            isAlertVisible = false
                        }
                    }*/
                }
            }
        )
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
        self.alert = alert
        isAlertVisible = true
    }
    private func setupAlert(_ error: Error) {
        self.alert = MainNotification.NotificationStructure(title: "Errore", message: "\(error.localizedDescription)")
        isAlertVisible = true
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
