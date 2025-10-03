import Foundation
import SwiftData

@Model
final class MemoryEntry {
    var id: UUID
    var date: Date
    var text: String
    var imageFileName: String
    var thumbnailFileName: String
    var createdAt: Date
    var updatedAt: Date
    
    init(date: Date, text: String, imageFileName: String, thumbnailFileName: String) {
        self.id = UUID()
        self.date = date
        self.text = text
        self.imageFileName = imageFileName
        self.thumbnailFileName = thumbnailFileName
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func updateText(_ newText: String) {
        self.text = newText
        self.updatedAt = Date()
    }
}

extension MemoryEntry {
    var dayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}