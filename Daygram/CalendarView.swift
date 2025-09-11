import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [DiaryEntry]
    
    @State private var selectedMonth = Date()
    @State private var selectedDate: Date?
    @State private var showingSettings = false
    
    private var calendar = Calendar.current
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                monthHeader
                calendarGrid
                Spacer()
            }
            .navigationTitle("Daygram")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                            .fontWeight(.medium)
                    }
                }
            }
            .sheet(item: Binding<DateWrapper?>(
                get: { selectedDate.map(DateWrapper.init) },
                set: { selectedDate = $0?.date }
            )) { dateWrapper in
                DayDetailView(date: dateWrapper.date)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
    
    private var monthHeader: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            Text(monthYearText)
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
    
    private var calendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
            ForEach(weekdayHeaders, id: \.self) { weekday in
                Text(weekday)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(height: 20)
            }
            
            ForEach(monthDays.indices, id: \.self) { index in
                let date = monthDays[index]
                if calendar.isDate(date, equalTo: selectedMonth, toGranularity: .month) {
                    DayCell(
                        date: date,
                        entry: entryForDate(date),
                        onTap: { selectedDate = date }
                    )
                } else {
                    Color.clear
                        .frame(height: 50)
                }
            }
        }
        .padding(.horizontal, 4)
    }
    
    private var weekdayHeaders: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.shortWeekdaySymbols
    }
    
    private var monthDays: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth) else { return [] }
        
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
    
    private func entryForDate(_ date: Date) -> DiaryEntry? {
        let dayKey = DiaryEntry.dayKey(for: date)
        return entries.first { $0.dayKey == dayKey }
    }
    
    private func previousMonth() {
        selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
    }
    
    private func nextMonth() {
        selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
    }
}

struct DayCell: View {
    let date: Date
    let entry: DiaryEntry?
    let onTap: () -> Void
    
    private var calendar = Calendar.current
    
    init(date: Date, entry: DiaryEntry?, onTap: @escaping () -> Void) {
        self.date = date
        self.entry = entry
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background - clean grid style
                Rectangle()
                    .fill(Color(.systemBackground))
                    .overlay(
                        Rectangle()
                            .stroke(Color(.systemGray5), lineWidth: 0.5)
                    )
                
                // Thumbnail image if exists
                if let entry = entry {
                    AsyncImage(url: nil) { _ in
                        if let thumbnail = ImageStorageManager.shared.loadThumbnail(fileName: entry.thumbnailFileName) {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                                .opacity(0.8)
                        }
                    }
                }
                
                // Date number - top right
                VStack {
                    HStack {
                        Spacer()
                        Text("\(calendar.component(.day, from: date))")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(isToday ? .white : .primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Group {
                                    if isToday {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.accentColor)
                                    } else if entry != nil {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.black.opacity(0.6))
                                    }
                                }
                            )
                    }
                    Spacer()
                }
                .padding(4)
            }
            .aspectRatio(1.0, contentMode: .fit)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
}

struct DateWrapper: Identifiable {
    let id = UUID()
    let date: Date
}

#Preview {
    CalendarView()
        .modelContainer(for: DiaryEntry.self, inMemory: true)
}