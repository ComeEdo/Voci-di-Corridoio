//
//  CurrentTimeView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 23/05/25.
//

import SwiftUI

protocol TimeIndicator: View {
    var minuteHeight: CGFloat { get }
    var minutesSinceStart: CGFloat { get }
    var totalHours: Int { get }
    var contentMargin: CGFloat { get }
    
    init(minuteHeight: CGFloat, minutesSinceStart: CGFloat, totalHours: Int, contentMargin: CGFloat)
}

struct CurrentTimeView<Indicator: TimeIndicator>: View {
    @EnvironmentObject private var timetableViewManager: TimetableViewManager
    
    private let minuteHeight: CGFloat
    private let hours: (startHour: Int, endHour: Int)
    private var totalHours: Int { hours.endHour - hours.startHour }
    private let contentMargin: CGFloat
    
    init(minuteHeight: CGFloat, hours: (startHour: Int, endHour: Int), contentMargin: CGFloat) {
        self.minuteHeight = minuteHeight
        self.hours = hours
        self.contentMargin = contentMargin
    }
    
    private var minutesSinceStart: CGFloat {
        let comps = Calendar.current.dateComponents([.hour, .minute, .second], from: timetableViewManager.clockTimer.currentDate)
        let hour = CGFloat(comps.hour ?? 0)
        let minute = CGFloat(comps.minute ?? 0)
        let second = CGFloat(comps.second ?? 0)
        
        return (hour - CGFloat(hours.startHour)) * 60 + minute + second / 60
    }
    
    var body: some View {
        Indicator(minuteHeight: minuteHeight, minutesSinceStart: minutesSinceStart, totalHours: totalHours, contentMargin: contentMargin)
    }
}

struct CurrentTimeIndicator: TimeIndicator {
    let minuteHeight: CGFloat
    let minutesSinceStart: CGFloat
    let totalHours: Int
    let contentMargin: CGFloat
    
    static let height: CGFloat = 2
    
    init(minuteHeight: CGFloat, minutesSinceStart: CGFloat, totalHours: Int, contentMargin: CGFloat) {
        self.minuteHeight = minuteHeight
        self.minutesSinceStart = minutesSinceStart
        self.totalHours = totalHours
        self.contentMargin = contentMargin
    }
    
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()
    
    var body: some View {
        if minutesSinceStart >= -(contentMargin / minuteHeight) && minutesSinceStart <= ((CGFloat(totalHours) * 60 ) +  (contentMargin / minuteHeight)) {
            Rectangle()
                .fill(Color.accentColor)
                .frame(height: CurrentTimeIndicator.height)
                .offset(y: minutesSinceStart * minuteHeight - CurrentTimeIndicator.height / 2)
        }
    }
}

struct CurrentTimeBox: TimeIndicator {
    @EnvironmentObject private var timetableViewManager: TimetableViewManager
    
    let minuteHeight: CGFloat
    let minutesSinceStart: CGFloat
    let totalHours: Int
    let contentMargin: CGFloat
    
    private let padding: CGFloat = 4
    
    init(minuteHeight: CGFloat, minutesSinceStart: CGFloat, totalHours: Int, contentMargin: CGFloat) {
        self.minuteHeight = minuteHeight
        self.minutesSinceStart = minutesSinceStart
        self.totalHours = totalHours
        self.contentMargin = contentMargin
    }
    
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()
    
    var body: some View {
        Group {
            if minutesSinceStart >= -(contentMargin / minuteHeight) && minutesSinceStart <= ((CGFloat(totalHours) * 60 ) +  (contentMargin / minuteHeight)) {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: 25, height: CurrentTimeIndicator.height)
                    .offset(x: 37, y: -CurrentTimeIndicator.height / 2)
                Text(CurrentTimeBox.timeFormatter.string(from: timetableViewManager.clockTimer.currentDate))
                    .foregroundStyle(Color.primary)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .padding(padding)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.accentColor))
                    .offset(x: -padding, y: -(TimetableDayScheduleView.offsetToCenterHours + padding))
            }
        }.offset(y: minutesSinceStart * minuteHeight)
    }
}
