//
//  UserSelectionView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 04/02/25.
//

import SwiftUI

struct UserSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    
    let response: [LoginResponse.RoleGroup]
    let onDismiss: (UUID) -> Void
    
    init(_ response: [LoginResponse.RoleGroup], onDismiss: @escaping (UUID) -> Void) {
        self.response = response
        self.onDismiss = onDismiss
    }
    
    @State private var selectedUser: User?
    @State private var sheetUser: User?
    
    private func roleTitle(for roleId: Int) -> String {
        return String(localized: Roles.from(roleId).description).uppercased()
    }
    
    var body: some View {
        ZStack {
            ColorGradient()
            VStack {
                GradientView(style: .black, height: 100, startPoint: .top).opacity(0.6)
                Spacer()
            }
            .ignoresSafeArea(edges: .top)
            .zIndex(30)
            TitleOnView("Seleziona Utente")
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading) {
                    ForEach(response, id: \.roleId) { roleGroup in
                        Section(header: Text(roleTitle(for: roleGroup.roleId))
                            .title(30, .heavy)
                        ) {
                            if roleGroup.users.isEmpty {
                                Text("No users in this role").body()
                            } else {
                                ForEach(roleGroup.users, id: \.id) { user in
                                    HStack {
                                        VStack {
                                            Text(user.username).body()
                                            Text(user.username).body()
                                            Text(user.username).body()
                                            Text(user.username).body()
                                            Text(user.username).body()
                                        }
                                        if selectedUser?.id == user.id {
                                            Spacer()
                                            Image(systemName: "checkmark.circle")
                                                .foregroundStyle(.green)
                                                .font(.system(size: 25, weight: .heavy))
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(25)
                                    .notificationStyle(selectedUser?.id == user.id ? Color.green : nil)
                                    .onTapGesture {
                                        selectedUser = (selectedUser?.id == user.id) ? nil : user
                                    }
                                    .onLongPressGesture {
                                        sheetUser = user
                                        HapticFeedback.trigger(HapticFeedback.HapticType.impact(style: .heavy))
                                    }
                                    .sheet(item: $sheetUser) { user in
                                        UserDetailsView(user: user)
                                    }
                                }
                            }
                        }
                        CommonSpacer(50)
                    }
                    Button {
                        if let userUUID = selectedUser?.id {
                            onDismiss(userUUID)
                        }
                        dismiss()
                    } label: {
                        Text("Confirm").textButtonStyle(selectedUser != nil)
                    }
                    .disabled(selectedUser == nil)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding()
            }
        }
        .toolbarBackground(.hidden)
    }
}

struct UserDetailsView: View {
    let user: User
    
    var body: some View {
        ZStack {
            ColorGradient()
            VStack {
                Text("User Details")
                    .font(.largeTitle)
                    .padding()
                switch Roles.isRole(user) {
                case .student:
                    if let student = user as? Student {
                        Text("Name: \(student.name) \(student.surname)")
                        Text("Username: \(student.username)")
                        Text("Class: \(student.classe.name) (ID: \(student.classe.id))")
                        Text("Study Field: \(student.studyFieldName)")
                    }
                case .teacher:
                    if let teacher = user as? Teacher {
                        Text("Name: \(teacher.name) \(teacher.surname)")
                        Text("Username: \(teacher.username)")
                        Text("Role: \(Roles.isRole(user).description)")
                    }
                case .admin:
                    Text("Name: \(user.name) \(user.surname)")
                    Text("Username: \(user.username)")
                    Text("Role: Admin")
                case .principal:
                    Text("Name: \(user.name) \(user.surname)")
                    Text("Username: \(user.username)")
                    Text("Role: Principal")
                case .secretariat:
                    Text("Name: \(user.name) \(user.surname)")
                    Text("Username: \(user.username)")
                    Text("Role: Secretariat")
                case .user:
                    Text("Name: \(user.name) \(user.surname)")
                    Text("Username: \(user.username)")
                    Text("Role: User")
                }
            }
            .padding()
        }
    }
}
