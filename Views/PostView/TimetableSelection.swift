//
//  TimetableSelection.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 12/05/25.
//

import SwiftUI
import Combine

class TimetableViewManager: ObservableObject {
    static let shared = TimetableViewManager()
    
    @Published private(set) var clockTimer = ClockTimer()
    private var clockTimerSubscription: AnyCancellable?
    
    let days: [Date] = {
        let today = Date()
        var TOTAL_DAYS: UInt = 32
        return (-Int(TOTAL_DAYS / 2)...Int(TOTAL_DAYS / 2)).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: offset, to: today)
        }
    }()
    
    private init() {
        clockTimer.start()
        clockTimerSubscription = clockTimer.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        }
    }
    deinit {
        clockTimer.cancel()
        clockTimerSubscription?.cancel()
        clockTimerSubscription = nil
    }
}

struct TimetableView: View {
    private var entriesByWeekday: [WeekDay: [TimetableEntry]]
    
    @State private var selectedDateIndex: Int
    
    @ObservedObject private var timetableViewManager: TimetableViewManager = TimetableViewManager.shared
    
    let namespace: Namespace.ID
    
    init(namespace: Namespace.ID) {
        self.namespace = namespace
        let grouped = Dictionary(grouping: TimetableManager.shared.timetable!.TimetableEntries, by: { $0.weekDay })
            .mapValues {
                $0.sorted {
                    if $0.startTime == $1.startTime {
                        return $0.endTime > $1.endTime
                    } else {
                        return $0.startTime < $1.startTime
                    }
                }
            }
        self.entriesByWeekday = grouped
        self.selectedDateIndex = TimetableViewManager.shared.days.firstIndex { Calendar.current.isDateInToday($0) } ?? TimetableViewManager.shared.days.count / 2
    }
    
    var body: some View {
        VStack(spacing: 0) {
            DateScrollMenu(selectedDateIndex: $selectedDateIndex, itemSize: 85).padding(.vertical)
            
            Divider()
            
            TabView(selection: indexSelection()) {
                ForEach(timetableViewManager.days.indices, id: \.self) { index in
                    TimetableDayScheduleView(namespace: namespace, date: timetableViewManager.days[index], entries: entriesByWeekday[WeekDay(calendarWeekday: Calendar.current.component(.weekday, from: timetableViewManager.days[index]))!] ?? [])
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .ignoresSafeArea(.container, edges: .bottom)
                
        }.environmentObject(timetableViewManager)
    }
    private func indexSelection() -> Binding<Int> {
        Binding<Int>(
            get: { self.selectedDateIndex },
            set: { newSelectedDateIndex in
                withAnimation {
                    self.selectedDateIndex = newSelectedDateIndex
                }
            }
        )
    }
}

struct TimetableDayScheduleView: View {
    private let date: Date
    private let entries: [TimetableEntry]
    
    let namespace: Namespace.ID
    
    static let offsetToCenterHours: CGFloat = 9
    
    private let minuteHeight: CGFloat = 2
    private let hours: (startHour: Int, endHour: Int)
    private var totalHours: Int { hours.endHour - hours.startHour }
    private var totalHeight: CGFloat { CGFloat(totalHours) * 60 * minuteHeight }
    private let contnentMargin: CGFloat = 50
    private let hoursMargin: (upperBound: Int, lowerBound: Int) = (upperBound: 0, lowerBound: 1)
    private let minHours: Int = 8
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    init(namespace: Namespace.ID, date: Date, entries: [TimetableEntry]) {
        self.namespace = namespace
        self.date = date
        self.entries = entries
        
        var start = 8
        var end = 12
        for entry in entries {  //entries are already sorted by startTime
            let h0 = Calendar.current.component(.hour, from: entry.startTime)
            let h1 = Calendar.current.component(.hour, from: entry.endTime)
            start = min(start, h0)
            end = max(end, h1)
        }
        start = max(start - hoursMargin.upperBound, 0)
        end = min(end + hoursMargin.lowerBound, 24)
        if end - start < minHours {
            var diff = minHours - (end - start)
            end = min(end + diff, 24)
            if end - start < minHours {
                diff = minHours - (end - start)
                start = max(start - diff, 0)
            }
        }
        hours = (startHour: start, endHour: end)
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            HStack(alignment: .top, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    ForEach(0...totalHours, id: \.self) { hr in
                        let y = CGFloat(hr * 60) * minuteHeight
                        Text(String(format: "%02d:00", hours.startHour + hr))
                            .font(.callout)
                            .fontWeight(.semibold)
                            .offset(y: y - TimetableDayScheduleView.offsetToCenterHours)
                    }
                    if isToday {
                        CurrentTimeView<CurrentTimeBox>(minuteHeight: minuteHeight, hours: hours, contentMargin: contnentMargin)
                    }
                }
                .padding(.horizontal, 8)
                .offset(y: contnentMargin)
                .zIndex(1)
                
                Divider()
                    .frame(height: totalHeight + (contnentMargin * 2))
                    .zIndex(0)
                
                ZStack(alignment: .top) {
                    ForEach(0...totalHours, id: \.self) { hr in
                        let y = CGFloat(hr * 60) * minuteHeight
                        Divider().offset(y: y)
                    }
                    ForEach(entries) { entry in
                        HeightedAndOffsettedEntryView<PlainTimetableEntryHourView>(namespace: namespace, timetableEntry: entry, date: date, minuteHeight: minuteHeight, hours: hours)
                            
                    }
                    if isToday {
                        CurrentTimeView<CurrentTimeIndicator>(minuteHeight: minuteHeight, hours: hours, contentMargin: contnentMargin)
                    }
                }
                .offset(y: contnentMargin)
                .zIndex(2)
            }
        }
    }
}

