//
//  LiveClockView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 18/05/25.
//

import SwiftUI
import Combine

//  MARK: - LiveTimeView

struct LiveTimeView: View {
    @State private var currentTime: String = ""
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .full
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    
    private let timer = Timer.publish(every: 0.001, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(currentTime)
            .font(.system(size: 32, weight: .bold, design: .monospaced))
            .padding(.vertical)
            .onReceive(timer) { input in
                currentTime = LiveTimeView.timeFormatter.string(from: input)
            }
    }
}

//  MARK: - ClockView

struct ClockView: View {
    @StateObject private var clock = ClockTimer()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .full
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()

    var body: some View {
        Text(ClockView.timeFormatter.string(from: clock.currentDate))
            .font(.system(size: 32, weight: .bold, design: .monospaced))
            .padding(.vertical)
            .onAppear {
                clock.start()  // Ensure timer starts when view appears
            }
            .onDisappear {
                clock.cancel()
            }
    }
}

final class ClockTimer: ObservableObject {
    @Published var currentDate: Date = Date.now
    private var timer: DispatchSourceTimer?
    private let matchingDate: DateComponents
    
    init(matchingDate: DateComponents = DateComponents(nanosecond: 0)) {
        self.matchingDate = matchingDate
    }
    
    func start() {
        cancel()
        
        let nextSecond = Calendar.current.nextDate(after: Date.now, matching: matchingDate, matchingPolicy: .strict, repeatedTimePolicy: .first, direction: .forward)!
        let delay = nextSecond.timeIntervalSince(Date.now)

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + delay, repeating: 1.0, leeway: .nanoseconds(0))
        timer.setEventHandler { [weak self] in
            self?.currentDate = Date.now
        }
        timer.resume()
        self.timer = timer
    }
    
    func cancel() {
        timer?.cancel()
        timer = nil
    }
    
    deinit {
        cancel()
    }
}

//  MARK: - LiveClockView

struct LiveClockView: View {
    @StateObject private var liveClockViewModel = LiveClockViewModel(interval: 0.001)
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .full
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    
    var body: some View {
        Text(LiveClockView.timeFormatter.string(from: liveClockViewModel.currentDate))
            .font(.system(size: 32, weight: .bold, design: .monospaced))
            .padding(.vertical)
    }
}

class LiveClockViewModel: ObservableObject {
    @Published var currentDate: Date = Date.now
    private var timerCancellable: AnyCancellable?

    init(interval: TimeInterval = 0.05) {
        timerCancellable = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.currentDate = date
            }
    }

    deinit {
        timerCancellable?.cancel()
    }
}

//  MARK: - LiveTimeTaskViewModel

struct LiveClockTaskView: View {
    @StateObject private var liveTimeTaskViewModel = LiveTimeTaskViewModel(interval: 0.001)
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .full
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    
    var body: some View {
        Text(LiveClockTaskView.timeFormatter.string(from: liveTimeTaskViewModel.currentDate))
            .font(.system(size: 32, weight: .bold, design: .monospaced))
            .padding(.vertical)
    }
}

final class LiveTimeTaskViewModel: ObservableObject {
    @Published var currentDate: Date = Date.now
    private var task: Task<Void, Never>?

    init(interval: TimeInterval = 0.05) {
        task = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                } catch {
                    break
                }
                guard let self = self else { break }
                await MainActor.run {
                    self.currentDate = Date.now
                }
            }
        }
    }

    deinit {
        task?.cancel()
    }
}

// MARK: - Preview

#Preview("LiveClockView") {
    Text("Previewing LiveTimeView")
    LiveTimeView()
    Divider()
    Text("Previewing LiveClockView")
    LiveClockView()
    Divider()
    Text("Previewing ClockView")
    ClockView()
    Divider()
    Text("Previewing LiveClockTaskView")
    LiveClockTaskView()
}

//  MARK: - ClockTimerDates

final class ClockTimerDates: ObservableObject {
    @Published var currentDate: Date = Date.now

    private let timeComponents: [DateComponents]
    private var currentIndex: Int = 0
    private var timer: DispatchSourceTimer?
    private var isTimerRunning: Bool = false
    
    private static func lhsIsMINrhs(lhs: DateComponents, rhs: DateComponents) -> Bool {
        let lSec = (lhs.hour ?? 0) * 3600 + (lhs.minute ?? 0) * 60 + (lhs.second ?? 0)
        let rSec = (rhs.hour ?? 0) * 3600 + (rhs.minute ?? 0) * 60 + (rhs.second ?? 0)
        if lSec != rSec { return lSec < rSec }
        return (lhs.nanosecond ?? 0) < (rhs.nanosecond ?? 0)
    }
    
    init() {
        let dates: [Date] = [Calendar.current.startOfDay(for: Date.now)]
        let comps: [DateComponents] = dates.map {
            Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: $0)
        }
        self.timeComponents = comps.sorted { lhs, rhs in ClockTimerDates.lhsIsMINrhs(lhs: lhs, rhs: rhs) }
    }
    init(dates: [Date]) throws {
        guard !dates.isEmpty else {
            throw Errors.arrayIsEmpty(message: "Array of DateComponents is empty.")
        }
        let comps: [DateComponents] = dates.map {
            Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: $0)
        }
        self.timeComponents = comps.sorted { lhs, rhs in ClockTimerDates.lhsIsMINrhs(lhs: lhs, rhs: rhs) }
    }

    func start() {
        guard !isTimerRunning else { return }
        isTimerRunning = true
        cancel()
        
        let now = Date.now
        let nowTimeDateComponents = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: now)
        currentIndex = timeComponents.firstIndex(where: { ClockTimerDates.lhsIsMINrhs(lhs: nowTimeDateComponents, rhs: $0) } ) ?? 0
        let nextDate = Calendar.current.nextDate(after: now, matching: timeComponents[currentIndex], matchingPolicy: .strict, repeatedTimePolicy: .first, direction: .forward)!
        scheduleNext(after: nextDate)
    }

    private func scheduleNext(after date: Date) {
        let timer = DispatchSource.makeTimerSource(queue: .main)
        let delay: TimeInterval = date.timeIntervalSince(Date.now)
        timer.schedule(deadline: .now() + delay, leeway: .nanoseconds(0))
        timer.setEventHandler { [weak self] in
            self?.cancel()
            guard let self = self else { return }
            
            withAnimation {
                self.currentDate = date
            }
            
            self.currentIndex = (self.currentIndex + 1) % self.timeComponents.count
            
            let nextComp = self.timeComponents[self.currentIndex]
            let nextDate = Calendar.current.nextDate(after: Date.now, matching: nextComp, matchingPolicy: .strict, repeatedTimePolicy: .first, direction: .forward)!
            
            self.scheduleNext(after: nextDate)
        }
        timer.resume()
        self.timer = timer
    }

    func cancel() {
        timer?.cancel()
        timer = nil
    }

    deinit {
        cancel()
    }
}

#Preview("ClockTimerDates") {
    @Previewable @StateObject var clockTimerDates: ClockTimerDates = try! ClockTimerDates(dates: [
        Date(timeIntervalSinceNow: 0),
        Date(timeIntervalSinceNow: 2),
        Date(timeIntervalSinceNow: 4),
        Date(timeIntervalSinceNow: 6),
        Date(timeIntervalSinceNow: 8),
        Date(timeIntervalSinceNow: 10)
    ])

    let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .full
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    
    Text(timeFormatter.string(from: clockTimerDates.currentDate))
        .font(.system(size: 32, weight: .bold, design: .monospaced))
        .padding(.vertical)
        .onAppear {
            clockTimerDates.start()
        }
    
}
