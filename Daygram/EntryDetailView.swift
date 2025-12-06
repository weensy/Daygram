import SwiftUI
import SwiftData

struct EntryDetailView: View {
    @Bindable var entry: MemoryEntry
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
        .onChange(of: entry.imageFileName) { _, _ in
            loadImage()
        }
    }
    
    private var footerSection: some View {
        HStack {
            Spacer()

            Text(dateTitle)
                .font(.daygramFont(forTextStyle: .subheadline, relativeTo: .subheadline))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
    
    private var imageSection: some View {
        Group {
            if let image = displayImage {
                let imageAspect = image.size.width / image.size.height
                let maxAspect: CGFloat = 2.0 / 3.0 // 2:3 ratio (width:height)
                
                if imageAspect >= maxAspect {
                    // Image is wider or equal to 2:3, show normally with .fit
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    // Image is taller than 2:3, crop to 2:3
                    Color.clear
                        .aspectRatio(maxAspect, contentMode: .fit)
                        .overlay(
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        )
                        .clipped()
                }
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
                        .font(customFont())
                        .lineSpacing(extra)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .onAppear(perform: recalc)
                        .onChange(of: dts) { recalc() }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func recalc() {
        let lh = UIFont.preferredFont(forTextStyle: .title3).lineHeight
        extra = (multiple - 1.0) * lh
    }

    private func customFont() -> Font {
        return .daygramFont(forTextStyle: .title3, relativeTo: .title3)
    }

    private var dateTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd.yyyy"
        return formatter.string(from: entry.date)
    }
    
    
    private func loadImage() {
        // Load image in background
        Task {
            let fileName = entry.imageFileName // Extract from main actor context
            let image = await Task.detached(priority: .userInitiated) {
                return ImageStorageManager.shared.loadImage(fileName: fileName)
            }.value
            
            displayImage = image
            if let image = image {
                // Update cache with new image
                imageCache.cacheImage(image, fileName: fileName)
            }
        }
    }
}

#Preview {
    @Previewable @State var isEditing = false
    @Previewable @State var editedText = ""
    
    return EntryDetailView(
        entry: MemoryEntry(
            date: Date(),
            text: "This is a sample diary entry with some text to show how it looks in the detail view.",
            imageFileName: "sample.jpg",
            thumbnailFileName: "sample_thumb.jpg"
        ),
        isEditing: $isEditing,
        editedText: $editedText
    )
    .modelContainer(for: MemoryEntry.self, inMemory: true)
}
