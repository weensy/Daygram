import SwiftUI
import SwiftData

struct ThumbnailIndicatorView: View {
    let entries: [MemoryEntry]
    @Binding var currentIndex: Int
    
    @StateObject private var thumbnailCache = ThumbnailCache.shared
    @State private var scrolledID: Int?
    
    private let thumbnailSize: CGFloat = 44
    private let collapsedWidth: CGFloat = 28
    private let selectedContainerWidth: CGFloat = 56 // Wider for selected
    private let collapsedContainerWidth: CGFloat = 32 // Tighter for unselected
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        let isSelected = index == currentIndex
                        let containerWidth = isSelected ? selectedContainerWidth : collapsedContainerWidth
                        
                        ThumbnailItemView(
                            entry: entry,
                            isSelected: isSelected,
                            width: isSelected ? thumbnailSize : collapsedWidth,
                            height: thumbnailSize
                        )
                        .frame(width: containerWidth)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                scrolledID = index
                            }
                        }
                        .id(index)
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, (geometry.size.width - selectedContainerWidth) / 2, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $scrolledID)
            .onAppear {
                scrolledID = currentIndex
            }
            .onChange(of: scrolledID) { _, newValue in
                if let newValue = newValue, newValue != currentIndex {
                    currentIndex = newValue
                }
            }
            .onChange(of: currentIndex) { _, newValue in
                if scrolledID != newValue {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        scrolledID = newValue
                    }
                }
            }
            .mask(
                HStack(spacing: 0) {
                    // Left fade
                    LinearGradient(
                        colors: [.clear, .white],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 60)
                    
                    // Center (fully visible)
                    Rectangle()
                        .fill(.white)
                    
                    // Right fade
                    LinearGradient(
                        colors: [.white, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 60)
                }
            )
        }
        .frame(height: thumbnailSize + 16)
    }
}

// MARK: - Thumbnail Item View
private struct ThumbnailItemView: View {
    let entry: MemoryEntry
    let isSelected: Bool
    let width: CGFloat
    let height: CGFloat
    
    @StateObject private var thumbnailCache = ThumbnailCache.shared
    @State private var thumbnailImage: UIImage?
    
    var body: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .frame(width: width, height: height)
            .overlay(
                Group {
                    if let image = thumbnailImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        ProgressView()
                            .scaleEffect(0.5)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .onAppear {
                loadThumbnail()
            }
    }
    
    private func loadThumbnail() {
        if let cached = thumbnailCache.getThumbnail(for: entry.thumbnailFileName) {
            thumbnailImage = cached
            return
        }
        
        Task {
            let fileName = entry.thumbnailFileName
            let thumbnail = await Task.detached(priority: .userInitiated) {
                return ImageStorageManager.shared.loadThumbnail(fileName: fileName)
            }.value
            
            if let thumbnail = thumbnail {
                thumbnailImage = thumbnail
                thumbnailCache.cacheThumbnail(thumbnail, fileName: fileName)
            }
        }
    }
}

#Preview {
    @Previewable @State var currentIndex = 1
    
    return ThumbnailIndicatorView(
        entries: [
            MemoryEntry(date: Date(), text: "First", imageFileName: "1.jpg", thumbnailFileName: "1_thumb.jpg"),
            MemoryEntry(date: Date(), text: "Second", imageFileName: "2.jpg", thumbnailFileName: "2_thumb.jpg"),
            MemoryEntry(date: Date(), text: "Third", imageFileName: "3.jpg", thumbnailFileName: "3_thumb.jpg"),
        ],
        currentIndex: $currentIndex
    )
    .background(Color.black.opacity(0.5))
    .modelContainer(for: MemoryEntry.self, inMemory: true)
}
