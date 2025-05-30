//
//  ArgumentSelectionView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 30/04/25.
//

import SwiftUI

enum NavigationSelectionNode: Hashable {
    case teacher(id: UUID)
    case subject(id: UUID, hash: Int)
    case timetable(id: UUID, date: Date)
    case home(id: UUID)
}

struct ArgumentSelectionView: ViewConnectionable {
    let namespace: Namespace.ID
    
    @EnvironmentObject private var timetableManager: TimetableManager
    
    init(namespace: Namespace.ID) {
        self.namespace = namespace
    }
    
    var body: some View {
        VStack {
            if timetableManager.isLoading {
                ProgressView()
            } else if timetableManager.teacherModelsSet.isEmpty {
                ContentUnavailableView {
                    Label("Operazione fallita", systemImage: "cup.and.heat.waves")
                } description: {
                    Text("Non è stato possibile caricare gli utenti")
                } actions: {
                    Button("Retry") {
                        Task {
                            await timetableManager.fetchUsers()
                        }
                    }
                }
            } else {
                ReviewSelectionView(namespace: namespace)
            }
        }
    }
}

struct ReviewSelectionView: ViewConnectionable {
    let namespace: Namespace.ID
    
    @EnvironmentObject private var timetableManager: TimetableManager
    
    init(namespace: Namespace.ID) {
        self.namespace = namespace
    }
    
    var body: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(Selectors.selectors) { selector in
                        NavigationLink(value: NavigationSelectionNode.home(id: selector.id)) {
                            SelectorCard(image: selector.image, title: selector.title)
                        }
                        .frame(height: 180)
                        .accessibilityLabel(String(localized: selector.title))
                        .matchedTransitionSource(id: selector.id, in: namespace) { src in
                            src
                                .clipShape(.rect(cornerRadius: 50, style: .continuous))
                                .background(Color.accent)
                        }
                        .hoverEffect()
                    }
                }.padding(.horizontal)
            }
        } header: {
            Text("Classe")
                .title(30)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
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
                .scaledToFit()
            Text(title)
                .body()
                .foregroundStyle(Color.white)
                .lineLimit(2)
        }
        .padding(.bottom, 10)
    }
}

struct ReviewDetailView: View {
    private let selector: Selectors.Selector
    private var namespace: Namespace.ID
    
    @EnvironmentObject private var timetableManager: TimetableManager
    
    init(selector: Selectors.Selector, namespace: Namespace.ID) {
        self.selector = selector
        self.namespace = namespace
    }
    
    var body: some View {
        switch selector.node {
        case .teacher:
            let timetable: TimetableEntry? = nowTimetable()
            ScrollView(showsIndicators: false) {
                if let teachers = timetable?.teachers, !teachers.isEmpty {
                    let userModelMap = Dictionary(uniqueKeysWithValues: timetableManager.teacherModelsSet.map { ($0.user.id, $0) })
                    HeroViewUserModel(namespace: namespace, userModels: teachers.compactMap { userModelMap[$0.id] })
                }
                UsersListView(title: selector.title, namespace: namespace).environmentObject(timetableManager)
                ReviewSelectionView(namespace: namespace)
            }
            .ignoresSafeArea(!(timetable?.teachers?.isEmpty ?? true) ? .all : [], edges: .top)
            .toolbarBackground(!(timetable?.teachers?.isEmpty ?? true) ? .hidden : .automatic)
            .navigationTitle("")
        case .subject:
            let timetable: TimetableEntry? = nowTimetable()
            ScrollView(showsIndicators: false) {
                if let subjectModels = timetable?.subjectModels, !subjectModels.isEmpty {
                    HeroViewSubjectModel(namespace: namespace, subjectModels: subjectModels)
                }
                SubjectsListView(title: selector.title, namespace: namespace).environmentObject(timetableManager)
                ReviewSelectionView(namespace: namespace)
            }
            .ignoresSafeArea(!(timetable?.subjectModels.isEmpty ?? true) ? .all : [], edges: .top)
            .toolbarBackground(!(timetable?.subjectModels.isEmpty ?? true) ? .hidden : .automatic)
            .navigationTitle("")
        case .timetable:
            TimetableView(namespace: namespace)
                .navigationTitle(String(localized: selector.title))
                .navigationBarTitleDisplayMode(.large)
        case .home:
            ScrollView {
                ReviewSelectionView(namespace: namespace)
            }.navigationTitle(String(localized: selector.title))
        }
    }
    
    private func nowTimetable() -> TimetableEntry? {
        let now = Date.now
        guard let today = WeekDay(calendarWeekday: Calendar.current.component(.weekday, from: now)), let allEntries = timetableManager.timetable?.TimetableEntries else { return nil }
//        let startTimeString = "08:00:00"
//        let endTimeString = "10:00:00"
//        
//        
//        let subjectModels: [SubjectModel] = [
//            SubjectModel(subject: .informatica, isLaboratory: true),
//            SubjectModel(subject: .ricreazione, isLaboratory: false),
//            SubjectModel(subject: .matematica, isLaboratory: false)
//        ]
//        
//        let timetableEntry = TimetableEntry(weekDay: .monday, startTime: startTimeString, endTime: endTimeString, subjectModels: subjectModels, teachers: nil)
//        print(timetableEntry ?? "nil")
//        
//        return timetableEntry
//        return allEntries.filter { $0.weekDay == .friday }[2]   // just for testing
        return allEntries.lazy.filter { entry in
            guard entry.weekDay == today, let startToday = now.settingTime(from: entry.startTime), let endToday = now.settingTime(from: entry.endTime) else {
                return false
            }
            return startToday <= now && now <= endToday
        }.max { lhs, rhs in
            if lhs.startTime != rhs.startTime {
                return lhs.startTime < rhs.startTime
            }
            return lhs.endTime < rhs.endTime
        }
    }
}
