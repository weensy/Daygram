import Foundation
import UIKit
import Vision
import FoundationModels

/// Represents extracted features from an image analysis
struct ImageFeatures {
    let scene: String       // e.g., "outdoor", "beach", "home"
    let objects: [String]   // e.g., ["baby", "toy", "grass"]
    let mood: String        // e.g., "joyful", "peaceful", "playful"
}

/// Analyzes images and generates one-line diary suggestions using on-device AI
@available(iOS 26.0, *)
actor ImageDescriptionService {
    static let shared = ImageDescriptionService()
    
    private init() {}
    
    // MARK: - Public API
    
    /// Generates a one-line diary description for the given image
    /// - Parameter image: The photo to analyze
    /// - Returns: A suggested diary line based on image content
    func generateDescription(for image: UIImage) async throws -> String {
        // Step 1: Extract image features using Vision framework
        let imageFeatures = try await analyzeImage(image)
        
        // Step 2: Generate diary line using Foundation Models
        let description = try await generateDiaryLine(from: imageFeatures)
        
        return description
    }
    
    // MARK: - Image Analysis
    
    /// Extracts visual features from an image using Vision framework
    private func analyzeImage(_ image: UIImage) async throws -> ImageFeatures {
        guard let cgImage = image.cgImage else {
            throw ImageDescriptionError.invalidImage
        }
        
        // Run classification and object detection in parallel
        async let sceneResult = classifyScene(cgImage: cgImage)
        async let objectsResult = detectObjects(cgImage: cgImage)
        
        let scene = try await sceneResult
        let objects = try await objectsResult
        
        // Derive mood from scene and objects
        let mood = deriveMood(scene: scene, objects: objects)
        
        return ImageFeatures(scene: scene, objects: objects, mood: mood)
    }
    
    /// Classifies the scene in the image
    private func classifyScene(cgImage: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNClassificationObservation],
                      let topResult = observations.first else {
                    continuation.resume(returning: "unknown scene")
                    return
                }
                
                // Get top classification with confidence > 0.3
                let relevantResults = observations.prefix(3).filter { $0.confidence > 0.3 }
                let scene = relevantResults.map { $0.identifier.replacingOccurrences(of: "_", with: " ") }
                    .joined(separator: ", ")
                
                continuation.resume(returning: scene.isEmpty ? "everyday moment" : scene)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Detects objects in the image using Vision's built-in recognition
    private func detectObjects(cgImage: CGImage) async throws -> [String] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeAnimalsRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let animals = (request.results as? [VNRecognizedObjectObservation])?.compactMap { observation in
                    observation.labels.first?.identifier
                } ?? []
                
                continuation.resume(returning: animals)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Derives mood from scene and detected objects
    private func deriveMood(scene: String, objects: [String]) -> String {
        let sceneKeywords = scene.lowercased()
        
        // Simple mood inference based on scene keywords
        if sceneKeywords.contains("outdoor") || sceneKeywords.contains("beach") || sceneKeywords.contains("park") {
            return "adventurous and free"
        } else if sceneKeywords.contains("baby") || sceneKeywords.contains("child") || objects.contains("cat") || objects.contains("dog") {
            return "warm and loving"
        } else if sceneKeywords.contains("food") || sceneKeywords.contains("meal") {
            return "cozy and content"
        } else if sceneKeywords.contains("sunset") || sceneKeywords.contains("sky") {
            return "peaceful and reflective"
        } else if sceneKeywords.contains("celebration") || sceneKeywords.contains("party") {
            return "joyful and festive"
        }
        
        return "meaningful and heartfelt"
    }
    
    // MARK: - Diary Line Generation
    
    /// Generates a diary line from extracted image features using Foundation Models
    private func generateDiaryLine(from features: ImageFeatures) async throws -> String {
        let session = LanguageModelSession()
        
        // Get the user's preferred language for the prompt
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        let languageName = Locale(identifier: "en").localizedString(forIdentifier: preferredLanguage) ?? "English"
        
        var promptParts: [String] = []
        promptParts.append("Based on these image features, write a warm one-line diary entry:")
        promptParts.append("- Scene: \(features.scene)")
        
        if !features.objects.isEmpty {
            promptParts.append("- Subjects: \(features.objects.joined(separator: ", "))")
        }
        
        promptParts.append("- Mood: \(features.mood)")
        promptParts.append("")
        promptParts.append("Requirements:")
        promptParts.append("- Keep it under 80 characters")
        promptParts.append("- Make it personal and nostalgic")
        promptParts.append("- Write in \(languageName)")
        promptParts.append("- Do not use hashtags or emojis")
        promptParts.append("- Output only the diary line, nothing else")
        
        let prompt = promptParts.joined(separator: "\n")
        let response = try await session.respond(to: prompt)
        
        // Clean up the response
        var result = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove quotes if present
        if result.hasPrefix("\"") && result.hasSuffix("\"") {
            result = String(result.dropFirst().dropLast())
        }
        
        return result
    }
}

// MARK: - Errors

enum ImageDescriptionError: LocalizedError {
    case invalidImage
    case analysisFaild
    case generationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Failed to process the image"
        case .analysisFaild:
            return "Failed to analyze the image"
        case .generationFailed:
            return "Failed to generate description"
        }
    }
}
