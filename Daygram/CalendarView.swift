import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [DiaryEntry]
    
    @StateObject private var thumbnailCache = ThumbnailCache.shared
    @State private var selectedMonth = Date()
    @State private var selectedDate: Date?
    @State private var showingSettings = false
    @State private var showingQuickAdd = false
    @State private var currentMonthID: Int? = Calendar.current.component(.month, from: Date())
    @State private var displayedYear = Calendar.current.component(.year, from: Date())
    @State private var debounceTask: Task<Void, Never>?
    @State private var monthDatesCache: [String: [Date]] = [:]
    
    private let cardSpacing: CGFloat = 4
    private let sideInset: CGFloat = 0
    private let peekReveal: CGFloat = 40 // visible width of the next card
    private let previousYearButtonID = 0
    private let nextYearButtonID = 13
    private var navigationButtonSidePadding: CGFloat {
        max((peekReveal / 2) - cardSpacing, 0)
    }
    
    private var calendar = Calendar.current
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Header with year and settings icon
                HStack {
                    Text(yearText)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                            .font(.title2)
                            .fontWeight(.medium)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                Spacer()
                calendarCarousel
                Spacer()
                
                // Quick Add Button
                VStack(spacing: 16) {
                    Button(action: {
                        if hasTodayEntry {
                            selectedDate = Date()
                        } else {
                            showingQuickAdd = true
                        }
                    }) {
                        Image(systemName: hasTodayEntry ? "checkmark" : "plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(hasTodayEntry ? Color.accentColor : Color.accentColor)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.vertical, 32)
            }
            .navigationBarHidden(true)
            .sheet(item: Binding<DateWrapper?>(
                get: { selectedDate.map(DateWrapper.init) },
                set: { selectedDate = $0?.date }
            )) { dateWrapper in
                let existingEntry = entryForDate(dateWrapper.date)
                if let entry = existingEntry {
                    EntryDetailView(entry: entry)
                        .onAppear {
                            // Preload image
                            thumbnailCache.preloadImage(for: entry)
                        }
                } else {
                    AddEntryView(date: dateWrapper.date)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingQuickAdd) {
                AddEntryView(date: Date())
            }
            .onAppear {
                updateEntriesDict()
                preloadCurrentMonthThumbnails()
            }
            .onChange(of: entries) { _, _ in
                Task { @MainActor in
                    updateEntriesDict()
                }
            }
            .onChange(of: selectedMonth) { _, _ in
                preloadCurrentMonthThumbnails()
            }
        }
    }
    
    
    private var calendarCarousel: some View {
        GeometryReader { geo in
            let cardWidth = max(geo.size.width - peekReveal, 0)
            let navigationCardWidth = cardWidth * 0.24
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(spacing: cardSpacing) {
                        previousYearReturnCard(proxy: proxy, width: navigationCardWidth)
                            .scaleEffect(currentMonthID == previousYearButtonID ? 1 : 0.96)
                            .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: currentMonthID)
                            .id(previousYearButtonID)
                        ForEach(1...12, id: \.self) { month in
                            calendarCard(for: month)
                                .frame(width: cardWidth)
                                .scaleEffect(currentMonthID == month ? 1 : 0.96)
                                .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: currentMonthID)
                                .id(month)
                        }
                        nextYearAdvanceCard(proxy: proxy, width: navigationCardWidth)
                            .scaleEffect(currentMonthID == nextYearButtonID ? 1 : 0.96)
                            .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: currentMonthID)
                            .id(nextYearButtonID)
                    }
                    .scrollTargetLayout()
                    .frame(maxHeight: .infinity)
                }
                .contentMargins(.horizontal, peekReveal / 2) // center each card within viewport
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                .scrollPosition(id: $currentMonthID, anchor: .center)
                .onChange(of: currentMonthID) { _, newID in
                    guard let newID else { return }
                    if newID == previousYearButtonID || newID == nextYearButtonID {
                        return
                    }
                    guard (1...12).contains(newID) else { return }
                    
                    // Cancel previous debounce task
                    debounceTask?.cancel()
                    
                    // Update date immediately for smooth animation
                    var components = DateComponents()
                    components.year = displayedYear
                    components.month = newID
                    components.day = 1
                    selectedMonth = calendar.date(from: components) ?? Date()
                    
                    // Preload adjacent months in background
                    debounceTask = Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms delay for preloading
                        guard !Task.isCancelled else { return }
                        preloadAdjacentMonths(currentMonth: newID)
                    }
                }
                .onAppear {
                    let today = Date()
                    selectedMonth = today
                    displayedYear = calendar.component(.year, from: today)
                    let currentMonth = Calendar.current.component(.month, from: Date())
                    currentMonthID = currentMonth
                    DispatchQueue.main.async {
                        proxy.scrollTo(currentMonth, anchor: .center)
                    }
                }
            }
        }
        .frame(height: 520)
    }

    private func previousYearReturnCard(proxy: ScrollViewProxy, width: CGFloat) -> some View {
        Button {
            returnToPreviousYear(proxy: proxy)
        } label: {
            VStack(spacing: 8) {
                Spacer()
                Image(systemName: "arrow.left.circle.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                Text(verbatim: String(displayedYear - 1))
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 24)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: width)
        .padding(.trailing, navigationButtonSidePadding)
    }

    private func nextYearAdvanceCard(proxy: ScrollViewProxy, width: CGFloat) -> some View {
        Button {
            advanceToNextYear(proxy: proxy)
        } label: {
            VStack(spacing: 8) {
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                Text(verbatim: String(displayedYear + 1))
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 24)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: width)
        .padding(.leading, navigationButtonSidePadding)
    }
    
    private func advanceToNextYear(proxy: ScrollViewProxy) {
        let nextYear = displayedYear + 1
        let targetMonth = 1
        var components = DateComponents()
        components.year = nextYear
        components.month = targetMonth
        components.day = 1
        let targetDate = calendar.date(from: components) ?? Date()
        withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
            displayedYear = nextYear
            currentMonthID = targetMonth
            selectedMonth = targetDate
            proxy.scrollTo(targetMonth, anchor: .center)
        }
    }

    private func returnToPreviousYear(proxy: ScrollViewProxy) {
        let previousYear = displayedYear - 1
        let targetMonth = 12
        var components = DateComponents()
        components.year = previousYear
        components.month = targetMonth
        components.day = 1
        let targetDate = calendar.date(from: components) ?? Date()
        withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
            displayedYear = previousYear
            currentMonthID = targetMonth
            selectedMonth = targetDate
            proxy.scrollTo(targetMonth, anchor: .center)
        }
    }

    private func calendarCard(for month: Int) -> some View {
        var components = DateComponents()
        components.year = displayedYear
        components.month = month
        components.day = 1
        let monthDate = calendar.date(from: components) ?? Date()
        let monthDates = cachedMonthDays(for: monthDate, year: displayedYear, month: month)
        
        return VStack(spacing: 0) {
            Spacer()
            // Month header inside card
            HStack {
                Spacer()
                Text(monthText(for: monthDate))
                    .font(.title)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 16)
            
            Spacer()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: 7), spacing: 1) {
                ForEach(weekdayHeaders, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(height: 24)
                }
                
                ForEach(monthDates.indices, id: \.self) { index in
                    let date = monthDates[index]
                    if calendar.isDate(date, equalTo: monthDate, toGranularity: .month) {
                        DayCell(
                            date: date,
                            entry: entryForDate(date),
                            onTap: { selectedDate = date }
                        )
                        .id("\(displayedYear)-\(month)-\(index)") // Stable ID for view recycling
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .aspectRatio(1.0, contentMode: .fit)
                    }
                }
            }
            .padding(.horizontal, 8)
            
            Spacer()
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        // .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 0) // remove outer horizontal padding to expose peek
        .padding(.top, 12)
        .padding(.bottom, 24)
    }
    
    private func numberOfWeeks(for month: Date) -> Int {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return 6 }
        
        let firstOfMonth = monthInterval.start
        let lastOfMonth = calendar.date(byAdding: .day, value: -1, to: monthInterval.end) ?? monthInterval.start
        
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysFromPreviousMonth = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        let daysInMonth = calendar.component(.day, from: lastOfMonth)
        let totalDays = daysFromPreviousMonth + daysInMonth
        
        return (totalDays + 6) / 7 // Round up to get number of weeks
    }
    
    private var statsSection: some View {
        HStack(spacing: 12) {
            StatItem(
                title: "Streak",
                value: "\(currentStreak)"
            )
            
            StatItem(
                title: "Weeks",
                value: "\(fullWeeks)"
            )
            
            StatItem(
                title: "Memories",
                value: "\(entries.count)"
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
    
    private var weekdayHeaders: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.shortWeekdaySymbols
    }
    
    private var monthDays: [Date] {
        return monthDays(for: selectedMonth)
    }
    
    private func cachedMonthDays(for month: Date, year: Int, month monthNum: Int) -> [Date] {
        let cacheKey = "\(year)-\(monthNum)"
        
        if let cachedDates = monthDatesCache[cacheKey] {
            return cachedDates
        }
        
        let dates = monthDays(for: month)
        
        // Defer cache update to avoid state modification during view update
        DispatchQueue.main.async {
            monthDatesCache[cacheKey] = dates
        }
        
        return dates
    }
    
    private func monthDays(for month: Date) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return [] }
        
        let firstOfMonth = monthInterval.start
        
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysFromPreviousMonth = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        let startDate = calendar.date(byAdding: .day, value: -daysFromPreviousMonth, to: firstOfMonth)!
        
        var dates: [Date] = []
        var currentDate = startDate
        
        for _ in 0..<42 {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return dates
    }
    
    private var monthYearText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }
    
    private var yearText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: selectedMonth)
    }
    
    private func monthText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }
    
    private func entryForDate(_ date: Date) -> DiaryEntry? {
        let dayKey = DiaryEntry.dayKey(for: date)
        return entriesDict[dayKey]
    }
    
    @State private var entriesDict: [String: DiaryEntry] = [:]
    
    private func updateEntriesDict() {
        entriesDict = Dictionary(entries.map { ($0.dayKey, $0) }) { first, _ in first }
    }
    
    
    private var hasTodayEntry: Bool {
        let today = Date()
        let todayKey = DiaryEntry.dayKey(for: today)
        return entries.contains { $0.dayKey == todayKey }
    }
    
    private var currentStreak: Int {
        guard !entries.isEmpty else { return 0 }
        
        var streak = 0
        var currentDate = Date()
        
        // Create a set of day keys for quick lookup
        let entryDayKeys = Set(entries.map { $0.dayKey })
        
        // Check if today has an entry
        let todayHasEntry = entryDayKeys.contains(DiaryEntry.dayKey(for: currentDate))
        
        if todayHasEntry {
            // If today has an entry, count from today backwards
            while entryDayKeys.contains(DiaryEntry.dayKey(for: currentDate)) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            }
        } else {
            // If today has no entry, start from yesterday
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            
            while entryDayKeys.contains(DiaryEntry.dayKey(for: currentDate)) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            }
        }
        
        return streak
    }
    
    private var fullWeeks: Int {
        // Create a set of day keys for quick lookup
        let entryDayKeys = Set(entries.map { $0.dayKey })
        
        // Group entries by week (Sunday to Saturday)
        let entriesByWeek = Dictionary(grouping: entries) { entry in
            // Get the Sunday that starts this week
            let weekInterval = calendar.dateInterval(of: .weekOfYear, for: entry.date)
            return weekInterval?.start ?? entry.date
        }
        
        var completedWeeks = 0
        
        for (weekStart, _) in entriesByWeek {
            // Check if this week has entries for all 7 days (Sunday through Saturday)
            var hasAllDays = true
            
            for dayOffset in 0..<7 {
                guard let dayInWeek = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else {
                    hasAllDays = false
                    break
                }
                
                let dayKey = DiaryEntry.dayKey(for: dayInWeek)
                if !entryDayKeys.contains(dayKey) {
                    hasAllDays = false
                    break
                }
            }
            
            if hasAllDays {
                completedWeeks += 1
            }
        }
        
        return completedWeeks
    }
    
    
    private func preloadCurrentMonthThumbnails() {
        let monthEntries = entries.filter { entry in
            calendar.isDate(entry.date, equalTo: selectedMonth, toGranularity: .month)
        }
        thumbnailCache.preloadThumbnails(for: monthEntries)
    }
    
    private func preloadAdjacentMonths(currentMonth: Int) {
        Task.detached(priority: .background) { @MainActor in
            let adjacentMonths = [currentMonth - 1, currentMonth + 1].compactMap { month in
                let adjustedMonth = ((month - 1 + 12) % 12) + 1
                return (1...12).contains(adjustedMonth) ? adjustedMonth : nil
            }
            
            for month in adjacentMonths {
                var components = DateComponents()
                components.year = displayedYear
                components.month = month
                components.day = 1
                
                if let monthDate = calendar.date(from: components) {
                    let monthEntries = entries.filter { entry in
                        calendar.isDate(entry.date, equalTo: monthDate, toGranularity: .month)
                    }
                    
                    thumbnailCache.preloadThumbnails(for: monthEntries)
                }
            }
        }
    }
}

