//
//  Selector.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 30/04/25.
//

import SwiftUI

struct Selectors {
    static let selectors = [
        Selector(image: Image("ProfImage"), title: "Professori", node: .teacher(id: UUID())),
        Selector(image: Image("SubjectImage"), title: "Materie", node: .subject(id: UUID(), hash: 0)),
        Selector(image: Image("TimetableImage"), title: "Orario", node: .timetable(id: UUID(), date: Date()))
    ]
    
    struct Selector: Identifiable {
        let id: UUID = UUID()
        let image: Image
        let title: LocalizedStringResource
        let node: NavigationSelectionNode
        
        init(image: Image, title: LocalizedStringResource, node: NavigationSelectionNode) {
            self.image = image
            self.title = title
            self.node = node
        }
    }
}
