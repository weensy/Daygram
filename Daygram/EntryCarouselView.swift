import SwiftUI
import SwiftData

struct EntryCarouselView: View {
    let entries: [MemoryEntry]
    @Binding var currentIndex: Int
    var isScrollDisabled: Bool
    var onDismiss: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var thumbnailCache = ThumbnailCache.shared
    @State private var scrolledID: Int?
    @State private var didPreloadInitialRange = false
    
    var body: some View {
        GeometryReader { geometry in
            let cardWidth = min(geometry.size.width - 32, 620)
            let spacing: CGFloat = 16
            
            VStack {
                Spacer()
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: spacing) {
                        ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                            EntryCardView(
                                entry: entry,
                                cardWidth: cardWidth,
                                geometry: geometry,
                                currentIndex: scrolledID ?? currentIndex,
                                index: index
                            )
                            .id(index)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollDisabled(isScrollDisabled)  // Disable scroll during dismiss gesture
                .contentMargins(.horizontal, (geometry.size.width - cardWidth) / 2, for: .scrollContent)
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $scrolledID)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 8)
                        .onChanged { value in
                            guard !isScrollDisabled else { return }
                            let direction = value.translation.width
                            if abs(direction) < 12 {
                                return
                            }
                            let nextIndex = direction < 0 ? currentIndex + 1 : currentIndex - 1
                            preloadNearImages(for: nextIndex)
                        }
                )
                .onAppear {
                    scrolledID = currentIndex
                    preloadInitialRangeIfNeeded(for: currentIndex)
                    preloadNearImages(for: currentIndex)
                }
                .onChange(of: scrolledID) { _, newValue in
                    // Sync scroll position to binding
                    if let newValue = newValue {
                        currentIndex = newValue
                    }
                }
                .onChange(of: currentIndex) { oldValue, newValue in
                    // Sync binding changes to scroll position (from thumbnail tap)
                    if scrolledID != newValue {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            scrolledID = newValue
                        }
                    }
                    preloadNearImages(for: newValue)
                }
                
                Spacer()
            }
        }
    }

    private func preloadNearImages(for index: Int) {
        preloadAround(index: index, radius: 2)
    }

    private func preloadInitialRangeIfNeeded(for index: Int) {
        guard !didPreloadInitialRange else { return }
        didPreloadInitialRange = true
        preloadAround(index: index, radius: 5)
    }

    private func preloadAround(index: Int, radius: Int) {
        guard !entries.isEmpty else { return }
        let maxIndex = entries.count - 1
        for distance in 0...radius {
            let offsets = distance == 0 ? [0] : [distance, -distance]
            for offset in offsets {
                let idx = index + offset
                guard idx >= 0 && idx <= maxIndex else { continue }
                thumbnailCache.preloadImage(for: entries[idx])
            }
        }
    }
}

// MARK: - Entry Card View
private struct EntryCardView: View {
    let entry: MemoryEntry
    let cardWidth: CGFloat
    let geometry: GeometryProxy
    let currentIndex: Int
    let index: Int
    
    @Environment(\.colorScheme) private var colorScheme
    
    // Only load images for cards within ±1 of current index
    private var isNearVisible: Bool {
        abs(index - currentIndex) <= 1
    }
    
    var body: some View {
        EntryDetailView(
            entry: entry,
            onDismiss: nil,
            isEditing: .constant(false),
            editedText: .constant(""),
            onSave: nil,
            shouldLoadImage: isNearVisible
        )
        .frame(width: cardWidth)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            Rectangle()
                .fill(colorScheme == .dark ? Color(.systemGray3) : Color.white)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        // 3D rotation effect for adjacent cards
        .rotation3DEffect(
            .degrees(rotationAngle),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
        .opacity(opacity)
        .scaleEffect(scale)
        .animation(.easeOut(duration: 0.2), value: currentIndex)
    }
    
    private var offset: CGFloat {
        CGFloat(index - currentIndex)
    }
    
    private var rotationAngle: Double {
        // Adjacent cards tilt inward
        let maxRotation: Double = 25
        return -Double(offset) * maxRotation
    }
    
    private var opacity: Double {
        let distance = abs(offset)
        return max(1.0 - Double(distance) * 0.3, 0.5)
    }
    
    private var scale: CGFloat {
        let distance = abs(offset)
        return max(1.0 - distance * 0.1, 0.85)
    }
}

#Preview {
    @Previewable @State var currentIndex = 0
    
    return EntryCarouselView(
        entries: [
            MemoryEntry(date: Date(), text: "First entry", imageFileName: "test1.jpg", thumbnailFileName: "test1_thumb.jpg"),
            MemoryEntry(date: Date().addingTimeInterval(86400), text: "Second entry", imageFileName: "test2.jpg", thumbnailFileName: "test2_thumb.jpg"),
        ],
        currentIndex: $currentIndex,
        isScrollDisabled: false,
        onDismiss: {}
    )
    .modelContainer(for: MemoryEntry.self, inMemory: true)
}
