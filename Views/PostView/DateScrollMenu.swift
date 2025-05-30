//
//  DateScrollMenu.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 19/05/25.
//

import SwiftUI

struct DateScrollMenu: View {
    @Binding private var selectedDateIndex: Int
    @State private var selectedGestureDateIndex: Int
    
    @EnvironmentObject private var timetableViewManager: TimetableViewManager
    
    private let itemSize: CGSize
    private let spacing: CGFloat = 12
    
    @State private var hasScrolledToInitialIndex = false
    @State private var isTodayButtonPressed = false
    
    private var todayIndex: Int? {
        timetableViewManager.days.firstIndex { Calendar.current.isDateInToday($0) }
    }
    /*.isDate($0, inSameDayAs: clockTimerDates.currentDate)*/
    private var showTodayButton: Bool {
        guard !isTodayButtonPressed, let todayIndex = todayIndex else { return false }
        let offset: UInt = 2
        return selectedDateIndex > todayIndex + Int(offset) || selectedDateIndex < todayIndex - Int(offset)
    }
    
    private func dateBackground(index: Int) -> some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(selectedDateIndex == index
                  ? Color.accentColor.opacity(0.75)
                  : /*Color.container*/Color.inversePrimary
            )
            .stroke(todayIndex == index
                    ? Color.accentColor
                    : Color.border,
                    lineWidth: 2
            )
    }
    private var textColor: (Int) -> Color {
        { index in
            if index == selectedDateIndex {
                return Color.primary
            }
            if index == todayIndex {
                return Color.accentColor
            }
            return Calendar.current.isDateInWeekend(timetableViewManager.days[index]) ? Color.textSecondary : Color.secondary
        }
    }
    
    init(selectedDateIndex: Binding<Int>, itemSize: CGFloat) {
        self._selectedDateIndex = selectedDateIndex
        self.selectedGestureDateIndex = selectedDateIndex.wrappedValue
        self.itemSize = CGSize(width: itemSize, height: itemSize)
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if showTodayButton {
                Button {
                    withAnimation {
                        self.selectedDateIndex = todayIndex ?? timetableViewManager.days.count / 2
                    }
                    self.isTodayButtonPressed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        self.isTodayButtonPressed = false
                    }
                } label: {
                    Label("Oggi", systemImage: "calendar")
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.inversePrimary).stroke(Color.accentColor))
                }
                .foregroundColor(Color.primary)
                .transition(.move(edge: .trailing))
                .padding(.horizontal)
                .offset(y: -30)
                .zIndex(10)
            }
            GeometryReader { proxy in
                ScrollViewReader { scrollProxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: spacing) {
                            ForEach(timetableViewManager.days.indices, id: \.self) { index in
                                let date = timetableViewManager.days[index]
                                DateView(for: date)
                                    .frame(width: itemSize.width, height: itemSize.height)
                                    .foregroundColor(textColor(index))
                                    .background(dateBackground(index: index))
                                    .scrollTransition { view, transition in
                                        view
//                                            .opacity(transition.isIdentity ? 1 : 0.6)
                                            .scaleEffect(transition.isIdentity ? 1.1 : 1, anchor: .bottom)
//                                            .blur(radius: transition.isIdentity ? 0 : 1.5)
                                    }
                                    .onScrollVisibilityChange { visibility in handleScrollVisibilityChange(index: index, visibility: visibility) }
                                    .onTapGesture { handleTapGesture(index: index, scrollProxy: scrollProxy) }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .contentMargins(.horizontal, (proxy.size.width - itemSize.width) / 2)
                    .scrollTargetBehavior(.viewAligned)
                    .scrollClipDisabled()
                    .onChange(of: selectedDateIndex) {
                        handleIndexChange(scrollProxy: scrollProxy)
                    }
                    .onAppear {
                        if !hasScrolledToInitialIndex {
                            scrollProxy.scrollTo(selectedDateIndex, anchor: .center)
                            DispatchQueue.main.async {
                                hasScrolledToInitialIndex = true
                            }
                        }
                    }
                }
            }.frame(height: itemSize.height)
        }
    }
    private func handleScrollVisibilityChange(index: Int, visibility: Bool) {
        if hasScrolledToInitialIndex, visibility && selectedDateIndex != index && selectedGestureDateIndex == selectedDateIndex {
            HapticFeedback.trigger(.selection)
            if !isTodayButtonPressed {
                withAnimation {
                    selectedDateIndex = index
                    selectedGestureDateIndex = index
                }
            }
        }
    }
    
    private func handleTapGesture(index: Int, scrollProxy: ScrollViewProxy) {
        guard selectedDateIndex != index || selectedGestureDateIndex != index else { return }
        withAnimation {
            scrollProxy.scrollTo(index, anchor: .center)
        }
    }
    
    private func handleIndexChange(scrollProxy: ScrollViewProxy) {
        if selectedDateIndex != selectedGestureDateIndex {
            HapticFeedback.trigger(.selection)
            withAnimation {
                selectedGestureDateIndex = selectedDateIndex
                scrollProxy.scrollTo(selectedDateIndex, anchor: .center)
            }
        }
    }
}

struct DateView: View {
    let date: Date
    
    init(for date: Date) {
        self.date = date
    }
    
    var body: some View {
        VStack {
            Text(DateView.dayOfWeekFormatter.string(from: date)).font(.callout)
            Text(DateView.dayFormatter.string(from: date))
                .font(.title)
                .fontWeight(.bold)
            Text(DateView.monthFormatter.string(from: date)).font(.caption)
        }
    }

    // MARK: - Formatters
    private static let dayFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d"
        return dateFormatter
    }()
    private static let dayOfWeekFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"
        return dateFormatter
    }()
    private static let monthFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"
        return dateFormatter
    }()
}
