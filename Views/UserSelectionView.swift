//
//  UserSelectionView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 04/02/25.
//

import SwiftUI

struct UserSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    
    let response: [LogInResponse.RoleGroup]
    let onDismiss: (UUID) -> Void
    
    init(_ response: [LogInResponse.RoleGroup], onDismiss: @escaping (UUID) -> Void) {
        self.response = response
        self.onDismiss = onDismiss
    }
    
    @State private var selectedUser: UserModel?
    @State private var sheetUser: UserModel?

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
                    ForEach(response) { roleGroup in
                        Section {
                            if roleGroup.userModels.isEmpty {
                                Text("No users in this role").body()
                            } else {
                                ForEach(roleGroup.userModels) { userModel in
                                    HStack {
                                        VStack {
                                            Text(userModel.user.username).body()
                                            Text(userModel.user.username).body()
                                            Text(userModel.user.username).body()
                                            Text(userModel.user.username).body()
                                            Text(userModel.user.username).body()
                                        }
                                        CircularProfileImage(userIdentity: AnyUser(for: userModel))
                                        if selectedUser == userModel {
                                            Spacer()
                                            Image(systemName: "checkmark.circle")
                                                .foregroundStyle(.green)
                                                .font(.system(size: 25, weight: .heavy))
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(25)
                                    .notificationStyle(selectedUser == userModel ? Color.green : nil)
                                    .onTapGesture {
                                        selectedUser = (selectedUser == userModel) ? nil : userModel
                                    }
                                    .onLongPressGesture {
                                        sheetUser = userModel
                                        HapticFeedback.trigger(HapticFeedback.HapticType.impact(style: .heavy))
                                    }
                                    .sheet(item: $sheetUser) { user in
                                        UserDetailsView(user: user.user).presentationDragIndicator(.visible)
                                    }
                                }
                            }
                        } header: {
                            Text(String(localized: roleGroup.role.description).uppercased())
                                .title(30, .heavy)
                        }
                        CommonSpacer(50)
                    }
                    Button {
                        if let userUUID = selectedUser?.user.id {
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
        .onAppear {
            HapticFeedback.trigger(HapticFeedback.HapticType.impact(style: UIImpactFeedbackGenerator.FeedbackStyle.rigid))
        }
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
                switch user {
                case let student as Student:
                    Text("Name: \(student.name) \(student.surname)")
                    Text("Username: \(student.username)")
                    Text("Class: \(student.classe.name) (ID: \(student.classe.id))")
                    Text("Study Field: \(student.studyFieldName)")
                case let teacher as Teacher:
                    Text("Name: \(teacher.name) \(teacher.surname)")
                    Text("Username: \(teacher.username)")
                    Text("Role: \(Roles.isRole(user).description)")
                case let admin as Admin:
                    Text("Name: \(admin.name) \(admin.surname)")
                    Text("Username: \(admin.username)")
                    Text("Role: Admin")
                case let principal as Principal:
                    Text("Name: \(principal.name) \(principal.surname)")
                    Text("Username: \(principal.username)")
                    Text("Role: Principal")
                case let secretariat as Secretariat:
                    Text("Name: \(secretariat.name) \(secretariat.surname)")
                    Text("Username: \(secretariat.username)")
                    Text("Role: Secretariat")
                case let user:
                    Text("Name: \(user.name) \(user.surname)")
                    Text("Username: \(user.username)")
                    Text("Role: User")
                }
            }
            .padding()
        }
    }
}
