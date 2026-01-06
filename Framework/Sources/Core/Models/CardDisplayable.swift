import SwiftUI

/// Protocol for items that can be displayed in card components
/// This allows card components to extract meaningful data from generic items
/// 
/// Note: Color configuration has been moved to PresentationHints (Issue #142)
/// to allow models to be SwiftUI-free for Intent extensions.
public protocol CardDisplayable {
    /// The primary title to display in the card
    var cardTitle: String { get }
    
    /// Optional subtitle to display in the card
    var cardSubtitle: String? { get }
    
    /// Optional description to display in the card
    var cardDescription: String? { get }
    
    /// Optional icon name to display in the card
    var cardIcon: String? { get }
    
    // cardColor removed - use PresentationHints.colorMapping, itemColorProvider, or defaultColor instead
}

/// Default implementation for CardDisplayable protocol
/// This provides a fallback for items that don't conform to the protocol
public extension CardDisplayable {
    var cardTitle: String { "Item" }
    var cardSubtitle: String? { nil }
    var cardDescription: String? { nil }
    var cardIcon: String? { "star.fill" }
    // cardColor removed - configure via PresentationHints instead
}

/// Smart fallback helper for items that don't conform to CardDisplayable
/// Uses reflection to extract meaningful content instead of generic "Item"
public struct CardDisplayHelper {
    
    /// Extract meaningful title from any item using hints or reflection
    public static func extractTitle(from item: Any, hints: PresentationHints? = nil) -> String? {
        // Priority 1: Check for configured title property in hints (developer's explicit intent)
        var shouldFallbackToReflection = false
        if let hints = hints,
           let titleProperty = hints.customPreferences["itemTitleProperty"] {
            // Empty property name should be ignored and fall back to reflection
            if titleProperty.isEmpty {
                shouldFallbackToReflection = true
            } else {
                // Check if property exists first
                let propertyExists = propertyExists(in: item, propertyName: titleProperty)
                
                if propertyExists {
                    // Property exists - extract its value
                    if let value = extractPropertyValue(from: item, propertyName: titleProperty) as? String {
                        // Use whatever the hint extracts, including empty strings
                        // UNLESS there's an explicit default value configured
                        if value.isEmpty {
                            if let defaultValue = hints.customPreferences["itemTitleDefault"],
                               !defaultValue.isEmpty {
                                return defaultValue
                            }
                            // No default configured - return nil for empty string
                            return nil
                        }
                        return value
                    } else {
                        // Property exists but is nil or not a String - check for default
                        if let defaultValue = hints.customPreferences["itemTitleDefault"],
                           !defaultValue.isEmpty {
                            return defaultValue
                        }
                        // No default configured - return nil (don't fall back)
                        return nil
                    }
                } else {
                    // Property doesn't exist - check for default, then fall back to reflection
                    if let defaultValue = hints.customPreferences["itemTitleDefault"],
                       !defaultValue.isEmpty {
                        return defaultValue
                    }
                    
                    // Property doesn't exist and no default - fall back to reflection
                    shouldFallbackToReflection = true
                }
            }
        }
        
        // Use reflection if no hints were provided OR if hint property doesn't exist
        if hints == nil || shouldFallbackToReflection {
            // Use reflection to find common title properties
            let mirror = Mirror(reflecting: item)
            
            // Look for common title property names (expanded list)
            let titleProperties = [
                "title", "name", "label", "text", "heading", "caption", 
                "displayName", "displayTitle", "itemName", "itemTitle",
                "content", "value", "description", "summary", "info",
                "identifier", "id", "key", "primary", "main"
            ]
            
            // First pass: look for exact property name matches
            for child in mirror.children {
                if let label = child.label,
                   titleProperties.contains(label.lowercased()),
                   let value = child.value as? String,
                   !value.isEmpty {
                    return value
                }
            }
            
            // Second pass: look for any String property that might be meaningful
            var stringCandidates: [(String, String)] = []
            for child in mirror.children {
                if let value = child.value as? String,
                   !value.isEmpty,
                   value.count < 200, // Reasonable length
                   !value.contains("@"), // Skip email-like strings
                   !value.contains("://"), // Skip URLs
                   !value.hasPrefix("0x"), // Skip memory addresses
                   value != "Optional" { // Skip Swift optional descriptions
                    
                    let label = child.label ?? "unnamed"
                    stringCandidates.append((label, value))
                }
            }
            
            // Sort candidates by preference (shorter labels first, then by length)
            stringCandidates.sort { first, second in
                let firstLabel = first.0.lowercased()
                let secondLabel = second.0.lowercased()
                
                // Prefer properties that sound like titles
                let firstIsTitleLike = titleProperties.contains(where: { firstLabel.contains($0) })
                let secondIsTitleLike = titleProperties.contains(where: { secondLabel.contains($0) })
                
                if firstIsTitleLike && !secondIsTitleLike { return true }
                if !firstIsTitleLike && secondIsTitleLike { return false }
                
                // Then prefer shorter labels
                if first.0.count != second.0.count {
                    return first.0.count < second.0.count
                }
                
                // Finally prefer shorter values
                return first.1.count < second.1.count
            }
            
            // Return the best candidate
            if let bestCandidate = stringCandidates.first {
                return bestCandidate.1
            }
        }
        
        // Priority 3: Check if item conforms to CardDisplayable and has meaningful content (fallback after reflection)
        if let displayable = item as? CardDisplayable {
            let title = displayable.cardTitle
            // Only use if it's not the default hardcoded fallback
            if title != "Item" && !title.isEmpty {
                return title
            }
        }
        
        // No meaningful content found - return nil instead of hardcoded fallback
        return nil
    }
    
