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
        case email
        case password
        case repeatedPassword
    }
    
    @Environment(\.presentationMode) private var presentationMode
    
    private var exit: () -> Void { return { presentationMode.wrappedValue.dismiss() } }
    
    @EnvironmentObject private var userManager: UserManager
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var classes: ClassesManager
    
    private var functions: Utility = Utility.shared
    
    @State private var isOperationFinished: Bool = true
    
    @State private var user: RegistrationData = RegistrationData(email: "edo.stud@itisgalileiroma.it")
    
    @State private var isValidUsername: Bool? = false
    @State private var reason: LocalizedStringResource = ""
    
    @State private var avoidUsernames: [String] = []
    @State private var avoidMails: [String] = []
    
    @State private var debounceTimer: Timer?
    
    @State private var usernameCheckTask: URLSessionDataTask?
    
    @FocusState private var focusedField: Field?
    
    @State private var keyboardHeight: CGFloat = .zero
    @State private var scroll: CGFloat = .zero
    
    init() {}
    
    var body: some View {
        ZStack {
            ColorGradient().zIndex(0)
            VStack {
                Text("Crea account")
                    .title(30, .heavy)
                Spacer()
            }
            .padding(.top, 58)
            .ignoresSafeArea()
            VStack(spacing: 0) {
                VScrollView($scroll) {
                    VStack(spacing: 20) {
                        if keyboardHeight != 0  {
                            Spacer()
                        }
                        nameSurname()
                        usernameClass()
                        emailView()
                        passwordView()
                        repeatedPasswordView()
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .scrollIndicators(.never)
                .padding(.horizontal, 30)
                buttonView()
                    .padding(keyboardHeight == 0 ? 0 : 10)
                    .offset(y: keyboardHeight == 0 ? scroll.progessionAsitotic(-20, -20) : scroll.progessionAsitotic(-10, -10))
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
        .onDisappear {
            cancelUsernameCheckTask()
            invalidateDebounceTimer()
        }
    }
    
    private func nameView() -> some View {
        VStack {
            HStack {
                AuthTextField("Nome", text: $user.name)
                    .personalFieldStyle($user.name)
                    .focused($focusedField, equals: .name)
                    .submitLabel(.next)
                    .onChange(of: focusedField) { oldValue, newValue in
                        if oldValue == .name && newValue != .name {
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
                    .submitLabel(.next)
                    .onChange(of: focusedField) { oldValue, newValue in
                        if oldValue == .surname && newValue != .surname {
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
    
    private func extractNumberAndLetter(from value: String) -> (number: Int, letter: String) {
        let regex = try? NSRegularExpression(pattern: "(\\d*)([a-zA-Z0-9]*)")
        let match = regex?.firstMatch(in: value, options: [], range: NSRange(value.startIndex..., in: value))
        
        if let match = match, let numberRange = Range(match.range(at: 1), in: value), let letterRange = Range(match.range(at: 2), in: value) {
            let number = Int(value[numberRange]) ?? 0
            let letter = String(value[letterRange])
            return (number, letter)
        } else {
            return (0, "")
        }
    }
    
    private func classSelectorView() -> some View {
        VStack(spacing: 0) {
            Picker(selection: $user.role) {
                if case .teacher = user.role {
                    Text("Classe").tag(RegistrationData.RegistrationRole.teacher)
                }
                ForEach(classes.classes.keys.sorted { key1, key2 in
                    let value1 = classes.classes[key1] ?? ""
                    let value2 = classes.classes[key2] ?? ""
                    
                    let (num1, letter1) = extractNumberAndLetter(from: value1)
                    let (num2, letter2) = extractNumberAndLetter(from: value2)
                    
                    if num1 != num2 {
                        return num1 > num2
                    } else {
                        return letter1 < letter2
                    }
                }, id: \.self) { key in
                    Text(classes.classes[key] ?? "Error").tag(RegistrationData.RegistrationRole.student(classGroup: key))
                }
            } label: {
                Text("Classe").title()
            }
            .pickerStyle(.menu)
            .padding(.vertical, -4.4)   //allineamnto divider
            .onDisappear {
                user.role = RegistrationData.RegistrationRole.teacher
            }
            Divider().dividerStyle(user.role != .teacher)
        }
        .frame(width: 100)
    }
    
    private func usernameClass() -> some View {
        HStack(alignment: .top) {
            usernameView()
            if functions.isValidStudentEmail(user.email) {
                classSelectorView()
            }
        }
    }
    
    private func emailView() -> some View {
        VStack {
            HStack {
                AuthTextField("Email", text: $user.email)
                    .emailFieldStyle($user.email)
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = getFocus()
                    }
                ValidationIcon(functions.mailChecker(user.email, avoid: avoidMails).result).validationIconStyle(user.email.isEmpty)
            }
            DividerText(result: functions.mailChecker(user.email, avoid: avoidMails), empty: user.email.isEmpty)
        }
    }
    
    private func passwordView() -> some View {
        VStack {
            HStack {
                AuthTextField("Password", text: $user.password, isSecure: true)
                    .passwordFieldStyle($user.password)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = getFocus()
                    }
                ValidationIcon(functions.passwordChecker(user.password).result).validationIconStyle(user.password.isEmpty)
            }
            DividerText(result: functions.passwordChecker(user.password), empty: user.password.isEmpty)
        }
    }
    
    private func repeatedPasswordView() -> some View {
        VStack {
            HStack {
                AuthTextField("Ripeti password", text: $user.repeatedPassword, isSecure: true)
                    .passwordFieldStyle($user.repeatedPassword)
                    .focused($focusedField, equals: .repeatedPassword)
                    .submitLabel(.done)
                    .onSubmit {
                        focusedField = getFocus()
                    }
                ValidationIcon(isPasswordsMatch().result).validationIconStyle(user.repeatedPassword.isEmpty)
            }
            DividerText(result: isPasswordsMatch(), empty: user.repeatedPassword.isEmpty)
        }
    }
    
    private func buttonView() -> some View {
        VStack {
            Button(action: handleRegister) { Text("Crea account").textButtonStyle(isFormValid()) }.disabled(!isFormValid() || !isOperationFinished)
        }
    }
    
    func cancelUsernameCheckTask() {
        usernameCheckTask?.cancel()
        usernameCheckTask = nil
    }
    
    func invalidateDebounceTimer() {
        debounceTimer?.invalidate()
        debounceTimer = nil
    }
    
    private func handleRegister() {
        if focusedField == .name {
            user.name = validateText(user.name)
        } else if focusedField == .surname {
            user.surname = validateText(user.surname)
        }
        if isFormValid() {
            focusedField = nil
            executeRegisterUser()
        } else {
            if(!isValidInput(user.name).result) {
                focusedField = .name
            } else {
                focusedField = .surname
            }
        }
    }
    
    private func executeRegisterUser() {
        isOperationFinished = false
        Task {
            //ordine esecuzione 2
            do {
                usernameCheckTask?.cancel()
                let alert = try await userManager.registerUser(user: user)
                if case .sucess = alert {
                    exit()
                } else if case .failureUsername(let username) = alert {
                    avoidUsernames.append(username)
                    isValidUsername = isUsernameValid()
                } else if case .failureMail(let mail) = alert {
                    avoidMails.append(mail)
                } else if case .failureUsernameMail(let username, let mail) = alert {
                    avoidUsernames.append(username)
                    isValidUsername = isUsernameValid()
                    avoidMails.append(mail)
                }
                setupAlert(alert.notification)
            } catch let error as Notifiable {
                setupAlert(error.notification)
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
        notificationManager.showAlert(alert)
    }
    private func setupAlert(_ error: Error) {
        notificationManager.showAlert(MainNotification.NotificationStructure(title: "Errore", message: "\(error.localizedDescription)", type: .error))
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
        if !functions.mailChecker(user.email, avoid: avoidMails).result {
            return .email
        }
        if !functions.passwordChecker(user.password).result {
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
        (functions.isValidStudentEmail(user.email) ? user.isRoleStudent() : true) &&
        functions.mailChecker(user.email, avoid: avoidMails).result &&
        functions.passwordChecker(user.password).result &&
        isPasswordsMatch().result
    }
    
    private func isPasswordsMatch() -> ResultLocalized {
        if user.password == user.repeatedPassword {
            return ResultLocalized(result: true, message: "Password valida.")
        } else {
            return ResultLocalized(result: false, message: "Le password sono diverse.")
        }
    }
    
    private func isValidInput(_ text: String) -> ResultLocalized {
        let allowedCharacterSet = "^[a-zA-ZáàéèíìóòúùâêîôûäëïöüãñåæçđðøýÿßẞęÈÉƏÊËĘĖĒEÙÚÛÜŪŨÌÍÎÏĮİĪįÄÖłşğĨǏŁĻĽĶĦĞĠŹŽŻÇĆČĊÑŃŅŇŴĚẼŘȚŤÝŶŸŲŮŰǓŵěẽēėřțťŷųůűūũǔıīĩǐőōõœǒǎāăąșśšďġħķļľźžżćčċńņň'‘’ ]+$"
        guard !(text.isEmpty || text.count < Utility.MIN_LENGHT_INPUT || text.count > Utility.MAX_LENGHT), text.matches(allowedCharacterSet) else {
            return ResultLocalized(result: false, message: "Contiene caratteri non validi.")
        }
        func checkIfPresentIn(_ text: String, _ char: String) -> Bool {
            return text.hasSuffix(char) || text.hasPrefix(char) || text.contains(char+char)
        }
        guard !(checkIfPresentIn(text, "'") || checkIfPresentIn(text, "’") || checkIfPresentIn(text, "‘") || text.contains(" ' ") || text.contains(" ’ ") || text.contains(" ‘ ")) else {
            return ResultLocalized(result: false, message: "Apostrofo non valido.")
        }
        guard !(text.contains("‘’") || text.contains("’‘") || text.contains("‘'") || text.contains("'‘") || text.contains("’'") || text.contains("'’")) else {
            return ResultLocalized(result: false, message: "Apostrofi non valido.")
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
        invalidateDebounceTimer()
        
        guard isUsernameValid() else {
            return isValidUsername = false
        }
        
        isValidUsername = nil
        
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) {_ in
            
            guard let url = URL(string: "\(userManager.URN)/check-username") else {
                reason = "URL non valido: \(userManager.URN)/check-username."
                return isValidUsername = true
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: String] = ["username": username]
            
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                reason = "\(error.localizedDescription)"
                return isValidUsername = false
            }
            
            cancelUsernameCheckTask()
            
            usernameCheckTask = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil, let httpResponse = response as? HTTPURLResponse else {
                    if let err = error?.localizedDescription {
                        reason = "Richiesta fallita: \(err)"
                    } else {
                        let unknownError: LocalizedStringResource = "Errore sconosciuto."
                        reason = "Richiesta fallita: \(unknownError)"
                    }
                    return isValidUsername = true
                }
                
                let statusCode = httpResponse.statusCode
                do {
                    let apiResponse = try JSONDecoder().decode(ApiResponse<DataFieldCheckUsername>.self, from: data)
                    
                    switch statusCode {
                    case 200:
                        if apiResponse.data?.exists == true, let username = apiResponse.data?.username {
                            avoidUsernames.append(username)
                        }
                        if isUsernameValid() {
                            reason = "\(user.username) valido."
                            isValidUsername = true
                        } else {
                            isValidUsername = false
                        }
                    default:
                        reason = "\(apiResponse.message)"
                        isValidUsername = true
                    }
                } catch let error as DecodingError {
                    reason = "Si è verificato un errore JSON: \(error.localizedDescription)."
                    isValidUsername = true
                } catch {
                    reason = "Impossibile interpretare la risposta: \(error.localizedDescription)."
                    isValidUsername = true
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

struct RegistrationData {
    enum RegistrationRole: Hashable {
        case student(classGroup: UUID)
        case teacher
    }
    
    var name: String
    var surname: String
    var username: String
    var email: String
    var password: String
    var repeatedPassword: String
    var role: RegistrationRole
    
    init(name: String = "", surname: String = "", username: String = "", email: String = "", password: String = "", repeatedPassword: String = "", role: RegistrationRole = RegistrationRole.teacher) {
        self.name = name
        self.surname = surname
        self.username = username
        self.email = email
        self.password = password
        self.repeatedPassword = repeatedPassword
        self.role = role
    }
    
    func isRoleStudent() -> Bool {
        if case .student = role {
            return true
        }
        return false
    }
}
