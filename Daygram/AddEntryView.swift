import SwiftUI
import PhotosUI
import UIKit

struct AddEntryView: View {
    let date: Date
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDate: Date
    @State private var showingDatePicker = false
    @State private var selectedImage: UIImage?
    @State private var entryText = ""
    @State private var showingImagePicker = false
    @State private var showingPhotoPicker = false
    @State private var showingSourcePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isLoading = false
    
    @Environment(\.dynamicTypeSize) private var dts
    @State private var extra: CGFloat = 0
    let multiple: CGFloat = 1.48
    
    private let textLimit = 100
    
    init(date: Date) {
        self.date = date
        self._selectedDate = State(initialValue: date)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                if let selectedImage = selectedImage {
                    imagePreviewSection(selectedImage)
                } else {
                    imageSelectionSection
                }
                
                textInputSection
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button {
                        showingDatePicker = true
                    } label: {
                        Text(selectedDate, format: .dateTime.year().month().day())
                            .fontWeight(.semibold)
                    }
                    .popover(isPresented: $showingDatePicker, arrowEdge: .top) {
                        DatePicker(
                            "",
                            selection: $selectedDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .frame(minWidth: 320)
                        .padding()
                        .presentationCompactAdaptation(.popover)
                        .onChange(of: selectedDate) { _, _ in
                            showingDatePicker = false
                        }
                    }
                }
            }
            .background(
                GlassNavigationButtons(
                    onCancel: { dismiss() },
                    onSave: { saveEntry() },
                    isSaveDisabled: selectedImage == nil || isLoading
                )
            )
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
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
        }
    }
    
    private func imagePreviewSection(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            // .frame(maxHeight: 300)
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
    
    private var imageSelectionSection: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
                .onTapGesture {
                    showingSourcePicker = true
                }
        }
        .padding(.vertical, 24)
        .confirmationDialog(String(localized: "add_entry.add_photo"), isPresented: $showingSourcePicker) {
            Button(String(localized: "add_entry.camera")) {
                showingImagePicker = true
            }
            Button(String(localized: "add_entry.photo_library")) {
                showingPhotoPicker = true
            }
            Button(String(localized: "common.cancel"), role: .cancel) { }
        }
    }
    
    private var textInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField(String(localized: "add_entry.write_line"), text: $entryText, axis: .vertical)
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
                .onChange(of: entryText) { _, newValue in
                    if newValue.count > textLimit {
                        entryText = String(newValue.prefix(textLimit))
                    }
                }

            HStack{
                Spacer()
                Text("\(entryText.count)/\(textLimit)")
                    .font(.caption)
                    .foregroundColor(entryText.count > textLimit ? .red : .secondary)
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
        return .daygramFont(forTextStyle: .title3, relativeTo: .title3)
    }
    
    private func loadPhotoFromPicker(_ item: PhotosPickerItem) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    selectedImage = image
                }
            }
        } catch {
            print("Error loading photo: \(error)")
        }
    }
    
    private func saveEntry() {
        guard let image = selectedImage else { return }
        
        isLoading = true
        
        let (imageFileName, thumbnailFileName) = ImageStorageManager.shared.saveImage(image)
        
        guard let imageFileName = imageFileName,
              let thumbnailFileName = thumbnailFileName else {
            isLoading = false
            return
        }
        
        let entry = MemoryEntry(
            date: selectedDate,
            text: entryText.trimmingCharacters(in: .whitespacesAndNewlines),
            imageFileName: imageFileName,
            thumbnailFileName: thumbnailFileName
        )
        
        modelContext.insert(entry)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving entry: \(error)")
            ImageStorageManager.shared.deleteEntry(
                imageFileName: imageFileName,
                thumbnailFileName: thumbnailFileName
            )
        }
        
        isLoading = false
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    AddEntryView(date: Date())
        .modelContainer(for: MemoryEntry.self, inMemory: true)
}