//
//  UserSelection.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 22/02/25.
//

import SwiftUI
                            
struct UsersListView: ListView {
    let title: LocalizedStringResource
    let namespace: Namespace.ID
    
    @EnvironmentObject private var timetableManager: TimetableManager
    
    init(title: LocalizedStringResource, namespace: Namespace.ID) {
        self.title = title
        self.namespace = namespace
    }
    
    var body: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: [GridItem(), GridItem()]) {
                    ForEach(timetableManager.teacherModelsSet) { userModel in
                        NavigationLink(value: NavigationSelectionNode.teacher(id: userModel.user.id)) {
                            UserModelPosterCard(for: userModel)
                        }
                        .accessibilityLabel(userModel.user.username)
                        .transitionSource(id: userModel.user.id, namespace: namespace)
                        .hoverEffect()
                    }
                }.padding(.horizontal)
            }
        } header: {
            Text(title)
                .title(30)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
    }
}

struct UserDetailView: SelectionDetailView {
    @Binding private var selectedUser: UserModel?
    @Binding var navigationPath: [NavigationSelectionNode]
    private let userModel: UserModel
    
    init(user: UserModel, selectedUser: Binding<UserModel?>, navigationPath: Binding<[NavigationSelectionNode]>) {
        self.userModel = user
        self._selectedUser = selectedUser
        self._navigationPath = navigationPath
    }
    
    var body: some View {
        VStack {
            ProfileView(for: AnyUser(for: userModel))
            Button {
                selectedUser = userModel
                navigationPath.removeAll()
            } label: {
                Text("Seleziona").textButtonStyle(true)
            }
            Spacer()
        }
    }
    
    func popViewsWithAnimation() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
            if navigationPath.isEmpty {
                timer.invalidate()
            } else {
                navigationPath.removeLast()
            }
        }
    }
}

struct UserModelPosterCard: View {
    @ObservedObject var userModel: UserModel
    
    init(for userModel: UserModel) {
        self.userModel = userModel
    }
    
    var body: some View {
        HStack(alignment: .center) {
            CircularProfileImage(userIdentity: AnyUser(for: userModel))
            Spacer()
            VStack {
                Text(userModel.user.surname).body()
                Text(userModel.user.name).body()
            }
            .frame(maxWidth: 200)
            .foregroundStyle(Color.white)
            .lineLimit(1)
            Spacer()
        }
        .padding(.trailing)
    }
}

//struct CustomButtonStyle: PrimitiveButtonStyle {
//    
//    func makeBody(configuration: Configuration) -> some View {
//        Button(configuration)
//            .buttonStyle(.bordered)
//            .buttonBorderShape(.capsule)
//            .fontWeight(.medium)
//            .controlSize(.regular)
//    }
//}
