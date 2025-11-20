import SwiftUI
import UIKit

extension UIFont {
    static func daygramFont(size: CGFloat) -> UIFont {
        // Primary: Georgia-Italic (English)
        // Secondary: MaruBuriot-Regular (Korean)
        // Tertiary: KleeOne-SemiBold (Japanese)
        
        let fontNames = [
            "Georgia-Italic",
            "MaruBuriot-Regular",
            "KleeOne-SemiBold"
        ]
        
        // Create the primary font descriptor
        var descriptor = UIFontDescriptor(name: fontNames[0], size: size)
        
        // Create descriptors for fallback fonts
        let fallbackDescriptors = fontNames.dropFirst().map { name in
            return UIFontDescriptor(name: name, size: size)
        }
        
        // Add attributes to the descriptor to specify the cascade list
        let attributes: [UIFontDescriptor.AttributeName: Any] = [
            .cascadeList: fallbackDescriptors
        ]
        
        descriptor = descriptor.addingAttributes(attributes)
        
        return UIFont(descriptor: descriptor, size: size)
    }
}

extension Font {
    static func daygramFont(size: CGFloat, relativeTo textStyle: Font.TextStyle? = nil) -> Font {
        let uiFont = UIFont.daygramFont(size: size)
        
        if let textStyle = textStyle {
            let uiTextStyle = uiTextStyle(from: textStyle)
            let metrics = UIFontMetrics(forTextStyle: uiTextStyle)
            let scaledFont = metrics.scaledFont(for: uiFont)
            return Font(scaledFont)
        } else {
            return Font(uiFont)
        }
    }
    
    // Helper to match the existing usage where size comes from a TextStyle
    static func daygramFont(forTextStyle style: UIFont.TextStyle, relativeTo relativeStyle: Font.TextStyle) -> Font {
        let size = UIFont.preferredFont(forTextStyle: style).pointSize
        return daygramFont(size: size, relativeTo: relativeStyle)
    }
    
    private static func uiTextStyle(from style: Font.TextStyle) -> UIFont.TextStyle {
        switch style {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .body: return .body
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        @unknown default: return .body
        }
    }
}
