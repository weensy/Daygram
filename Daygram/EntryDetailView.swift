import SwiftUI
import SwiftData

struct EntryDetailView: View {
    @Bindable var entry: DiaryEntry
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var imageCache = ThumbnailCache.shared
    
    @State private var isEditing = false
    @State private var editedText = ""
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    @State private var displayImage: UIImage?
    
    private let textLimit = 500
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    imageSection
                    textSection
                    metadataSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .navigationTitle(dateTitle)
            .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { isEditing.toggle() }) {
                        Label(isEditing ? "Cancel Edit" : "Edit Text", systemImage: isEditing ? "xmark" : "pencil")
                    }
                    
                    Button(action: { showingShareSheet = true }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Delete Entry", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteEntry()
            }
        } message: {
            Text("This will permanently delete this memory. This action cannot be undone.")
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = ImageStorageManager.shared.loadImage(fileName: entry.imageFileName) {
                ShareSheet(items: [image, entry.text])
            }
        }
        .onAppear {
            editedText = entry.text
            loadImage()
        }
        }
    }
    
    private var imageSection: some View {
        VStack(spacing: 12) {
            if let image = displayImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 300)
                    .overlay(
                        ProgressView()
                            .scaleEffect(1.5)
                    )
            }
        }
    }
    
    private var textSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Note")
                    .font(.headline)
                
                Spacer()
                
                if isEditing {
                    HStack(spacing: 12) {
                        Button("Cancel") {
                            isEditing = false
                            editedText = entry.text
                        }
                        .foregroundColor(.secondary)
                        
                        Button("Save") {
                            saveText()
                        }
                        .fontWeight(.medium)
                        .disabled(editedText.count > textLimit)
                    }
                }
            }
            
            if isEditing {
                VStack(alignment: .trailing, spacing: 8) {
                    TextField("Add your thoughts...", text: $editedText, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(5...15)
                    
                    Text("\(editedText.count)/\(textLimit)")
                        .font(.caption)
                        .foregroundColor(editedText.count > textLimit ? .red : .secondary)
                }
            } else {
                if entry.text.isEmpty {
                    Text("No note added")
                        .foregroundColor(.secondary)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                } else {
                    Text(entry.text)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                Text(dateString)
                    .font(.body)
            }
            
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                Text(timeString)
                    .font(.body)
            }
            
            if entry.updatedAt != entry.createdAt {
                HStack {
                    Image(systemName: "pencil")
                        .foregroundColor(.secondary)
                    Text("Edited \(updatedTimeString)")
                        .font(.body)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var dateTitle: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: entry.date)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: entry.date)
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: entry.createdAt)
    }
    
    private var updatedTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: entry.updatedAt, relativeTo: Date())
    }
    
    private func saveText() {
        let trimmedText = editedText.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.updateText(trimmedText)
        
        do {
            try modelContext.save()
            isEditing = false
        } catch {
            print("Error saving text: \(error)")
        }
    }
    
    private func deleteEntry() {
        ImageStorageManager.shared.deleteEntry(
            imageFileName: entry.imageFileName,
            thumbnailFileName: entry.thumbnailFileName
        )
        
        modelContext.delete(entry)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error deleting entry: \(error)")
        }
    }
    
    private func loadImage() {
        // Check cached image first
        if let cachedImage = imageCache.getImage(for: entry.imageFileName) {
            displayImage = cachedImage
            return
        }
        
        // Load image in background
        Task {
            let fileName = entry.imageFileName // Extract from main actor context
            let image = await Task.detached(priority: .userInitiated) {
                return ImageStorageManager.shared.loadImage(fileName: fileName)
            }.value
            
            displayImage = image
            if let image = image {
                // Cache the image
                imageCache.cacheImage(image, fileName: fileName)
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        EntryDetailView(entry: DiaryEntry(
            date: Date(),
            text: "This is a sample diary entry with some text to show how it looks in the detail view.",
            imageFileName: "sample.jpg",
            thumbnailFileName: "sample_thumb.jpg"
        ))
    }
    .modelContainer(for: DiaryEntry.self, inMemory: true)
}