struct PlainTimetableEntryHourView: HeighsettableEntry {
    private let namespace: Namespace.ID
    
    private let timetableEntry: TimetableEntry
    private let date: Date
    
    private let viewHeight: CGFloat
    
    private let minHeightToText: CGFloat = 60
    
    init(namespace: Namespace.ID, timetableEntry: TimetableEntry, date: Date, viewHeight: CGFloat) {
        self.namespace = namespace
        self.timetableEntry = timetableEntry
        self.date = date
        self.viewHeight = viewHeight
    }
    
    private var isEntryShort: (_ viewHeight: CGFloat) -> Bool {
        return { viewHeight in
            minHeightToText > viewHeight
        }
    }
    
    var body: some View {
        NavigationLink(value: NavigationSelectionNode.timetable(id: timetableEntry.id, date: date)) {
            EntryHourView(timetableEntry: timetableEntry, isShort: isEntryShort(viewHeight))
                .clipped()
                .padding(.horizontal)
                .matchedTransitionSource(id: timetableEntry.id, in: namespace)
                .hoverEffect()
        }
    }
}

struct EntryHourView: View {
    private let timetableEntry: TimetableEntry
    private let isShort: Bool
    private let fullDate: Bool
    
    init(timetableEntry: TimetableEntry, isShort: Bool = false, fullDate: Bool = false) {
        self.timetableEntry = timetableEntry
        self.isShort = isShort
        self.fullDate = fullDate
    }
    
    var body: some View {
        ZStack(alignment: isShort ? .leading : .topLeading) {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(Color.random())
                .stroke(Color.accentColor)
            if !isShort {
                VStack(alignment: .leading) {
                    Text(fullDate ? formattedTimetableRange : formattedTimeOnly)
                        .font(.headline)
                        .fontWeight(.bold)
                    Text(timetableEntry.subjectModels.map { String(localized: $0.subject.name) }.joined(separator: ", "))
                        .font(.footnote)
                        .fontWeight(.semibold)
                    if let teachers = timetableEntry.teachers {
                        Text(teachers.map { "\($0.name) \($0.surname)" }.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(Color.primary)
                    }
                }.padding()
            } else {
                Text(timetableEntry.subjectModels.map { String(localized: $0.subject.name) }.joined(separator: ", "))
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
            }
        }
    }
    private var formattedTimeOnly: String {
        let startTime = EntryHourView.formatterTimeOnly.string(from: timetableEntry.startTime)
        let endTime = EntryHourView.formatterTimeOnly.string(from: timetableEntry.endTime)
        return "\(startTime) – \(endTime)"
    }
    private var formattedTimetableRange: String {
        let startString = EntryHourView.formatterWeekdayDayMonthYearTime.string(from: timetableEntry.startTime)
        let endTimeOnly = EntryHourView.formatterTimeOnly.string(from: timetableEntry.endTime)
        
        return "\(startString) - \(endTimeOnly)"
    }
    private static let formatterWeekdayDayMonthYearTime: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E dd MMM yyyy, HH:mm"
        return dateFormatter
    }()
    private static let formatterTimeOnly: DateFormatter = {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        return timeFormatter
    }()
}

protocol HeighsettableEntry: View {
    init(namespace: Namespace.ID, timetableEntry: TimetableEntry, date: Date, viewHeight: CGFloat)
}

struct HeightedAndOffsettedEntryView<Entry: HeighsettableEntry>: View {
    private let namespace: Namespace.ID
    
    private let timetableEntry: TimetableEntry
    private let date: Date
    
