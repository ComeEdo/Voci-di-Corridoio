//
//  PostNavigationController.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 30/04/25.
//

import SwiftUI

extension View {
    func navigationDestination(in namespace: Namespace.ID, selectedUser: Binding<UserModel?>, selectedSubject: Binding<SubjectModel?>, selectedTimetableEntry: Binding<TimetableEntry?>, navigationPath: Binding<[NavigationSelectionNode]>) -> some View {
        self.modifier(NavigationDestination(namespace: namespace, selectedUser: selectedUser, selectedSubject: selectedSubject, selectedTimetableEntry: selectedTimetableEntry, navigationPath: navigationPath))
    }
    func transitionSource(id: UUID, namespace: Namespace.ID) -> some View {
        self.modifier(TransitionSourceModifier(id: id, namespace: namespace))
    }
}

private struct NavigationDestination: ViewModifier {
    private let namespace: Namespace.ID
    @Binding private var selectedUser: UserModel?
    @Binding private var selectedSubject: SubjectModel?
    @Binding private var selectedTimetableEntry: TimetableEntry?
    @Binding private var navigationPath: [NavigationSelectionNode]
    
    @EnvironmentObject private var timetableManager: TimetableManager
    
    init(namespace: Namespace.ID, selectedUser: Binding<UserModel?>, selectedSubject: Binding<SubjectModel?>, selectedTimetableEntry: Binding<TimetableEntry?>, navigationPath: Binding<[NavigationSelectionNode]>) {
        self.namespace = namespace
        self._selectedUser = selectedUser
        self._selectedSubject = selectedSubject
        self._selectedTimetableEntry = selectedTimetableEntry
        self._navigationPath = navigationPath
    }
    
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: NavigationSelectionNode.self) { node in
                switch node {
                case .teacher(id: let id):
                    if let userModel = timetableManager.teacherModelsSet.first(where: { $0.id == id }) {
                        UserDetailView(user: userModel, selectedUser: $selectedUser, navigationPath: $navigationPath).navigationTransition(.zoom(sourceID: userModel.user.id, in: namespace))
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
                case .subject(id: let id, hash: let hash):
                    if let subject = timetableManager.subjectModelsSet.first(where: { $0.hashValue == hash }) {
                        SubjectDetailView(subjectModel: subject, selectedSubject: $selectedSubject, navigationPath: $navigationPath)
                            .navigationTransition(.zoom(sourceID: id, in: namespace))
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
                case .home(id: let id):
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
                case .timetable(id: let id, date: let date):
                    if let entry = timetableManager.timetable?.TimetableEntries.first(where: { $0.id == id }) {
                        TimetableEntryDetailView(timetableEntry: TimetableEntry(timetableEntry: entry, date: date), selectedTimetableEntry: $selectedTimetableEntry, navigationPath: $navigationPath)
                            .environmentObject(timetableManager)
                            .navigationTransition(.zoom(sourceID: id, in: namespace))
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

protocol SelectionDetailView: View {
    var navigationPath: [NavigationSelectionNode] { get set }
    
    func popViewsWithAnimation()
}

struct TransitionSourceModifier: ViewModifier {
    var id: UUID
    var namespace: Namespace.ID
    
    func body(content: Content) -> some View {
        content
            .matchedTransitionSource(id: id, in: namespace) { src in
                src
                    .clipShape(.rect(cornerRadius: 50, style: .circular))
                    .background(Color.accentColor)
            }
    }
}