    /// Extract meaningful subtitle from any item using hints or reflection
    public static func extractSubtitle(from item: Any, hints: PresentationHints? = nil) -> String? {
        // Priority 1: Check for configured subtitle property in hints (developer's explicit intent)
        var shouldFallbackToReflection = false
        if let hints = hints,
           let subtitleProperty = hints.customPreferences["itemSubtitleProperty"],
           !subtitleProperty.isEmpty {
            // Check if property exists first
            let propertyExists = propertyExists(in: item, propertyName: subtitleProperty)
            
            if propertyExists {
                // Property exists - extract its value
                if let value = extractPropertyValue(from: item, propertyName: subtitleProperty) as? String {
                    // Use whatever the hint extracts, including empty strings
                    // UNLESS there's an explicit default value configured
                    if value.isEmpty {
                        if let defaultValue = hints.customPreferences["itemSubtitleDefault"],
                           !defaultValue.isEmpty {
                            return defaultValue
                        }
                        // No default configured - return nil for empty string
                        return nil
                    }
                    return value
                } else {
                    // Property exists but is nil or not a String - check for default
                    if let defaultValue = hints.customPreferences["itemSubtitleDefault"],
                       !defaultValue.isEmpty {
                        return defaultValue
                    }
                    // No default configured - return nil (don't fall back)
                    return nil
                }
            } else {
                // Property doesn't exist - check for default, then fall back to reflection
                if let defaultValue = hints.customPreferences["itemSubtitleDefault"],
                   !defaultValue.isEmpty {
                    return defaultValue
                }
                
                // Property doesn't exist and no default - fall back to reflection
                shouldFallbackToReflection = true
            }
        }
        
        // Use reflection if no hints were provided OR if hint property doesn't exist
        if hints == nil || shouldFallbackToReflection {
            // Use reflection to find common subtitle properties
            let mirror = Mirror(reflecting: item)
            
            // Look for common subtitle property names (expanded list)
            let subtitleProperties = [
                "subtitle", "description", "detail", "summary", "info",
                "secondary", "secondaryText", "detailText", "caption",
                "explanation", "notes", "comment", "message"
            ]
            
            // First pass: look for exact property name matches
            for child in mirror.children {
                if let label = child.label,
                   subtitleProperties.contains(label.lowercased()),
                   let value = child.value as? String,
                   !value.isEmpty {
                    return value
                }
            }
            
            // Second pass: look for String properties that might be subtitles
            // (longer strings that weren't used as titles, but exclude clearly non-subtitle properties)
            let nonSubtitleProperties = ["id", "status", "priority", "state", "type", "kind", "category", "tag", "label", "identifier"]
            var subtitleCandidates: [(String, String)] = []
            for child in mirror.children {
                if let label = child.label,
                   !nonSubtitleProperties.contains(label.lowercased()),
                   let value = child.value as? String,
                   !value.isEmpty,
                   value.count > 10, // Subtitles should be longer than titles
                   value.count < 300, // But not too long
                   !value.contains("@"), // Skip email-like strings
                   !value.contains("://"), // Skip URLs
                   !value.hasPrefix("0x"), // Skip memory addresses
                   value != "Optional" { // Skip Swift optional descriptions
                    
                    subtitleCandidates.append((label, value))
                }
            }
            
            // Sort candidates by preference
            subtitleCandidates.sort { first, second in
                let firstLabel = first.0.lowercased()
                let secondLabel = second.0.lowercased()
                
                // Prefer properties that sound like subtitles
                let firstIsSubtitleLike = subtitleProperties.contains(where: { firstLabel.contains($0) })
                let secondIsSubtitleLike = subtitleProperties.contains(where: { secondLabel.contains($0) })
                
                if firstIsSubtitleLike && !secondIsSubtitleLike { return true }
                if !firstIsSubtitleLike && secondIsSubtitleLike { return false }
                
                // Then prefer shorter labels
                if first.0.count != second.0.count {
                    return first.0.count < second.0.count
                }
                
                // Finally prefer shorter values
                return first.1.count < second.1.count
            }
            
            // Return the best candidate
            return subtitleCandidates.first?.1
        }
        
        // Priority 3: Check if item conforms to CardDisplayable and has meaningful content (fallback after reflection)
        if let displayable = item as? CardDisplayable,
           let subtitle = displayable.cardSubtitle,
           !subtitle.isEmpty {
            return subtitle
        }
        
        // No meaningful content found - return nil
        return nil
    }
    
