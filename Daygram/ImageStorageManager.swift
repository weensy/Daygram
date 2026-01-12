import UIKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

class ImageStorageManager {
    static let shared = ImageStorageManager()
    
    private let documentsDirectory: URL
    private let imagesDirectory: URL
    private let thumbnailsDirectory: URL
    
    private init() {
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        imagesDirectory = documentsDirectory.appendingPathComponent("Images")
        thumbnailsDirectory = documentsDirectory.appendingPathComponent("Thumbnails")
        
        createDirectoriesIfNeeded()
    }
    
    private func createDirectoriesIfNeeded() {
        try? FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: thumbnailsDirectory, withIntermediateDirectories: true)
    }
    
    private func heicData(from image: UIImage, compressionQuality: CGFloat) -> Data? {
        // Normalize orientation by redrawing the image
        // This ensures the orientation is baked into the pixel data
        let normalizedImage: UIImage
        if image.imageOrientation == .up {
            normalizedImage = image
        } else {
            UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
            image.draw(in: CGRect(origin: .zero, size: image.size))
            normalizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        }
        
        guard let cgImage = normalizedImage.cgImage else { return nil }
        
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.heic.identifier as CFString,
            1,
            nil
        ) else { return nil }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality
        ]
        
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        
        return data as Data
    }
    
    func saveImage(_ image: UIImage) -> (imageFileName: String?, thumbnailFileName: String?) {
        let imageFileName = "\(UUID().uuidString).heic"
        let thumbnailFileName = "\(UUID().uuidString)_thumb.heic"
        
        let thumbnailImage = resizeImage(image, maxDimension: 400)
        
        guard let imageData = heicData(from: image, compressionQuality: 0.9),
              let thumbnailData = heicData(from: thumbnailImage, compressionQuality: 0.8) else {
            return (nil, nil)
        }
        
        let imageURL = imagesDirectory.appendingPathComponent(imageFileName)
        let thumbnailURL = thumbnailsDirectory.appendingPathComponent(thumbnailFileName)
        
        do {
            try imageData.write(to: imageURL)
            try thumbnailData.write(to: thumbnailURL)
            return (imageFileName, thumbnailFileName)
        } catch {
            print("Error saving images: \(error)")
            return (nil, nil)
        }
    }
    
    func loadImage(fileName: String) -> UIImage? {
        let imageURL = imagesDirectory.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: imageURL.path)
    }
    
    func loadThumbnail(fileName: String) -> UIImage? {
        let thumbnailURL = thumbnailsDirectory.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: thumbnailURL.path)
    }
    
    func deleteImage(fileName: String) {
        let imageURL = imagesDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: imageURL)
    }
    
    func deleteThumbnail(fileName: String) {
        let thumbnailURL = thumbnailsDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: thumbnailURL)
    }
    
    func deleteEntry(imageFileName: String, thumbnailFileName: String) {
        deleteImage(fileName: imageFileName)
        deleteThumbnail(fileName: thumbnailFileName)
    }
    
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        
        if ratio >= 1 {
            return image
        }
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
}