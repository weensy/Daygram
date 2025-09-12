import UIKit
import SwiftUI

class ThumbnailCache: ObservableObject {
    static let shared = ThumbnailCache()
    
    private var thumbnailCache: [String: UIImage] = [:]
    private var imageCache: [String: UIImage] = [:]
    private let cacheQueue = DispatchQueue(label: "image.cache", qos: .userInitiated)
    
    private init() {}
    
    func getThumbnail(for fileName: String) -> UIImage? {
        return thumbnailCache[fileName]
    }
    
    func getImage(for fileName: String) -> UIImage? {
        return imageCache[fileName]
    }
    
    func preloadThumbnails(for entries: [DiaryEntry]) {
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
    
    func preloadImage(for entry: DiaryEntry) {
        cacheQueue.async { [weak self] in
            if self?.imageCache[entry.imageFileName] == nil {
                if let image = ImageStorageManager.shared.loadImage(fileName: entry.imageFileName) {
                    DispatchQueue.main.async {
                        self?.imageCache[entry.imageFileName] = image
                    }
                }
            }
        }
    }
    
    func clearCache() {
        thumbnailCache.removeAll()
        imageCache.removeAll()
    }
    
    func removeThumbnail(fileName: String) {
        thumbnailCache.removeValue(forKey: fileName)
    }
    
    func removeImage(fileName: String) {
        imageCache.removeValue(forKey: fileName)
    }
    
    func cacheImage(_ image: UIImage, fileName: String) {
        imageCache[fileName] = image
    }
}