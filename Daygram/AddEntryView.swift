import SwiftUI
import PhotosUI
import UIKit

struct AddEntryView: View {
    let date: Date
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedImage: UIImage?
    @State private var entryText = ""
    @State private var showingImagePicker = false
    @State private var showingPhotoPicker = false
    @State private var showingSourcePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isLoading = false
    
    private let textLimit = 100
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()
                if let selectedImage = selectedImage {
                    imagePreviewSection(selectedImage)
                } else {
                    imageSelectionSection
                }
                
                textInputSection
                
                Spacer()
            }
            .navigationTitle("New Memory")
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
                    .disabled(selectedImage == nil || isLoading)
                    .fontWeight(.medium)
                }
            }
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
        VStack(spacing: 16) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                // .frame(maxHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
            
            Button("Change Photo") {
                showingSourcePicker = true
            }
            .font(.headline)
            .foregroundColor(.accentColor)
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
        .padding(.vertical, 24)
    }
    
    private var imageSelectionSection: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Button("Add a Photo") {
                showingSourcePicker = true
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .confirmationDialog("Add a Photo", isPresented: $showingSourcePicker) {
                Button("Camera") {
                    showingImagePicker = true
                }
                Button("Photo Library") {
                    showingPhotoPicker = true
                }
                Button("Cancel", role: .cancel) { }
            }
        }
        
        .padding(.vertical, 24)
    }
    
    private var textInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Write a Line", text: $entryText, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...5)
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
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        
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
        
        let entry = DiaryEntry(
            date: date,
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
        .modelContainer(for: DiaryEntry.self, inMemory: true)
}