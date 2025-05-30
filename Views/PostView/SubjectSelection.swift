//
//  SubjectSelection.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 30/04/25.
//

import SwiftUI

struct SubjectsListView: ListView {
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
                    ForEach(timetableManager.subjectModelsSet) { subjectModel in
                        NavigationLink(value: NavigationSelectionNode.subject(id: subjectModel.id, hash: subjectModel.hashValue)) {
                            SubjectPosterCard(for: subjectModel)
                        }
                        .accessibilityLabel(String(localized: subjectModel.subject.name))
                        .transitionSource(id: subjectModel.id, namespace: namespace)
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

struct SubjectDetailView: SelectionDetailView {
    @Binding private var selectedSubject: SubjectModel?
    @Binding var navigationPath: [NavigationSelectionNode]
    private let subjectModel: SubjectModel
    
    init(subjectModel: SubjectModel, selectedSubject: Binding<SubjectModel?>, navigationPath: Binding<[NavigationSelectionNode]>) {
        self.subjectModel = subjectModel
        self._selectedSubject = selectedSubject
        self._navigationPath = navigationPath
    }
    
    var body: some View {
        VStack {
            ZStack(alignment: .bottomLeading) {
                subjectModel.subject.image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 300, height: 300)
                    .fixedSize(horizontal: true, vertical: true)
                    .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                SubjectTagView(for: subjectModel, weight: .bold)
                    .foregroundStyle(Color.white)
                    .padding([.leading, .bottom])
            }
            Button {
                selectedSubject = subjectModel
                navigationPath.removeAll()
            } label: {
                Text("Seleziona").textButtonStyle(true)
            }
            Spacer()
        }.navigationTitle(String(localized: subjectModel.subject.name))
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

struct SubjectPosterCard: View {
    let subjectModel: SubjectModel
    
    init(for subjectModel: SubjectModel) {
        self.subjectModel = subjectModel
    }
    
    var body: some View {
        HStack(alignment: .center) {
            subjectModel.subject.image
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .fixedSize(horizontal: true, vertical: true)
                .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
            Spacer()
            VStack(alignment: .leading) {
                Text(subjectModel.subject.name).body()
                SubjectTagView(for: subjectModel)
            }
            .frame(maxWidth: 200)
            .foregroundStyle(Color.white)
            .lineLimit(1)
            Spacer()
        }
        .padding(.trailing)
    }
}

struct SubjectTagView: View {
    let subjectModel: SubjectModel
    let weight: Font.Weight
    
    init(for subjectModel: SubjectModel, weight: Font.Weight? = nil) {
        self.subjectModel = subjectModel
        self.weight = weight ?? .regular
    }
    var body: some View {
        HStack(spacing: 8) {
            if subjectModel.isLaboratory {
                Text("Laboratorio").textTag(weight: weight)
            }
        }
    }
}

#Preview("DetailView") {
    SubjectDetailView(
        subjectModel: SubjectModel(subject: .informatica, isLaboratory: true),
        selectedSubject: .constant(nil),
        navigationPath: .constant([])
    )
}
