import SwiftUI
import SwiftData

struct DayDetailView: View {
    let date: Date
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allEntries: [DiaryEntry]
    
    @State private var showingAddEntry = false
    
    private var entriesForDay: [DiaryEntry] {
        let dayKey = DiaryEntry.dayKey(for: date)
        return allEntries
            .filter { $0.dayKey == dayKey }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if entriesForDay.isEmpty {
                    emptyState
                } else {
                    entryList
                }
            }
            .navigationTitle(dateTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddEntry = true }) {
                        Image(systemName: "plus")
                            .fontWeight(.medium)
                    }
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                AddEntryView(date: date)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No memories yet")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Tap the + button to add your first photo and note for this day")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: { showingAddEntry = true }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Entry")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Spacer()
        }
    }
    
    private var entryList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(entriesForDay, id: \.id) { entry in
                    NavigationLink(destination: EntryDetailView(entry: entry)) {
                        EntryRowView(entry: entry)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }
    
    private var dateTitle: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
}

struct EntryRowView: View {
    let entry: DiaryEntry
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: nil) { _ in
                if let thumbnail = ImageStorageManager.shared.loadThumbnail(fileName: entry.thumbnailFileName) {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if !entry.text.isEmpty {
                    Text(entry.text)
                        .font(.body)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                } else {
                    Text("No text")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .italic()
                }
                
                Text(timeString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: entry.createdAt)
    }
}

#Preview {
    DayDetailView(date: Date())
        .modelContainer(for: DiaryEntry.self, inMemory: true)
}