    /// Extract meaningful icon from any item using hints or reflection
    public static func extractIcon(from item: Any, hints: PresentationHints? = nil) -> String? {
        // Priority 1: Check for configured icon property in hints (developer's explicit intent)
        var shouldFallbackToReflection = false
        if let hints = hints,
           let iconProperty = hints.customPreferences["itemIconProperty"],
           !iconProperty.isEmpty {
            // Check if property exists first
            let propertyExists = propertyExists(in: item, propertyName: iconProperty)
            
            if propertyExists {
                // Property exists - extract its value
                if let value = extractPropertyValue(from: item, propertyName: iconProperty) as? String {
                    // Use whatever the hint extracts, including empty strings
                    // UNLESS there's an explicit default value configured
                    if value.isEmpty {
                        if let defaultValue = hints.customPreferences["itemIconDefault"],
                           !defaultValue.isEmpty {
                            return defaultValue
                        }
                        // No default configured - return nil for empty string
                        return nil
                    }
                    return value
                } else {
                    // Property exists but is nil or not a String - check for default
                    if let defaultValue = hints.customPreferences["itemIconDefault"],
                       !defaultValue.isEmpty {
                        return defaultValue
                    }
                    // No default configured - return nil (don't fall back)
                    return nil
                }
            } else {
                // Property doesn't exist - check for default, then fall back to reflection
                if let defaultValue = hints.customPreferences["itemIconDefault"],
                   !defaultValue.isEmpty {
                    return defaultValue
                }
                
                // Property doesn't exist and no default - fall back to reflection
                shouldFallbackToReflection = true
            }
        }
        
        // Priority 2: Use reflection if no hints were provided OR if hint property doesn't exist
        if hints == nil || shouldFallbackToReflection {
        
            // Use reflection to find icon-related properties
            let mirror = Mirror(reflecting: item)
            
            // Look for icon properties
            let iconProperties = ["icon", "image", "symbol", "emoji"]
            for child in mirror.children {
                if let label = child.label,
                   iconProperties.contains(label.lowercased()),
                   let value = child.value as? String,
                   !value.isEmpty {
                    return value
                }
            }
        }
        
        // Priority 3: Check if item conforms to CardDisplayable and has meaningful content (fallback after reflection)
        if let displayable = item as? CardDisplayable,
           let icon = displayable.cardIcon,
           icon != "star.fill" && !icon.isEmpty {
            return icon
        }
        
        // No meaningful content found - return nil instead of hardcoded fallback
        return nil
    }
    
