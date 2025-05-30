//
//  User.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 05/12/24.
//

import SwiftUI

class User: CustomStringConvertible, Comparable, Codable, Identifiable, Hashable {
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name && lhs.surname == rhs.surname && lhs.username == rhs.username && lhs.profileImageId == rhs.profileImageId
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var description: String {
        return "\(name) \(surname)\nUsername: \(username)"
    }
    
    let id: UUID
    var name: String
    var surname: String
    var username: String
    var profileImageId: UUID?
    
    init(id: UUID, name: String, surname: String, username: String) {
        self.id = id
        self.name = name
        self.surname = surname
        self.username = username
    }
    
    static func < (lhs: User, rhs: User) -> Bool {
        return lhs.username < rhs.username
    }
    
    private enum CodingKeys: String, CodingKey {
        case id = "userId"
        case name = "firstName"
        case surname = "lastName"
        case username = "username"
        case profileImageId = "profileImageId"
    }
}

class Student: User {
//    static func == (lhs: Student, rhs: Student) -> Bool {
//        return lhs as User == rhs as User && lhs.classe == rhs.classe && lhs.studyFieldName == rhs.studyFieldName
//    }
    
    var classe: Classs
    var studyFieldName: String
    
    init(id: UUID, name: String, surname: String, username: String, classe: Classs, studyFieldName: String) {
        self.classe = classe
        self.studyFieldName = studyFieldName
        super.init(id: id, name: name, surname: surname, username: username)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.classe = try container.decode(Classs.self, forKey: .classe)
        self.studyFieldName = try container.decode(String.self, forKey: .studyFieldName)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(classe, forKey: .classe)
        try container.encode(studyFieldName, forKey: .studyFieldName)
        try super.encode(to: encoder)
    }
    
    private enum CodingKeys: String, CodingKey {
        case classe = "class"
        case studyFieldName = "studyFieldName"
    }
    
    override var description: String {
        return super.description + "\nClass: \(classe.name) (ID: \(classe.id))\nStudy Field: \(studyFieldName)"
    }
}

class Teacher: User {
    override var description: String {
        return super.description + "\nRole: Teacher"
    }
}

class Admin: User {}
class Principal: User {}
class Secretariat: User {}

struct SubjectModel: Codable, Hashable, Identifiable {
    let id: UUID = UUID()
    let subject: Subjects
    let isLaboratory: Bool
    
    init(subject: Subjects, isLaboratory: Bool) {
        self.subject = subject
        self.isLaboratory = isLaboratory
    }
    init(slef subjectModel: SubjectModel) {
        self.subject = subjectModel.subject
        self.isLaboratory = subjectModel.isLaboratory
    }
    
    static func ==(lhs: SubjectModel, rhs: SubjectModel) -> Bool {
        lhs.subject == rhs.subject &&
        lhs.isLaboratory == rhs.isLaboratory
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(subject)
        hasher.combine(isLaboratory)
    }
    
    enum CodingKeys: String, CodingKey {
        case subject = "subjectId"
        case isLaboratory = "isLab"
    }
    
    enum Subjects: Int, Codable {
        case matematica         = 1
        case lettere            = 2
        case informatica        = 3
        case tpsit              = 4
        case inglese            = 5
        case educazioneFisica   = 6
        case religione          = 7
        case sistemiEReti       = 8
        case gpoi               = 9
        case tutor              = 10
        case ricreazione        = 11
        case automazione        = 16
        case cnc                = 17
        
        var name: LocalizedStringResource {
            switch self {
            case .matematica: return "Matematica"
            case .lettere: return "Lettere"
            case .informatica: return "Informatica"
            case .tpsit: return "TPSIT"
            case .inglese: return "Inglese"
            case .educazioneFisica: return "Educazione fisica"
            case .religione: return "Religione"
            case .sistemiEReti: return "Sistemi e Reti"
            case .gpoi: return "G.P.O.I"
            case .tutor: return "Tutor"
            case .ricreazione: return "Ricreazione"
            case .automazione: return "Automazione"
            case .cnc: return "CNC"
            }
        }
        
        var description: LocalizedStringResource {
            switch self {
            case .matematica: return "Studio dei numeri, delle equazioni e delle funzioni."
            case .lettere: return "Studi letterari, la grammatica e la cultura delle lingue."
            case .informatica: return "Studio dei concetti e delle tecniche dell'informatica."
            case .tpsit: return "Tecnologie per la produzione di sistemi informatici e telematici."
            case .inglese: return "Studio della lingua e cultura inglese."
            case .educazioneFisica: return "Attività fisica e sportiva per il benessere."
            case .religione: return "Studio delle tradizioni religiose e della loro cultura."
            case .sistemiEReti: return "Studio delle infrastrutture e dei sistemi informatici."
            case .gpoi: return "Gestione e organizzazione di sistemi informatici e reti."
            case .tutor: return "Attività di supporto e assistenza agli studenti."
            case .ricreazione: return "Momento di svago e gioco."
            case .automazione: return "Studio dei processi automatizzati e della loro applicazione industriale."
            case .cnc: return "Studio e gestione delle macchine a controllo numerico per la produzione industriale."
            }
        }
        
        private var stringImage: String {
            switch self {
            case .matematica: return "Matematica"
            case .lettere: return "LettereItaliano"
            case .informatica: return "Informatica"
            case .tpsit: return "TPSIT"
            case .inglese: return "Inglese"
            case .educazioneFisica: return "EducazioneFisica"
            case .religione: return "Religione"
            case .sistemiEReti: return "SistemiReti"
            case .gpoi: return "G.P.O.I"
            case .tutor: return "Tutor"
            case .ricreazione: return "Ricreazione"
            case .automazione: return "Automazione"
            case .cnc: return "CNC"
            }
        }
        
        var image: Image {
            if let uiImage = UIImage(named: stringImage) {
                Image(uiImage: uiImage)
            } else {
                Image("ProfImage")
            }
        }
    }
}
