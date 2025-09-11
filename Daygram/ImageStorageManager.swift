import UIKit
import Foundation

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
    
    func saveImage(_ image: UIImage) -> (imageFileName: String?, thumbnailFileName: String?) {
        let imageFileName = "\(UUID().uuidString).jpg"
        let thumbnailFileName = "\(UUID().uuidString)_thumb.jpg"
        
        let resizedImage = resizeImage(image, maxDimension: 3000)
        let thumbnailImage = resizeImage(image, maxDimension: 400)
        
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8),
              let thumbnailData = thumbnailImage.jpegData(compressionQuality: 0.8) else {
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