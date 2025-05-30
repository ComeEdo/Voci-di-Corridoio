//
//  HeroViews.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 30/04/25.
//

import SwiftUI

struct HeroViewUserModel: ViewConnectionable {
    let namespace: Namespace.ID
    let userModels: [UserModel]
    
    init(namespace: Namespace.ID, userModels: [UserModel]) {
        self.namespace = namespace
        self.userModels = userModels
    }
    init(namespace: Namespace.ID, userModel: UserModel) {
        self.namespace = namespace
        self.userModels = [userModel]
    }
    
    var body: some View {
        InfinitePageView(pages: userModels.map { userModel in
            NavigationLink(value: NavigationSelectionNode.teacher(id: userModel.user.id)) {
                ZStack(alignment: .bottom) {
                    Image("HeroViewProfessorImage")
                        .resizable()
                        .scaledToFill()
                        .frame(maxHeight: UIScreen.main.bounds.height * 125 / 213, alignment: .top)
                        .clipped()
                    GradientView(style: .black.opacity(0.6), startPoint: .bottom)
                    UserModelPosterCard(for: userModel).padding([.horizontal, .bottom])
                }
            }.transitionSource(id: userModel.user.id, namespace: namespace)
        })
    }
}

struct HeroViewSubjectModel: ViewConnectionable {
    let namespace: Namespace.ID
    let subjectModels: [SubjectModel]
    
    init(namespace: Namespace.ID, subjectModels: [SubjectModel]) {
        self.namespace = namespace
        self.subjectModels = subjectModels
    }
    init(namespace: Namespace.ID, subjectModel: SubjectModel) {
        self.namespace = namespace
        self.subjectModels = [subjectModel]
    }
    
    var body: some View {
        InfinitePageView(pages: subjectModels.map { subjectModel in
            NavigationLink(value: NavigationSelectionNode.subject(id: subjectModel.id, hash: subjectModel.hashValue)) {
                ZStack(alignment: .bottomLeading) {
                    subjectModel.subject.image
                        .resizable()
                        .scaledToFill()
                        .frame(maxHeight: UIScreen.main.bounds.height * 125 / 213, alignment: .top)
                        .clipped()
                    GradientView(style: .black.opacity(0.6), startPoint: .bottom)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(String(localized: subjectModel.subject.name).uppercased())
                            .title(35)
                        SubjectTagView(for: subjectModel)
                    }
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .padding([.horizontal, .bottom])
                }
            }.transitionSource(id: subjectModel.id, namespace: namespace)
        })
    }
}
