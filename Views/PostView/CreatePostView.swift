//
//  CreatePostView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 18/02/25.
//

import SwiftUI

class CreatePostOptions: ObservableObject {
    static let shared = CreatePostOptions()
    
    @AppStorage(CreatePostView.RatingView.🔑.rawValue) var ratingView: CreatePostView.RatingView = .picker
    
    private init() {}
}

struct CreatePostView: View {
    enum Field {
        case title
        case content
    }
    
    @FocusState private var focusedField: Field?
    
    @State private var title: String = ""
    @State private var content: String = ""
    private let titleMaxLength: Int = 200
    private let contentMaxLength: Int = 1000
    
    @State private var selectedUser: UserModel? = nil
    @State private var selectedSubject: SubjectModel? = nil
    @State private var selectedTimetableEntry: TimetableEntry? = nil
    
    @Namespace private var namespace
    @State private var navigationPath: [NavigationSelectionNode] = []
    
    @ObservedObject private var timetableManager = TimetableManager.shared
    @ObservedObject private var notificationManager = NotificationManager.shared
    @ObservedObject private var createPostOptions: CreatePostOptions = CreatePostOptions.shared
    
    @State private var mark: Int = 6
    @State private var anonymus: Bool = false
    
    @State private var isPosting: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    
    enum RatingView: String, DefaultPersistenceProtocol, CaseIterable {
        case burger
        case picker
        
        static var 🔑: DefaultPersistence.Saves = .postPicker
        
        static func set(_ newValue: RatingView) {
            UserDefaults.standard.set(newValue.rawValue, forKey: 🔑.rawValue)
            }

        static func current() -> RatingView {
            let stored = UserDefaults.standard.string(forKey: 🔑.rawValue)
            return RatingView(rawValue: stored ?? "") ?? .burger
        }
        
        var description: LocalizedStringResource {
            switch self {
            case .burger: return "Panini"
            case .picker: return "Voti"
            }
        }
    }
    
    init() {}
    