    /// Extract meaningful color from any item using hints or reflection
    /// 
    /// Priority order:
    /// 1. PresentationHints.colorMapping (by type)
    /// 2. PresentationHints.itemColorProvider (per-item)
    /// 3. PresentationHints.defaultColor
    /// 4. customPreferences["itemColorProperty"] (legacy support)
    /// 5. customPreferences["itemColorDefault"] (legacy support)
    /// 6. Reflection (look for color/tint/accent properties)
    /// 7. nil (no fallback)
    public static func extractColor(from item: Any, hints: PresentationHints? = nil) -> Color? {
        guard let hints = hints else {
            // No hints - try reflection only
            return extractColorViaReflection(from: item)
        }
        
        // Priority 1: Type-based color mapping
        if let colorMapping = hints.colorMapping {
            let itemType = ObjectIdentifier(type(of: item))
            if let color = colorMapping[itemType] {
                return color
            }
        }
        
        // Priority 2: Per-item color provider
        if let itemColorProvider = hints.itemColorProvider,
           let displayable = item as? CardDisplayable {
            if let color = itemColorProvider(displayable) {
                return color
            }
        }
        
        // Priority 3: Default color
        if let defaultColor = hints.defaultColor {
            return defaultColor
        }
        
        // Priority 4: Legacy customPreferences["itemColorProperty"] support
        var shouldFallbackToReflection = false
        if let colorProperty = hints.customPreferences["itemColorProperty"],
           !colorProperty.isEmpty {
            // Check if property exists first
            let propertyExists = propertyExists(in: item, propertyName: colorProperty)
            
            if propertyExists {
                // Property exists - extract its value
                if let value = extractPropertyValue(from: item, propertyName: colorProperty) as? Color {
                    return value
                } else {
                    // Property exists but is nil or not a Color - check for default
                    if let defaultValue = hints.customPreferences["itemColorDefault"],
                       !defaultValue.isEmpty {
                        return parseColorString(defaultValue)
                    }
                    // No default configured - return nil (don't fall back)
                    return nil
                }
            } else {
                // Property doesn't exist - check for default, then fall back to reflection
                if let defaultValue = hints.customPreferences["itemColorDefault"],
                   !defaultValue.isEmpty {
                    return parseColorString(defaultValue)
                }
                
                // Property doesn't exist and no default - fall back to reflection
                shouldFallbackToReflection = true
            }
        }
        
        // Priority 5: Legacy customPreferences["itemColorDefault"] support (when no property specified)
        if shouldFallbackToReflection,
           let defaultValue = hints.customPreferences["itemColorDefault"],
           !defaultValue.isEmpty {
            return parseColorString(defaultValue)
        }
        
        // Priority 6: Reflection
        if hints.customPreferences["itemColorProperty"] == nil || shouldFallbackToReflection {
            if let color = extractColorViaReflection(from: item) {
                return color
            }
        }
        
        // Priority 7: No color found
        return nil
    }
    
    /// Extract color via reflection (helper method)
    private static func extractColorViaReflection(from item: Any) -> Color? {
        let mirror = Mirror(reflecting: item)
        
        // Look for color properties
        let colorProperties = ["color", "tint", "accent"]
        for child in mirror.children {
            if let label = child.label,
               colorProperties.contains(label.lowercased()),
               let value = child.value as? Color {
                return value
            }
        }
        
        return nil
    }
    
    /// Helper method to check if a property exists in an item
    private static func propertyExists(in item: Any, propertyName: String) -> Bool {
        let mirror = Mirror(reflecting: item)
        for child in mirror.children {
            if child.label == propertyName {
                return true
            }
        }
        return false
    }
    
    /// Helper method to extract property value by name using reflection
    private static func extractPropertyValue(from item: Any, propertyName: String) -> Any? {
        let mirror = Mirror(reflecting: item)
        for child in mirror.children {
            if child.label == propertyName {
                return child.value
            }
        }
        return nil
    }
    
    /// Helper method to parse color string to Color
    private static func parseColorString(_ colorString: String) -> Color {
        let lowercased = colorString.lowercased()
        switch lowercased {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "gray", "grey": return .gray
        case "black": return .black
        case "white": return .white
        case "cyan": return .cyan
        case "mint": return .mint
        case "teal": return .teal
        case "indigo": return .indigo
        case "brown": return .brown
        default: return .blue // Default fallback
        }
    }
}

/// Extension to make GenericDataItem conform to CardDisplayable
/// This is the minimal version used internally by the framework
extension GenericDataItem: CardDisplayable {
    public var cardTitle: String { title }
    public var cardSubtitle: String? { subtitle }
    public var cardDescription: String? { nil }
    public var cardIcon: String? { "doc.text" }
    // cardColor removed - configure via PresentationHints instead
}

// NOTE: Other generic type CardDisplayable extensions have been moved to 
// Framework/Examples/GenericTypes.swift. Those are example types and 
// should not be in the main framework sources.
