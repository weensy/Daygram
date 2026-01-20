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
    
    // AI description states
    @State private var isGeneratingDescription = false
    @State private var showAIButton = false
    
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
            .navigationTitle(String(localized: "edit_entry.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "common.cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "common.save")) {
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
            .onChange(of: newImage) { _, image in
                // Show AI button when new image is selected
                if image != nil {
                    showAIButton = true
                }
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
            .confirmationDialog(String(localized: "add_entry.change_photo"), isPresented: $showingSourcePicker) {
                Button(String(localized: "add_entry.camera")) {
                    showingImagePicker = true
                }
                Button(String(localized: "add_entry.photo_library")) {
                    showingPhotoPicker = true
                }
                Button(String(localized: "common.cancel"), role: .cancel) { }
            }
    }
    
    private var imageLoadingSection: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(String(localized: "edit_entry.loading_image"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 24)
    }
    
    private var textInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // AI description button - only shown when new image is selected and on iOS 26+
            if showAIButton && newImage != nil {
                aiDescriptionButton
            }
            
            TextField(String(localized: "add_entry.write_line"), text: $editedText, axis: .vertical)
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
    
    @ViewBuilder
    private var aiDescriptionButton: some View {
        if #available(iOS 26.0, *) {
            Button {
                generateAIDescription()
            } label: {
                HStack(spacing: 6) {
                    if isGeneratingDescription {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(isGeneratingDescription 
                         ? String(localized: "ai_description.generating")
                         : String(localized: "ai_description.button"))
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
            }
            .disabled(isGeneratingDescription)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 8)
        }
    }
    
    private func generateAIDescription() {
        guard let image = newImage else { return }
        
        Task {
            isGeneratingDescription = true
            defer { isGeneratingDescription = false }
            
            if #available(iOS 26.0, *) {
                do {
                    let description = try await ImageDescriptionService.shared.generateDescription(for: image)
                    await MainActor.run {
                        editedText = description
                        showAIButton = false
                    }
                } catch {
                    print("AI description generation failed: \(error)")
                }
            }
        }
    }
    
    private func recalc() {
        let lh = UIFont.preferredFont(forTextStyle: .title3).lineHeight
        extra = (multiple - 1.0) * lh
    }

    private func customFont() -> Font {
        return .daygramFont(forTextStyle: .title3, relativeTo: .title3)
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