struct DayCell: View {
    let date: Date
    let entry: DiaryEntry?
    let onTap: () -> Void
    
    @StateObject private var thumbnailCache = ThumbnailCache.shared
    @State private var thumbnailImage: UIImage?
    @State private var loadTask: Task<Void, Never>?
    private var calendar = Calendar.current
    
    init(date: Date, entry: DiaryEntry?, onTap: @escaping () -> Void) {
        self.date = date
        self.entry = entry
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            Rectangle()
                .fill(Color(.systemBackground))
                .overlay(
                    // Thumbnail image if exists
                    Group {
                        if let thumbnailImage = thumbnailImage {
                            Image(uiImage: thumbnailImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    }
                )
                .overlay(
                    // Date number - top right
                    VStack {
                        HStack {
                            Spacer()
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(isToday ? .white : (entry != nil ? .white : .primary))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Group {
                                        if isToday {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.accentColor)
                                        }
                                    }
                                )
                                .shadow(color: entry != nil && !isToday ? .black.opacity(0.7) : .clear, radius: 1, x: 0, y: 0)
                        }
                        Spacer()
                    }
                    .padding(4)
                )
                .clipped()
                .aspectRatio(1.0, contentMode: .fit)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // Only load if entry exists to reduce overhead
            if entry != nil {
                loadThumbnailAsync()
            }
        }
        .onChange(of: entry?.thumbnailFileName) { _, _ in
            loadThumbnailAsync()
        }
        .onDisappear {
            loadTask?.cancel()
        }
    }
    
    private func loadThumbnailAsync() {
        // Cancel previous task
        loadTask?.cancel()
        
        guard let entry = entry else {
            thumbnailImage = nil
            return
        }
        
        // Check cache first
        if let cachedThumbnail = thumbnailCache.getThumbnail(for: entry.thumbnailFileName) {
            thumbnailImage = cachedThumbnail
            return
        }
        
        // Load asynchronously with priority control
        loadTask = Task(priority: .userInitiated) { @MainActor in
            if let thumbnail = ImageStorageManager.shared.loadThumbnail(fileName: entry.thumbnailFileName) {
                guard !Task.isCancelled else { return }
                thumbnailImage = thumbnail
                thumbnailCache.cacheThumbnail(thumbnail, fileName: entry.thumbnailFileName)
            }
        }
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
}

struct DateWrapper: Identifiable {
    let id = UUID()
    let date: Date
}


struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}


#Preview {
    CalendarView()
        .modelContainer(for: DiaryEntry.self, inMemory: true)
}
