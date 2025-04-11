//
//  ViewExtensions.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 10/11/24.
//

import SwiftUI

extension Text {
    func textColor() -> Text {
        self.foregroundStyle(.accent)
    }
    func title(_ size: CGFloat = 22, _ weight: Font.Weight = .bold) -> Text {
        self.font(.system(size: size, weight: weight))
    }
    func body(_ size: CGFloat = 18) -> Text {
        self.font(.system(size: size, weight: .semibold))
    }
}

extension View {
    func rotateIt() -> some View {
        self.modifier(RotatingModifier())
    }
    
    func personalFieldStyle(_ cleanText: Binding<String>) -> some View {
        self
            .autocorrectionDisabled()
            .textInputAutocapitalization(.words)
            .padding(.trailing, -10)
    }
    
    func emailFieldStyle(_ text: Binding<String>) -> some View {
        self
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
            .padding(.trailing, -10)
            .modifier(NoSpaceModifier(text))
    }
    
    func passwordFieldStyle(_ text: Binding<String>) -> some View {
        self
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .padding(.trailing, -10)
            .modifier(NoSpaceModifier(text))
    }
    
    func validationIconStyle(_ isEmpty: Bool) -> some View {
        self.opacity(isEmpty ? 0 : 1)
    }
    
    func validationTextStyle(_ isEmpty: Bool = false, isValid: Bool = false, alignment: Alignment = .leading) -> some View {
        self
            .font(.system(size: 12))
            .frame(maxWidth: .infinity, alignment: alignment)
            .foregroundStyle(isValid ? Color.accentColor : Color.red)
            .opacity(isEmpty ? 0 : 1)
    }
    
    func dividerStyle(_ isValid: Bool) -> some View {
        self.overlay(isValid ? Color.accentColor : Color.red)
    }
    
    func textButtonStyle(_ isEnabled: Bool, width: CGFloat? = nil, padding: Edge.Set = .all) -> some View {
        self
            .fontWeight(.bold)
            .frame(width: width)
            .padding(padding)
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 20))
            .foregroundColor(isEnabled ? Color.white : Color.secondary)
    }
    
    func notificationStyle(_ accent: Color? = nil) -> some View {
        self
            .background(RoundedRectangle(cornerRadius: 40, style: .continuous)
                .inset(by: 5)
                .stroke(lineWidth: 3)
                .fill((accent != nil ? accent! : Color.gray.opacity(0.5)))
            )
            .background(RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color.black)
                .stroke(accent ?? Color.accent)
                .shadow(color: accent ?? Color.accent, radius: 3))
    }
    
    func alertStyle() -> some View {
        self
            .padding()
            .notificationStyle()
            .padding(.horizontal, 60)
    }
}

fileprivate struct NoSpaceModifier: ViewModifier {
    @Binding private var text: String
    
    init(_ text: Binding<String>) {
        self._text = text
    }
    
    func body(content: Content) -> some View {
        content
            .onChange(of: text) {
                if text.contains(" ") {
                    text = text.replacingOccurrences(of: " ", with: "")
                }
            }
    }
}

final class KeyboardManager: ObservableObject {
    static let shared = KeyboardManager()
    
    @Published private(set) var keyboardHeight: CGFloat = .zero
    var isZero: Bool {
        if keyboardHeight == .zero {
            return true
        } else {
            return false
        }
    }
    
    private init() {
        addKeyboardObservers()
    }
    
    private func addKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                DispatchQueue.main.async {
                    withAnimation {
                        self.keyboardHeight = keyboardFrame.height
                    }
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            DispatchQueue.main.async {
                withAnimation {
                    self.keyboardHeight = .zero
                }
            }
        }
    }
}

private struct RotatingModifier: ViewModifier {
    @State private var rotation: Double = 0
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .onAppear() {
                withAnimation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
            .onDisappear() {
                withAnimation(Animation.easeInOut(duration: 1)) {
                    rotation = 0
                }
            }
    }
}

extension View {
    func navigationDestination(in namespace: Namespace.ID, selectedUser: Binding<User?>, navigationPath: Binding<[NavigationSelectionNode]>) -> some View {
        self.modifier(NavigationDestination(namespace: namespace, selectedUser: selectedUser, navigationPath: navigationPath))
    }

    func transitionSource(id: UUID, namespace: Namespace.ID) -> some View {
        self.modifier(TransitionSourceModifier(id: id, namespace: namespace))
    }
}

private struct NavigationDestination: ViewModifier {
    var namespace: Namespace.ID
    @Binding var selectedUser: User?
    @Binding var navigationPath: [NavigationSelectionNode]
    
    @EnvironmentObject private var timetableManager: TimetableManager
    
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: NavigationSelectionNode.self) { node in
                switch node {
                case .user(let id):
                    if let user = timetableManager.users.first(where: { $0.id == id }) {
                        UserDetailView(user: user, selectedUser: $selectedUser, navigationPath: $navigationPath).navigationTransition(.zoom(sourceID: user.id, in: namespace))
                    } else {
                        ContentUnavailableView {
                            Label("Operazione fallita", systemImage: "person")
                        } description: {
                            Text("Questo utente non è disponibile")
                        } actions: {
                            Button {
                                guard navigationPath.popLast() != nil else { return }
                            } label: {
                                Label("Indietro", systemImage: "chevron.backward")
                            }
                        }
                        .navigationTransition(.zoom(sourceID: id, in: namespace))
                        .navigationTitle("Errore")
                    }
                case .subject(let id):
                    if false {
                        
                    } else {
                        ContentUnavailableView {
                            Label("Operazione fallita", systemImage: "graduationcap")
                        } description: {
                            Text("Questa materia non è disponibile")
                        } actions: {
                            Button {
                                guard navigationPath.popLast() != nil else { return }
                            } label: {
                                Label("Indietro", systemImage: "chevron.backward")
                            }
                        }
                        .navigationTransition(.zoom(sourceID: id, in: namespace))
                        .navigationTitle("Errore")
                    }
                case .home(let id):
                    if let home = Selectors.selectors.first(where: { $0.id == id }) {
                        ReviewDetailView(selector: home, namespace: namespace)
                            .environmentObject(timetableManager)
                            .navigationTransition(.zoom(sourceID: home.id, in: namespace))
                    } else {
                        ContentUnavailableView {
                            Label("Operazione fallita", systemImage: "filemenu.and.selection")
                        } description: {
                            Text("Questa selezione non è disponibile")
                        } actions: {
                            Button {
                                guard navigationPath.popLast() != nil else { return }
                            } label: {
                                Label("Indietro", systemImage: "chevron.backward")
                            }
                        }
                        .navigationTransition(.zoom(sourceID: id, in: namespace))
                        .navigationTitle("Errore")
                    }
                case .timetable(let id):
                    if false {
                        
                    } else {
                        ContentUnavailableView {
                            Label("Operazione fallita", systemImage: "graduationcap")
                        } description: {
                            Text("Questa materia non è disponibile")
                        } actions: {
                            Button {
                                guard navigationPath.popLast() != nil else { return }
                            } label: {
                                Label("Indietro", systemImage: "chevron.backward")
                            }
                        }
                        .navigationTransition(.zoom(sourceID: id, in: namespace))
                        .navigationTitle("Errore")
                    }
                }
            }
    }
}

private struct TransitionSourceModifier: ViewModifier {
    var id: UUID
    var namespace: Namespace.ID
    
    func body(content: Content) -> some View {
        content
            .matchedTransitionSource(id: id, in: namespace) { src in
                src
                    .clipShape(.rect(cornerRadius: 45, style: .continuous))
                    .background(Color.accent)
            }
    }
}