    private var ablePostButton: Bool {
        !title.isEmpty && !content.isEmpty && (selectedUser != nil || selectedSubject != nil || selectedTimetableEntry != nil)
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                HStack(alignment: .center) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.system(size: 50, weight: .light))
                    }
                    
                    Spacer()
                    
                    switch createPostOptions.ratingView {
                    case .burger:
                        BurgerRatingView(mark: $mark)
                    case .picker:
                        PickerRatingView(mark: $mark)
                    }
                    
                    Spacer()
                    
                    Button(action: handlePostButton) {
                        Text("Post").textButtonStyle(true)
                    }.disabled(!ablePostButton || isPosting)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        Toggle(isOn: $anonymus) {
                            Label("Anonimo", systemImage: anonymus ? "eye.slash.fill" : "eye.fill")
                                .animation(.smooth, value: anonymus)
                                .font(.title2)
                                .fontWeight(.bold)
                        }.padding([.horizontal, .top])
                        if navigationPath.isEmpty, let userModel = selectedUser {
                            DismissableCard {
                                UserModelPosterCard(for: userModel)
                            } onDismissWithAnimation: {
                                selectedUser = nil
                            }
                        } else if navigationPath.isEmpty, let subjectModel = selectedSubject {
                            DismissableCard {
                                SubjectPosterCard(for: subjectModel)
                            } onDismissWithAnimation: {
                                selectedSubject = nil
                            }
                        } else if navigationPath.isEmpty, let timetableEntry = selectedTimetableEntry {
                            DismissableCard {
                                EntryHourView(timetableEntry: timetableEntry, fullDate: true)
                            } onDismissWithAnimation: {
                                selectedTimetableEntry = nil
                            }
                        } else {
                            ArgumentSelectionView(namespace: namespace)
                                .navigationDestination(in: namespace, selectedUser: $selectedUser, selectedSubject: $selectedSubject, selectedTimetableEntry: $selectedTimetableEntry, navigationPath: $navigationPath)
                                .environmentObject(timetableManager)
                        }
                        TextField("", text: $title, prompt: Text("Titolo").textColor())
                            .id(Field.title)
                            .foregroundStyle(Color.white)
                            .font(.system(size: 30, weight: .bold))
                            .padding([.top, .horizontal])
                            .onChange(of: focusedField, initial: false) { oldValue, newValue in
                                if oldValue == Field.title && newValue != Field.title {
                                    title = title.trimmingCharacters(in: .whitespacesAndNewlines)
                                }
                            }
                            .focused($focusedField, equals: Field.title)
                            .textInputAutocapitalization(.words)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = getFocus()
                            }
                        TextField("", text: $content, prompt: Text("Corpo").textColor(), axis: .vertical)
                            .id(Field.content)
                            .foregroundStyle(Color.white)
                            .font(.body)
                            .padding()
                            .onChange(of: focusedField, initial: false) { oldValue, newValue in
                                if oldValue == Field.content && newValue != Field.content {
                                    content = content.trimmingCharacters(in: .whitespacesAndNewlines)
                                }
                            }
                            .onChange(of: content) {
                                withAnimation {
                                    proxy.scrollTo(Field.content, anchor: .bottom)
                                }
                            }
                            .focused($focusedField, equals: Field.content)
                            .submitLabel(.return)
                            .textInputAutocapitalization(.sentences)
                    }.scrollDismissesKeyboard(.interactively)
                }
            }.navigationTitle("Recensione \(timetableManager.timetable?.classe.name ?? "")")
        }.task {
            await timetableManager.fetchUsers()
        }
    }
    private func getFocus() -> Field? {
        if title.isEmpty {
            return .title
        } else if content.isEmpty {
            return .content
        } else {
            return nil
        }
    }
    private func handlePostButton() {
        focusedField = nil
        content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard title.count <= titleMaxLength else {
            return Utility.setupAlert(PostErrors.titleTooLong(maxLength: titleMaxLength).notification)
        }
        guard content.count <= contentMaxLength else {
            return Utility.setupAlert(PostErrors.contentTooLong(maxLength: contentMaxLength).notification)
        }
        let postData: PostData = PostData(title: title, content: content, selectedUser: selectedUser, selectedSubject: selectedSubject, selectedTimetableEntry: selectedTimetableEntry, mark: mark, anonymus: anonymus)
        isPosting = true
        Task {
            defer { isPosting = false }
            do {
                let response = try await UserManager.shared.uploadPost(for: postData)
                if case PostNotification.posted = response {
                    dismiss()
                }
                Utility.setupBottom(response.notification)
            } catch {
                if let err = mapError(error) {
                    Utility.setupBottom(err.notification)
                }
            }
        }
    }
}

struct PostData: Encodable {
    let title: String
    let content: String
    
    let selectedUser: UserModel?
    let selectedSubject: SubjectModel?
    let selectedTimetableEntry: TimetableEntry?
    
    let mark: Int
    let valueType: CreatePostView.RatingView = CreatePostOptions.shared.ratingView
    let anonymus: Bool
    
    enum CodingKeys: String, CodingKey {
        case title
        case content
        case teacherId
        case subjectId
        case isLab
        case timetableEntryId
        case timetableDate
        case mark
        case valueType
        case anonymus
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(title, forKey: .title)
        try container.encode(content, forKey: .content)
        try container.encode(mark, forKey: .mark)
        try container.encode(valueType.rawValue, forKey: .valueType)
        try container.encode(anonymus, forKey: .anonymus)
        
        // Custom encoding logic for optional nested models
        if let user = selectedUser {
            try container.encode(user.id, forKey: .teacherId)
        } else if let subject = selectedSubject {
            try container.encode(subject.subject, forKey: .subjectId)
            try container.encode(subject.isLaboratory, forKey: .isLab)
        } else if let timetableEntry = selectedTimetableEntry {
            try container.encode(timetableEntry.id, forKey: .timetableEntryId)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateString = formatter.string(from: timetableEntry.startTime)
            try container.encode(dateString, forKey: .timetableDate)
        }
    }
}

fileprivate struct DismissableCard<Content: View>: View {
    let content: Content
    let onDismiss: () -> Void
    
    init(content: () -> Content, onDismissWithAnimation: @escaping () -> Void) {
        self.content = content()
        self.onDismiss = onDismissWithAnimation
    }
    
    var body: some View {
        HStack {
            content
            Button {
                withAnimation {
                    onDismiss()
                }
            } label: {
                Image(systemName: "xmark").fontWeight(.bold)
            }
        }.padding(.horizontal)
    }
}