    let minuteHeight: CGFloat
    let hours: (startHour: Int, endHour: Int)
    
    init(namespace: Namespace.ID, timetableEntry: TimetableEntry, date: Date, minuteHeight: CGFloat, hours: (startHour: Int, endHour: Int)) {
        self.namespace = namespace
        self.timetableEntry = timetableEntry
        self.date = date
        self.minuteHeight = minuteHeight
        self.hours = hours
    }
    
    private var minutesSinceStart: (_ date: Date) -> CGFloat {
        return { date in
            let comps = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
            let hour = CGFloat(comps.hour ?? 0)
            let minute = CGFloat(comps.minute ?? 0)
            let second = CGFloat(comps.second ?? 0)
            
            return (hour - CGFloat(hours.startHour)) * 60 + minute + second / 60
        }
    }
    
    var body: some View {
        let startMin = minutesSinceStart(timetableEntry.startTime)
        let endMin = minutesSinceStart(timetableEntry.endTime)
        
        let yOffset = startMin * minuteHeight
        let viewHeight = (endMin - startMin) * minuteHeight
        
        Entry(namespace: namespace, timetableEntry: timetableEntry, date: date, viewHeight: viewHeight)
            .frame(height: viewHeight, alignment: .top)
            .offset(y: yOffset)
    }
}

extension Color {
    static func random() -> Color {
        let palette: [Color] = [
            .red,
            .orange,
            .yellow,
            .green,
            .teal,
            .blue,
            .indigo,
            .purple,
            .pink,
            .brown,
            .cyan,
            .textSecondary,
            .gradientBottom,
            .gradientTop
        ]
        return palette.randomElement()!
    }
    static var inversePrimary: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .black : .white
        })
    }
}

struct TimetableEntryDetailView: SelectionDetailView {
    private let timetableEntry: TimetableEntry
    @Binding private var selectedTimetableEntry: TimetableEntry?
    @Binding var navigationPath: [NavigationSelectionNode]
    
    @EnvironmentObject private var timetableManager: TimetableManager
    
    init(timetableEntry: TimetableEntry, selectedTimetableEntry: Binding<TimetableEntry?>, navigationPath: Binding<[NavigationSelectionNode]>) {
        self.timetableEntry = timetableEntry
        self._selectedTimetableEntry = selectedTimetableEntry
        self._navigationPath = navigationPath
    }
    
    var body: some View {
        VStack {
            Text(formattedTimetableRange)
                .font(.title2)
                .fontWeight(.bold)
            ForEach(timetableEntry.subjectModels) { subjectModel in
                SubjectPosterCard(for: subjectModel)
            }
            if let teachers = timetableEntry.teachers {
                ForEach(teachers) { teacher in
                    if let teacherModel = timetableManager.teacherModelsSet.first(where: { $0.id == teacher.id }) {
                        UserModelPosterCard(for: teacherModel)
                    } else {
                        Text("Non trovato\nProfessore: \(teacher.description)")
                            .foregroundColor(.red)
                            .padding()
                    }
                }
            }
            Button {
                selectedTimetableEntry = timetableEntry
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
    private var formattedTimetableRange: String {
        let startString = TimetableEntryDetailView.formatterWeekdayDayMonthYearTime.string(from: timetableEntry.startTime)
        let endTimeOnly = TimetableEntryDetailView.formatterTimeOnly.string(from: timetableEntry.endTime)
        
        return "\(startString) - \(endTimeOnly)"
    }
    private static let formatterWeekdayDayMonthYearTime: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E dd MMM yyyy, HH:mm"
        return dateFormatter
    }()
    private static let formatterTimeOnly: DateFormatter = {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        return timeFormatter
    }()
}

#Preview("Post") {
    @Previewable @ObservedObject var userManager = UserManager.shared
    @Previewable @ObservedObject var notificationManager = NotificationManager.shared
    @Previewable @ObservedObject var keyboardManager = KeyboardManager.shared
    @Previewable @ObservedObject var timetableManager = TimetableManager.shared

    @Previewable @State var time: Timetable?
    
    @Previewable @Namespace var namespace

    VStack {
        if timetableManager.isLoading {
            ProgressView()
        } else if timetableManager.timetable?.TimetableEntries.isEmpty ?? true {
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
            TimetableView(namespace: namespace)
        }
    }
    .addAlerts(notificationManager)
    .addBottomNotifications(notificationManager)
    .foregroundStyle(Color.accentColor)
    .accentColor(Color.accent)
    .environmentObject(userManager)
    .environmentObject(keyboardManager)
    .task {
        await timetableManager.fetchUsers()
    }
}
