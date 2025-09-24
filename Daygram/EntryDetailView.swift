import SwiftUI
import SwiftData

struct EntryDetailView: View {
    @Bindable var entry: DiaryEntry
    var onDismiss: (() -> Void)? = nil
    @Binding var isEditing: Bool
    @Binding var editedText: String
    var onSave: (() -> Void)?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var imageCache = ThumbnailCache.shared
    
    @State private var displayImage: UIImage?
    
    private let textLimit = 100

    @Environment(\.dynamicTypeSize) private var dts
    @State private var extra: CGFloat = 0
    let multiple: CGFloat = 1.48
    
    var body: some View {
        VStack(spacing: 0) {

            VStack(spacing: 0) {
                imageSection
                textSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 20)

            footerSection
        }
        .onAppear {
            loadImage()
        }
    }
    
    private var footerSection: some View {
        HStack {
            Spacer()

            Text(dateTitle)
                .font(.custom("Georgia-Italic", size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize, relativeTo: .subheadline))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
    
    private var imageSection: some View {
        VStack(spacing: 12) {
            if let image = displayImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    // .clipShape(RoundedRectangle(cornerRadius: 12))
                    // .shadow(radius: 4)
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
                // Text("Note")
                //     .font(.headline)
                
                // Spacer()
                
                if isEditing {
                    HStack(spacing: 12) {
                        Button("Cancel") {
                            isEditing = false
                            editedText = entry.text
                        }
                        .foregroundColor(.secondary)
                        
                        Button("Save") {
                            onSave?()
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
                        .lineLimit(3...5)
                    
                    Text("\(editedText.count)/\(textLimit)")
                        .font(.caption)
                        .foregroundColor(editedText.count > textLimit ? .red : .secondary)
                }
            } else {
                if entry.text.isEmpty {
                    // Text("No note added")
                    //     .foregroundColor(.secondary)
                    //     .font(.custom("Georgia-Italic", size: UIFont.preferredFont(forTextStyle: .title3).pointSize, relativeTo: .title3))
                    //     .lineSpacing(extra)
                    //     .multilineTextAlignment(.center)
                    //     .frame(maxWidth: .infinity)
                    //     .onAppear(perform: recalc)
                    //     .onChange(of: dts) { _ in recalc() }
                } else {
                    Text(entry.text)
                        // .font(.body)
                        .font(.custom("Georgia-Italic", size: UIFont.preferredFont(forTextStyle: .title3).pointSize, relativeTo: .title3))
                        .lineSpacing(extra)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .onAppear(perform: recalc)
                        .onChange(of: dts) { _ in recalc() }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func recalc() {
        let lh = UIFont.preferredFont(forTextStyle: .title3).lineHeight
        extra = (multiple - 1.0) * lh
    }

    private var dateTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd.yyyy"
        return formatter.string(from: entry.date)
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

#Preview {
    @State var isEditing = false
    @State var editedText = ""
    
    return EntryDetailView(
        entry: DiaryEntry(
            date: Date(),
            text: "This is a sample diary entry with some text to show how it looks in the detail view.",
            imageFileName: "sample.jpg",
            thumbnailFileName: "sample_thumb.jpg"
        ),
        isEditing: $isEditing,
        editedText: $editedText
    )
    .modelContainer(for: DiaryEntry.self, inMemory: true)
}
