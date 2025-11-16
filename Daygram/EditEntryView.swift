import SwiftUI
import SwiftData
import PhotosUI

struct EditEntryView: View {
    @Bindable var entry: MemoryEntry
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var editedText: String = ""
    @State private var currentImage: UIImage?
    @State private var newImage: UIImage?
    @State private var isLoading = false
    @State private var showingImagePicker = false
    @State private var showingPhotoPicker = false
    @State private var showingSourcePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    @Environment(\.dynamicTypeSize) private var dts
    @State private var extra: CGFloat = 0
    let multiple: CGFloat = 1.48
    
    private let textLimit = 100
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()
                
                // Display current or new image
                if let image = newImage ?? currentImage {
                    imagePreviewSection(image)
                } else {
                    imageLoadingSection
                }
                
                textInputSection
                
                Spacer()
            }
            .navigationTitle("Edit Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(isLoading)
                    .fontWeight(.medium)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $newImage)
            }
            .photosPicker(
                isPresented: $showingPhotoPicker,
                selection: $selectedPhotoItem,
                matching: .images
            )
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let newItem = newItem {
                        await loadPhotoFromPicker(newItem)
                    }
                }
            }
            .onAppear {
                editedText = entry.text
                currentImage = ImageStorageManager.shared.loadImage(fileName: entry.imageFileName)
            }
        }
    }
    
    private func imagePreviewSection(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 24)
            .onTapGesture {
                showingSourcePicker = true
            }
            .confirmationDialog("Change Photo", isPresented: $showingSourcePicker) {
                Button("Camera") {
                    showingImagePicker = true
                }
                Button("Photo Library") {
                    showingPhotoPicker = true
                }
                Button("Cancel", role: .cancel) { }
            }
    }
    
    private var imageLoadingSection: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading image...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 24)
    }
    
    private var textInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Write a Line", text: $editedText, axis: .vertical)
                .font(customFont())
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)
                .lineLimit(1...3)
                .padding(.bottom, 8)
                .background(
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(height: 1)
                    }
                )
                .onChange(of: editedText) { _, newValue in
                    if newValue.count > textLimit {
                        editedText = String(newValue.prefix(textLimit))
                    }
                }

            HStack{
                Spacer()
                Text("\(editedText.count)/\(textLimit)")
                    .font(.caption)
                    .foregroundColor(editedText.count > textLimit ? .red : .secondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
    }
    
    private func recalc() {
        let lh = UIFont.preferredFont(forTextStyle: .title3).lineHeight
        extra = (multiple - 1.0) * lh
    }

    private func customFont() -> Font {
        let baseSize = UIFont.preferredFont(forTextStyle: .title3).pointSize

        // Check the app's preferred language
        let preferredLanguage = Bundle.main.preferredLocalizations.first ?? "en"

        switch preferredLanguage {
        case "ko":
            return .custom("MaruBuri-Regular", size: baseSize, relativeTo: .title3)
        case "ja":
            return .custom("KleeOne-Regular", size: baseSize, relativeTo: .title3)
        default:
            return .custom("Georgia-Italic", size: baseSize, relativeTo: .title3)
        }
    }
    
    private func loadPhotoFromPicker(_ item: PhotosPickerItem) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    newImage = image
                }
            }
        } catch {
            print("Error loading photo: \(error)")
        }
    }
    
    private func saveEntry() {
        isLoading = true
        
        // Update text
        let trimmedText = editedText.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.updateText(trimmedText)
        
        // Handle image change if there's a new image
        if let newImage = newImage {
            // Delete old image files
            ImageStorageManager.shared.deleteEntry(
                imageFileName: entry.imageFileName,
                thumbnailFileName: entry.thumbnailFileName
            )
            
            // Save new image
            let (imageFileName, thumbnailFileName) = ImageStorageManager.shared.saveImage(newImage)
            
            guard let imageFileName = imageFileName,
                  let thumbnailFileName = thumbnailFileName else {
                isLoading = false
                return
            }
            
            // Update entry with new filenames
            entry.imageFileName = imageFileName
            entry.thumbnailFileName = thumbnailFileName
            
            // Clear cache for old thumbnail to ensure fresh load
            if let thumbnail = ImageStorageManager.shared.loadThumbnail(fileName: thumbnailFileName) {
                ThumbnailCache.shared.cacheThumbnail(thumbnail, fileName: thumbnailFileName)
            }
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving entry: \(error)")
        }
        
        isLoading = false
    }
}

#Preview {
    @Previewable @State var entry = MemoryEntry(
        date: Date(),
        text: "Sample entry text for editing",
        imageFileName: "sample.jpg",
        thumbnailFileName: "sample_thumb.jpg"
    )
    
    return EditEntryView(entry: entry)
        .modelContainer(for: MemoryEntry.self, inMemory: true)
}