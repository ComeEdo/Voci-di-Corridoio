//
//  CreateAccountView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 10/11/24.
//

import SwiftUI

struct CreateAccountView: View {
    enum Field {
        case name
        case surname
        case username
        case mail
        case password
        case repeatedPassword
    }
    
    @Environment(\.presentationMode) var presentationMode
    
    private var exit: () -> Void { return { presentationMode.wrappedValue.dismiss() } }
    
    @StateObject var userManager: UserManager = UserManager()
    
    private var functions: Utility = Utility()
    
    @State private var isGoingWell: Bool = true
    @State private var isOperationFinished: Bool = true
    
    @State private var isRegistered: Bool = false
    
    @State private var isAlertVisible: Bool = false
    @State private var alertTitle: LocalizedStringResource = ""
    @State private var alertMessage: LocalizedStringResource = ""
    
    @State private var user: User = User()
    
    @State private var isValidUsername: Bool? = false
    @State private var reason: LocalizedStringResource = ""
    
    @State private var avoidUsernames: [String] = []
    @State private var avoidMails: [String] = []
    
    @State private var debounceTimer: Timer?
    
    @State private var usernameCheckTask: URLSessionDataTask?
    
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
                .zIndex(0)
            VScrollView {
                VStack(spacing: 20) {
                    nameSurname()
                    usernameView()
                    mailView()
                    passwordView()
                    repeatedPasswordView()
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.never)
            .padding(.horizontal, 30)
            .padding(.bottom, scrollOffset*2)
            .animation(.easeOut(duration: 0.3), value: scrollOffset)
            .zIndex(1)
            VStack() {
                Spacer()
                Button(action: handleRegister) {
                    Text("Crea account").textButtonStyle(isFormValid())
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
                if !isGoingWell {
                    Text("Manca qualcosa").validationTextStyle(alignment: .center)
                }
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
                    AlertView(title: alertTitle, message: alertMessage) {
                        if isRegistered == true {
                            exit()
                        } else {
                            isAlertVisible = false
                        }
                    }
                }
            }
        )
    }
    
    private func nameView() -> some View {
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
                ValidationIcon(isValidInput(user.name).result).validationIconStyle(user.name.isEmpty)
            }
            DividerText(result: isValidInput(user.name), empty: user.name.isEmpty)
        }
    }
    
    private func surnameView() -> some View {
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
                ValidationIcon(isValidInput(user.surname).result).validationIconStyle(user.surname.isEmpty)
            }
            DividerText(result: isValidInput(user.surname), empty: user.surname.isEmpty)
        }
    }
    
    private func nameSurname() -> some View {
        HStack {
            nameView()
            surnameView()
        }
    }
    
    private func usernameView() -> some View {
        VStack {
            HStack {
                AuthTextField("Nome utente", text: $user.username)
                    .passwordFieldStyle($user.username)
                    .focused($focusedField, equals: .username)
                    .submitLabel(.next)
                    .onChange(of: user.username) {
                        Task {
                            await checkUsernameAvailability(user.username)
                         }
                    }
                    .onSubmit {
                        focusedField = getFocus()
                    }
                ValidationIcon(isValidUsername).validationIconStyle(user.username.isEmpty)
            }
            Divider().dividerStyle(isValidUsername ?? true || user.username.isEmpty)
            Text(reason).validationTextStyle(!user.username.isEmpty && isValidUsername == nil ? true : user.username.isEmpty, isValid: isValidUsername ?? true)
        }
    }
    
    private func mailView() -> some View {
        VStack {
            HStack {
                AuthTextField("Email", text: $user.mail)
                    .emailFieldStyle($user.mail)
                    .focused($focusedField, equals: .mail)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = getFocus()
                    }
                ValidationIcon(functions.mailChecker(user.mail, avoid: avoidMails).result).validationIconStyle(user.mail.isEmpty)
            }
            DividerText(result: functions.mailChecker(user.mail, avoid: avoidMails), empty: user.mail.isEmpty)
        }
    }
    
    private func passwordView() -> some View {
        VStack {
            HStack {
                AuthTextField("Password", text: $password, isSecure: true)
                    .passwordFieldStyle($password)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = getFocus()
                    }
                ValidationIcon(functions.passwordChecker(password).result).validationIconStyle(password.isEmpty)
            }
            DividerText(result: functions.passwordChecker(password), empty: password.isEmpty)
        }
    }
    
    private func repeatedPasswordView() -> some View {
        VStack {
            HStack {
                AuthTextField("Ripeti password", text: $repeatedPassword, isSecure: true)
                    .passwordFieldStyle($repeatedPassword)
                    .focused($focusedField, equals: .repeatedPassword)
                    .submitLabel(.done)
                    .onSubmit {
                        focusedField = getFocus()
                    }
                ValidationIcon(isPasswordsMatch().result).validationIconStyle(repeatedPassword.isEmpty)
            }
            DividerText(result: isPasswordsMatch(), empty: repeatedPassword.isEmpty)
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
    
    private func handleRegister() {
        focusedField = nil
        user.name = validateText(user.name)
        user.surname = validateText(user.surname)
        isGoingWell = isFormValid()
        if (isGoingWell) {
            registerLogic()
        } else {
            if(isValidInput(user.name).result) {
                user.surname = ""
                isSurname = true
            } else {
                user.name = ""
                isName = true
            }
        }
    }
    
    private func registerLogic() {
        isOperationFinished = false
        userManager.currentUser = user
        Task {
            //ordine esecuzione 2
            do {
                usernameCheckTask?.cancel()
                let alert = try await userManager.registerUser(password: password)
                if case .sucess = alert {
                    isRegistered = true
                } else if case .failureUsername(let username) = alert {
                    avoidUsernames.append(username)
                } else if case .failureMail(let mail) = alert {
                    avoidMails.append(mail)
                } else if case .failureUsernameMail(let username, let mail) = alert {
                    avoidUsernames.append(username)
                    avoidMails.append(mail)
                }
                setupAlert(alert.response)
            } catch let error as RegistrationError {
                setupAlert(error.message)
            } catch let error as Codes {
                setupAlert(error.response)
            } catch {
                print(error.localizedDescription)
            }
            //ordine esecuzione 3
            if !isRegistered {
                isGoingWell = false
            }
            isOperationFinished = true
        }
        //ordine esecuzione 1
    }
    
    private func setupAlert(_ message: AlertResponse) {
        alertTitle = message.title
        alertMessage = message.message
        isAlertVisible = true
    }
    
    private func getFocus() -> Field? {
        if !isValidInput(user.name).result {
            return .name
        }
        if !isValidInput(user.surname).result {
            return .surname
        }
        if isValidUsername == false {
            return .username
        }
        if !functions.mailChecker(user.mail, avoid: avoidMails).result {
            return .mail
        }
        if !functions.passwordChecker(password).result {
            return .password
        }
        if !isPasswordsMatch().result {
            return .repeatedPassword
        }
        return nil
    }
    
    private func isFormValid() -> Bool {
        return isValidInput(user.name).result &&
        isValidInput(user.surname).result &&
        isValidUsername ?? true &&
        functions.mailChecker(user.mail, avoid: avoidMails).result &&
        functions.passwordChecker(password).result &&
        isPasswordsMatch().result
    }
    
    private func isPasswordsMatch() -> ResultLocalized {
        if password == repeatedPassword {
            return ResultLocalized(result: true, message: "Password valida.")
        } else {
            return ResultLocalized(result: false, message: "Le password sono diverse.")
        }
    }
    
    private func isValidInput(_ text: String) -> ResultLocalized {
        let allowedCharacterSet = "^[a-zA-ZáàéèíìóòúùâêîôûäëïöüãñåæçđðøýÿßẞęÈÉƏÊËĘĖĒEÙÚÛÜŪŨÌÍÎÏĮİĪįÄÖłşğĨǏŁĻĽĶĦĞĠŹŽŻÇĆČĊÑŃŅŇŴĚẼŘȚŤÝŶŸŲŮŰǓŵěẽēėřțťŷųůűūũǔıīĩǐőōõœǒǎāăąșśšďġħķļľźžżćčċńņň ]+$"
        guard !(text.isEmpty || text.count < Utility.MIN_LENGHT_INPUT || text.count > Utility.MAX_LENGHT), text.matches(allowedCharacterSet) else {
            return ResultLocalized(result: false, message: "Contiene caratteri non validi.")
        }
        return ResultLocalized(result: true, message: "Valido.")
    }
    
    private func isUsernameValid() -> Bool {
        guard !user.username.isEmpty else {
            reason = "È vuoto."
            return false
        }
        let allowedCharacterSet = "^[a-zA-Z0-9._]+$"
        guard user.username.matches(allowedCharacterSet) else {
            reason = "\(user.username) non è valido, poi usare solo . _."
            return false
        }
        guard !avoidUsernames.contains(user.username) else {
            reason = "\(user.username) è già in uso."
            return false
        }
        guard !(user.username.count < Utility.MIN_LENGHT) else {
            reason = "\(user.username) è troppo corto."
            return false
        }
        guard !(user.username.count > Utility.MAX_LENGHT_USERNAME) else {
            reason = "\(user.username) è troppo lungo."
            return false
        }
        return true
    }
    
    @MainActor
    private func checkUsernameAvailability(_ username: String) async {
        debounceTimer?.invalidate()
        
        guard isUsernameValid() else {
            isValidUsername = false
            return
        }
        
        if isValidUsername != nil {
            isValidUsername = nil
        }
        
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) {_ in
            
            guard let url = URL(string: "\(URN)/check-username") else {
                reason = "URL non valido: \(URN)/check-username."
                isValidUsername = true
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let payload: [String: Any] = ["username": username]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            } catch let err {
                reason = "\(err.localizedDescription)"
                isValidUsername = false
                return
            }
            
            usernameCheckTask?.cancel()
            usernameCheckTask = nil
            
            usernameCheckTask = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil, let httpResponse = response as? HTTPURLResponse else {
                    if let err = error?.localizedDescription {
                        reason = "Richiesta fallita: \(err)"
                    } else {
                        let unknownError: LocalizedStringResource = "Errore sconosciuto."
                        reason = "Richiesta fallita: \(unknownError)"
                    }
                    isValidUsername = true
                    return
                }
                
                let statusCode = httpResponse.statusCode
                do {
                    let apiResponse = try JSONDecoder().decode(ApiResponse.self, from: data)
                    print("Success: \(apiResponse.success)")
                    print("Message: \(apiResponse.message)")
                    
                    switch statusCode {
                    case 200:
                        if let exist = apiResponse.data?.exists, let username = apiResponse.data?.username {
                            if exist {
                                avoidUsernames.append(username)
                            }
                        }
                        if isUsernameValid() {
                            reason = "\(user.username) valido."
                            isValidUsername = true
                        } else {
                            isValidUsername = false
                        }
                    default:
                        reason = "\(apiResponse.message)"
                    }
                } catch let error as DecodingError {
                    reason = "Si è verificato un errore JSON: \(error.localizedDescription)."
                    isValidUsername = true
                    return
                } catch {
                    reason = "Impossibile interpretare la risposta: \(error.localizedDescription)."
                    isValidUsername = true
                    return
                }
            }
            usernameCheckTask?.resume()
        }
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
