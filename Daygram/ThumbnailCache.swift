import UIKit
import SwiftUI

class ThumbnailCache: ObservableObject {
    static let shared = ThumbnailCache()
    
    private var thumbnailCache: [String: UIImage] = [:]
    private let imageCache = NSCache<NSString, UIImage>()
    private let cacheQueue = DispatchQueue(label: "image.cache", qos: .userInitiated)
    
    private let maxDisplayWidth: CGFloat = 1320
    
    private init() {
        // Limit cache to prevent memory issues
        imageCache.countLimit = 15  // Max 15 images in cache
        imageCache.totalCostLimit = 150 * 1024 * 1024  // 150MB limit
    }
    
    func getThumbnail(for fileName: String) -> UIImage? {
        return thumbnailCache[fileName]
    }
    
    func getImage(for fileName: String) -> UIImage? {
        return imageCache.object(forKey: fileName as NSString)
    }
    
    func preloadThumbnails(for entries: [MemoryEntry]) {
        cacheQueue.async { [weak self] in
            for entry in entries {
                if self?.thumbnailCache[entry.thumbnailFileName] == nil {
                    if let thumbnail = ImageStorageManager.shared.loadThumbnail(fileName: entry.thumbnailFileName) {
                        DispatchQueue.main.async {
                            self?.thumbnailCache[entry.thumbnailFileName] = thumbnail
                        }
                    }
                }
            }
        }
    }
    
    func preloadImage(for entry: MemoryEntry) {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.imageCache.object(forKey: entry.imageFileName as NSString) == nil {
                if let image = ImageStorageManager.shared.loadImage(fileName: entry.imageFileName) {
                    // Resize for display to save memory
                    let resizedImage = self.resizeForDisplay(image)
                    let cost = Int(resizedImage.size.width * resizedImage.size.height * 4) // RGBA bytes
                    
                    DispatchQueue.main.async {
                        self.imageCache.setObject(resizedImage, forKey: entry.imageFileName as NSString, cost: cost)
                    }
                }
            }
        }
    }
    
    func clearCache() {
        thumbnailCache.removeAll()
        imageCache.removeAllObjects()
    }
    
    func removeThumbnail(fileName: String) {
        thumbnailCache.removeValue(forKey: fileName)
    }
    
    func removeImage(fileName: String) {
        imageCache.removeObject(forKey: fileName as NSString)
    }
    
    @discardableResult
    func cacheImage(_ image: UIImage, fileName: String) -> UIImage {
        let resizedImage = resizeForDisplay(image)
        let cost = Int(resizedImage.size.width * resizedImage.size.height * 4)
        imageCache.setObject(resizedImage, forKey: fileName as NSString, cost: cost)
        return resizedImage
    }
    
    func cacheThumbnail(_ image: UIImage, fileName: String) {
        thumbnailCache[fileName] = image
    }
    
    // MARK: - Private
    
    private func resizeForDisplay(_ image: UIImage) -> UIImage {
        let size = image.size
        
        // Only resize if width exceeds max
        guard size.width > maxDisplayWidth else {
            return image
        }
        
        let ratio = maxDisplayWidth / size.width
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
