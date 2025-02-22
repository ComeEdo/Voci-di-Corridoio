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

    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var userManager: UserManager

    private var functions: Utility = Utility.shared

    @State private var isOperationFinished: Bool = true

    @State private var email: String = "frezzotti.edoardo.stud@itisgalileiroma.it"
    @State private var password: String = "aa"

    @FocusState private var focusedField: Field?

    @State private var keyboardHeight: CGFloat = .zero
    @State private var scroll: CGFloat = .zero

    @State private var users: [LoginResponse.RoleGroup]? = nil
    @State private var isShowingUserSelector = false

    init() {}

    var body: some View {
        ZStack {
            ColorGradient().zIndex(0)
            TitleOnView("Accesso")
            VStack(spacing: 0) {
                VScrollView($scroll, spacing: 20) {
                    if keyboardHeight != 0  {
                        Spacer()
                    }
                    emailView()
                    passwordView()
                }
                .scrollDismissesKeyboard(.interactively)
                .padding(.horizontal, 30)
                buttonView()
                    .padding(keyboardHeight == 0 ? 0 : 10)
                    .offset(y: keyboardHeight == 0 ? scroll.progessionAsitotic(-20, -20) : scroll.progessionAsitotic(-10, -10))
            }
        }
        .navigationDestination(isPresented: $isShowingUserSelector) {
            if let users = users {
                UserSelectorView(users) { UUID in
                    isOperationFinished = false
                    logInUser(UUID)
                }
            }
        }
        .navigationTitle("")
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
        isOperationFinished = false
        Task {
            //ordine esecuzione 2
            do {
                let alert = try await userManager.logInUser(email: email, password: password)
                if case .success(let users) = alert {
                    guard !users.allSatisfy({ $0.users.isEmpty }) else {
                        throw LoginError.userNotFound
                    }
                    let allUsers = users.flatMap { $0.users }
                    if allUsers.count == 1, let singleUser = allUsers.first {
                        return logInUser(singleUser.id)
                    } else {
                        self.users = users
                        isShowingUserSelector = true
                    }
                } else {
                    Utility.setupAlert(alert.notification)
                }
            } catch let error as ServerError {
                if error == .sslError {
                    SSLAlert(error.notification)
                } else {
                    Utility.setupAlert(error.notification)
                }
            } catch let error as LoginError {
                if error == .userNotFound {
                    Utility.setupBottom(error.notification)
                } else {
                    Utility.setupAlert(error.notification)
                }
            } catch let error as Notifiable {
                Utility.setupAlert(error.notification)
            } catch {
                print(error.localizedDescription)
                Utility.setupAlert(error)
            }
            //ordine esecuzione 3
            isOperationFinished = true
        }
        //ordine esecuzione 1
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

    func logInUser(_ userUUID: UUID) {
        Task {
            do {
                let alert = try await userManager.getUserAndToken(userUUID)
                dismiss()
                Utility.setupBottom(alert.notification)
            } catch let error as ServerError {
                SSLAlert(error)
            } catch let error as Notifiable {
                Utility.setupAlert(error.notification)
            } catch {
                Utility.setupAlert(error)
            }
            isOperationFinished = true
        }
    }
}

#Preview {
    SignInView()
}