protocol ListView: ViewConnectionable {
    var title: LocalizedStringResource { get }
}
protocol ViewConnectionable: View {
    var namespace: Namespace.ID { get }
}

struct BurgerRatingView: View {
    @Binding var mark: Int
    private let units: Int = 5
    private let maxRating: Int = 10
    private var unitValue: Int { maxRating / units }
    
    enum BurgerUnitState {
        case full
        case half
        case empty
        
        var image: Image {
            switch self {
            case .full:  return Image("Burger")
            case .half:  return Image("HalfBurger")
            case .empty: return Image("NoBurger")
            }
        }
    }
    
    private func state(for index: Int) -> BurgerUnitState {
        let fullCount = mark / unitValue
        let remainder = mark % unitValue
        
        if index < fullCount {
            return .full
        } else if index == fullCount && remainder > 0 {
            return .half
        } else {
            return .empty
        }
    }
    
    private func ratingByCoordinate(width: CGFloat, xLocation: CGFloat) {
        let unitWidth = width / CGFloat(units)
        let rawIndex = Int(xLocation / unitWidth)
        let index = min(max(rawIndex, 0), units - 1)
        
        let localX = xLocation - (CGFloat(index) * unitWidth)
        
        ratingByCoordinate(index: index, width: width, localX: localX)
    }
    
    private func ratingByCoordinate(index: Int, width: CGFloat, localX: CGFloat) {
        let unitWidth = width / CGFloat(units)
        
        let leftThreshold = unitWidth * (1/4)
        let rightThreshold = unitWidth * (3/4)
        
        mark = if localX > rightThreshold {
            (index + 1) * unitValue
        } else if localX >= leftThreshold {
            index * unitValue + (unitValue / 2)
        } else {
            index * unitValue
        }
    }
    
    var body: some View {
        GeometryReader { outerGeo in
            HStack(spacing: 0) {
                ForEach(0..<units, id: \.self) { index in
                    state(for: index).image
                        .resizable()
                        .scaledToFit()
                        .gesture(SpatialTapGesture(coordinateSpace: .local)
                            .onEnded { value in
                                ratingByCoordinate(index: index, width: outerGeo.size.width, localX: value.location.x)
                            }
                        )
                }
            }.gesture(DragGesture(coordinateSpace: .local)
                .onChanged { drag in
                    ratingByCoordinate(width: outerGeo.size.width, xLocation: drag.location.x)
                }
                .onEnded { drag in
                    ratingByCoordinate(width: outerGeo.size.width, xLocation: drag.location.x)
                }
            )
        }.onChange(of: mark) {
            HapticFeedback.trigger(.selection)
        }
    }
}

struct PickerRatingView: View {
    @Binding var mark: Int
    private let maxRating: Int = 10
    private let minRating: Int = 0
    private let unitValue: Int = 1
    
    var body: some View {
        Menu {
            ForEach(minRating...maxRating, id: \.self) { index in
                Button {
                    mark = index * unitValue
                } label: {
                    Text("\(index * unitValue)")
                }
            }
        } label: {
            let weight: Font.Weight = .bold
            Label("Voto: \(mark.description)", systemImage: "chevron.up.chevron.down")
                .font(.title)
                .fontWeight(weight)
                .foregroundStyle(Color.primary)
                .padding(.horizontal, weight.horizontalPadding)
                .padding(.vertical, weight.verticalPadding)
                .background(Capsule().stroke(lineWidth: weight.strokeWidth))
        }
    }
}

#Preview("Post") {
    @Previewable @ObservedObject var userManager = UserManager.shared
    @Previewable @ObservedObject var notificationManager = NotificationManager.shared
    @Previewable @ObservedObject var keyboardManager = KeyboardManager.shared
    
    NavigationStack {
        CreatePostView()
    }
    .addAlerts(notificationManager)
    .addBottomNotifications(notificationManager)
    .foregroundStyle(Color.accentColor)
    .accentColor(Color.accent)
    .environmentObject(userManager)
    .environmentObject(keyboardManager)
}
