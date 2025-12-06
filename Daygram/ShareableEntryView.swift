import SwiftUI

/// A view specifically designed for sharing as an image.
/// This mirrors EntryDetailView's layout but is optimized for image rendering.
struct ShareableEntryView: View {
    let entry: MemoryEntry
    let image: UIImage
    let width: CGFloat
    
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
        .frame(width: width)
        .background(Color.white)
    }
    
    private var imageSection: some View {
        Group {
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
        }
    }
    
    private var textSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Empty HStack matching EntryDetailView structure
            }
            
            if !entry.text.isEmpty {
                Text(entry.text)
                    .font(customFont())
                    .lineSpacing(lineSpacing)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
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
    
    private func customFont() -> Font {
        return .daygramFont(forTextStyle: .title3, relativeTo: .title3)
    }
    
    private var lineSpacing: CGFloat {
        let lh = UIFont.preferredFont(forTextStyle: .title3).lineHeight
        return (1.48 - 1.0) * lh
    }
    
    private var dateTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd.yyyy"
        return formatter.string(from: entry.date)
    }
}

/// Utility to render ShareableEntryView as UIImage
struct EntryImageRenderer {
    @MainActor
    static func render(entry: MemoryEntry, image: UIImage, width: CGFloat = 390) -> UIImage? {
        let view = ShareableEntryView(entry: entry, image: image, width: width)
            .environment(\.colorScheme, .light)
        
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        
        return renderer.uiImage
    }
}
