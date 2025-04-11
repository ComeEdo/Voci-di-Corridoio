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
    
    @EnvironmentObject private var keyboardManager: KeyboardManager
    @EnvironmentObject private var userManager: UserManager
    
    private var functions: Utility = Utility.shared
    
    @State private var isOperationFinished: Bool = true
    
    @State private var email: String = "frezzotti.edoardo.stud@itisgalileiroma.it"
    @State private var password: String = "aa"
    
    @FocusState private var focusedField: Field?
    
    @State private var scroll: CGFloat = .zero
    
    @State private var users: [LogInResponse.RoleGroup]? = nil
    @State private var isShowingUserSelector = false
    
    init() {}
    
    var body: some View {
        ZStack {
            ColorGradient().zIndex(0)
            TitleOnView("Accesso")
            VStack(spacing: 0) {
                VScrollView($scroll, spacing: 20) {
                    if !keyboardManager.isZero  {
                        Spacer()
                    }
                    emailView()
                    passwordView()
                }
                .scrollDismissesKeyboard(.interactively)
                .padding(.horizontal, 30)
                .scrollClipDisabled()
                buttonView()
                    .padding(keyboardManager.isZero ? 0 : 10)
                    .offset(y: keyboardManager.isZero ? scroll.progessionAsitotic(-20, -20) : scroll.progessionAsitotic(-10, -10))
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
            defer { isOperationFinished = true }
            //ordine esecuzione 2
            do {
                let alert = try await userManager.logInUser(email: email, password: password)
                if case .success(let users) = alert {
                    guard !users.allSatisfy({ $0.userModels.isEmpty }) else {
                        throw LoginError.userNotFound
                    }
                    let allUsers = users.flatMap { $0.userModels }
                    if allUsers.count == 1, let singleUserId = allUsers.first?.user.id {
                        return logInUser(singleUserId)
                    } else {
                        self.users = users
                        isShowingUserSelector = true
                    }
                } else {
                    Utility.setupAlert(alert.notification)
                }
            } catch let error as LoginError {
                if error == .userNotFound {
                    Utility.setupBottom(error.notification)
                } else {
                    Utility.setupAlert(error.notification)
                }
            } catch {
                if let err = mapError(error) {
                    Utility.setupAlert(err.notification)
                }
            }
            //ordine esecuzione 3
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
            defer { isOperationFinished = true }
            do {
                let alert = try await userManager.getAuthUserAndToken(userUUID)
                dismiss()
                Utility.setupBottom(alert.notification)
            } catch {
                if let err = mapError(error) {
                    Utility.setupAlert(err.notification)
                }
            }
        }
    }
}

#Preview {
    SignInView()
}
