//
//  TimetableManager.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 30/04/25.
//

import SwiftUI

class TimetableManager: ObservableObject {
    static let shared = TimetableManager()
    
    @Published private(set) var timetable: Timetable?
    @Published private(set) var teacherModelsSet: [UserModel] = []
    @Published private(set) var subjectModelsSet: [SubjectModel] = []
    @Published private(set) var isLoading: Bool = false
    
    private init() {}
    
    func fetchUsers() async {
        guard !isLoading, let student = UserManager.shared.mainUser?.user as? Student, student.classe != timetable?.classe else { return }
        await MainActor.run {
            isLoading = true
        }
        do {
            try await getUsers()
        } catch {
            if let err = mapError(error) {
                Utility.setupAlert(err.notification)
            }
        }
        await MainActor.run {
            isLoading = false
        }
    }
    
    @MainActor
    private func getUsers() async throws {
        self.timetable = try await UserManager.shared.getTimetable()
        teacherModelsSet = getOrderedSetTeacherModels(from: self.timetable!)
        subjectModelsSet = getOrderedSetSubjects(from: self.timetable!)
    }
    
    private func getOrderedSetTeacherModels(from timetable: Timetable) -> [UserModel] {
        var seen = Set<Teacher>()
        var orderedTeachers: [UserModel] = []
        
        for entry in timetable.TimetableEntries {
            for teacher in entry.teachers ?? [] {
                if !seen.contains(teacher) {
                    seen.insert(teacher)
                    let userModel = UserModel(user: teacher, role: Roles.teacher)
                    Task {
                        do {
                            try await userModel.fetchProfileImage()
                        } catch {
                            if let err = mapError(error) {
                                Utility.setupAlert(err.notification)
                            }
                        }
                    }
                    orderedTeachers.append(userModel)
                }
            }
        }
        return orderedTeachers
    }
    
    private func getOrderedSetSubjects(from timetable: Timetable) -> [SubjectModel] {
        var seen = Set<SubjectModel>()
        var orderedSubjects: [SubjectModel] = []
        
        for entry in timetable.TimetableEntries {
            for subject in entry.subjectModels {
                if !seen.contains(subject) {
                    seen.insert(subject)
                    orderedSubjects.append(SubjectModel(slef: subject))
                }
            }
        }
        return orderedSubjects
    }
}
