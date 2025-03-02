//
//  Testing.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 22/02/25.
//

import SwiftUI

enum NavigationNode: Equatable, Hashable, Identifiable {
    case home(UUID)
    case user(UUID)
    case subject(UUID)
    
    var id: UUID {
        switch self {
        case .user(let id): id
        case .subject(let id): id
        case .home(let id): id
        }
    }
}
struct Selectors {
    static let selectors = [Selectorr(image: Image(decorative: "ProfImage"), title: "Professori", node: .user(UUID())), Selectorr(image: Image(decorative: "SubjectImage"), title: "Materie", node: .subject(UUID()))]
    
    struct Selectorr: Identifiable {
        let id: UUID
        let image: Image
        let title: LocalizedStringResource
        let node: NavigationNode
        
        init(image: Image, title: LocalizedStringResource, node: NavigationNode) {
            self.image = image
            self.title = title
            self.id = UUID()
            self.node = node
        }
    }
}
                            
struct UsersListView: View {
    private let title: LocalizedStringResource
    private let namespace: Namespace.ID
    
    init(title: LocalizedStringResource, namespace: Namespace.ID) {
        self.title = title
        self.namespace = namespace
    }
    
    var body: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(TimetableManager.shared.users) { user in
                        NavigationLink(value: NavigationNode.user(user.id)) {
                            PosterCard(image: Image(decorative: "using"), surname: user.surname, name: user.name).hoverEffect()
                                .padding(.bottom, 10)
                        }
                        .frame(height: 300)
                        .accessibilityLabel(user.username)
                        .transitionSource(id: user.id, namespace: namespace)
                    }
                }.padding(.leading)
            }
        } header: {
            Text(title)
                .title(30)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
    }
}

struct ReviewSelectionView: View {
    private let title: LocalizedStringResource
    private let namespace: Namespace.ID
    
    init(title: LocalizedStringResource, namespace: Namespace.ID) {
        self.title = title
        self.namespace = namespace
    }
    
    var body: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(Selectors.selectors) { selector in
                        NavigationLink(value: NavigationNode.home(selector.id)) {
                            SelectorCard(image: selector.image, title: selector.title).hoverEffect().padding(.bottom, 10)
                        }
                        .frame(height: 180)
                        .accessibilityLabel(String(localized: selector.title))
                        .transitionSource(id: selector.id, namespace: namespace)
                    }
                }.padding(.leading)
            }
        } header: {
            Text(title)
                .title(30)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
    }
}

struct bb: View {
    private let namespace: Namespace.ID
    @EnvironmentObject private var timetableManager: TimetableManager
    
    init(namespace: Namespace.ID) {
        self.namespace = namespace
    }
    
    var body: some View {
        VStack {
            if timetableManager.isLoading {
                ProgressView()
            } else if timetableManager.users.isEmpty {
                ContentUnavailableView("This video isn’t available", systemImage: "list.and.film")
                Button("Retry") {
                    timetableManager.fetchUsers()
                }
            } else {
                ReviewSelectionView(title: "Recensire", namespace: namespace)
            }
        }
    }
}

struct UserDetailView: View {
    @Binding private var selectedUser: User?
    @Binding private var navigationPath: [NavigationNode]
    private let user: User
    
    init(user: User, selectedUser: Binding<User?>, navigationPath: Binding<[NavigationNode]>) {
        self.user = user
        self._selectedUser = selectedUser
        self._navigationPath = navigationPath
    }
    
    var body: some View {
        VStack {
            Text(user.name)
            Text(user.surname)
            Text(user.username)
            Button {
                selectedUser = user
                popViewsWithAnimation()
            } label: {
                Text("Seleziona").textButtonStyle(true)
            }
        }
        .navigationTitle(user.username)
    }
    
    private func popViewsWithAnimation() {
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

struct ReviewDetailView: View {
    private let selector: Selectors.Selectorr
    private var namespace: Namespace.ID
    
    init(selector: Selectors.Selectorr, namespace: Namespace.ID) {
        self.selector = selector
        self.namespace = namespace
    }
    var body: some View {
        ScrollView {
            switch selector.node {
            case .user:
                UsersListView(title: selector.title, namespace: namespace)
            case .subject:
                Text("subject")
            case .home:
                ReviewSelectionView(title: selector.title, namespace: namespace)
            }
        }
        .navigationTitle(String(localized: selector.title))
    }
}

struct PosterCard: View {
    private let image: Image
    private let surname: String
    private let name: String
    
    init(image: Image, surname: String, name: String) {
        self.image = image
        self.surname = surname
        self.name = name
    }
    
    var body: some View {
        VStack {
            image
                .resizable()
                .scaledToFill()
            Text("\(surname)\n\(name)")
                .body()
                .foregroundStyle(Color.white)
                .lineLimit(2)
        }
    }
}

struct SelectorCard: View {
    private let image: Image
    private let title: LocalizedStringResource
    
    init(image: Image, title: LocalizedStringResource) {
        self.image = image
        self.title = title
    }
    
    var body: some View {
        VStack {
            image
                .resizable()
                .scaledToFill()
            Text(title)
                .body()
                .foregroundStyle(Color.white)
                .lineLimit(2)
        }
    }
}

struct CustomButtonStyle: PrimitiveButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        Button(configuration)
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .fontWeight(.medium)
            .controlSize(.regular)
    }
}

class TimetableManager: ObservableObject {
    static let shared = TimetableManager()
    
    @Published private(set) var timetable: Timetable?
    @Published private(set) var users: [User] = []
    @Published private(set) var isLoading: Bool = false
    
    //    func getAllTeachers(from timetableEntries: Set<TimetableEntry>) -> [Teacher] {
    //        let uniqueTeachers = Set(timetableEntries.compactMap { $0.teachers }.flatMap { $0 })
    //        return Array(uniqueTeachers)
    //    }
        
    //    func getUniqueTeachers(from entry: TimetableEntry) -> [Teacher] {
    //        guard let teachers = entry.teachers else { return [] }
    //        let uniqueTeachers = Array(Set(teachers))
    //        return uniqueTeachers
    //    }
    
    @MainActor
    private func getUsers() async throws {
        let timetable = try await UserManager.shared.getTimetable()
        self.timetable = timetable
        users = getAllTeachers(from: timetable)
    }
    
//    private func getAllTeachers(from timetable: Timetable) -> [Teacher] {
//        let allTeachers = timetable.TimetableEntrys.flatMap { $0.teachers ?? [] }
//        return Array(Set(allTeachers))
//    }
    
    private func getAllTeachers(from timetable: Timetable) -> [Teacher] {
        var seen = Set<Teacher>()
        var orderedTeachers: [Teacher] = []
        
        for entry in timetable.TimetableEntrys {
            for teacher in entry.teachers ?? [] {
                if !seen.contains(teacher) {
                    seen.insert(teacher)
                    orderedTeachers.append(teacher)
                }
            }
        }
        return orderedTeachers
    }
    
    func fetchUsers() {
        Task {
            await MainActor.run {
                isLoading = true
            }
            await UserManager.shared.waitUntilAuthLoadingCompletes()
            do {
                try await getUsers()
            } catch let error as ServerError {
                if error == .sslError {
                    SSLAlert(error.notification)
                } else {
                    Utility.setupAlert(error.notification)
                }
            } catch let error as Notifiable {
                Utility.setupAlert(error.notification)
            } catch {
                print(error.localizedDescription)
                Utility.setupAlert(MainNotification.NotificationStructure(title: "Errore", message: "\(error.localizedDescription)", type: .error))
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private init() {
        fetchUsers()
    }
}
