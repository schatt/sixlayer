//
//  PhotoPurposeExtensionExample.swift
//  SixLayerFramework
//
//  Example showing how to extend PhotoPurpose with custom purposes and aliases
//  for backward compatibility with vehicle-specific purposes
//

import Foundation
import SixLayerFramework

// MARK: - PhotoPurpose Extension Example

/// Example extension showing how to add custom photo purposes and aliases
/// 
/// This demonstrates:
/// 1. Creating aliases for backward compatibility (vehicle-specific purposes)
/// 2. Creating custom purposes for domain-specific needs
/// 3. Using custom purposes in your application
extension PhotoPurpose {
    // MARK: - Backward Compatibility Aliases
    
    /// Alias for vehicle photos (maps to .general)
    /// Use this for backward compatibility with code that used .vehiclePhoto
    public static let vehiclePhoto = PhotoPurpose.general
    
    /// Alias for fuel receipt photos (maps to .document)
    /// Use this for backward compatibility with code that used .fuelReceipt
    public static let fuelReceipt = PhotoPurpose.document
    
    /// Alias for pump display photos (maps to .document)
    /// Use this for backward compatibility with code that used .pumpDisplay
    public static let pumpDisplay = PhotoPurpose.document
    
    /// Alias for odometer photos (maps to .document)
    /// Use this for backward compatibility with code that used .odometer
    public static let odometer = PhotoPurpose.document
    
    /// Alias for maintenance photos (maps to .reference)
    /// Use this for backward compatibility with code that used .maintenance
    public static let maintenance = PhotoPurpose.reference
    
    /// Alias for expense photos (maps to .reference)
    /// Use this for backward compatibility with code that used .expense
    public static let expense = PhotoPurpose.reference
    
    // MARK: - Custom Domain-Specific Purposes
    
    /// Custom purpose for product photos in an e-commerce app
    /// Example: PhotoPurpose.productPhoto
    public static let productPhoto = PhotoPurpose(identifier: "product")
    
    /// Custom purpose for user-generated content
    /// Example: PhotoPurpose.userContent
    public static let userContent = PhotoPurpose(identifier: "user_content")
    
    /// Custom purpose for medical records
    /// Example: PhotoPurpose.medicalRecord
    public static let medicalRecord = PhotoPurpose(identifier: "medical_record")
    
    /// Custom purpose for insurance claims
    /// Example: PhotoPurpose.insuranceClaim
    public static let insuranceClaim = PhotoPurpose(identifier: "insurance_claim")
}

// MARK: - Usage Examples

/// Example usage of custom photo purposes
struct PhotoPurposeUsageExamples {
    
    /// Example: Using backward compatibility aliases
    func exampleBackwardCompatibility() {
        // Old code using vehicle-specific purposes still works
        let vehicleContext = PhotoContext(
            screenSize: CGSize(width: 375, height: 812),
            availableSpace: CGSize(width: 375, height: 400),
            userPreferences: PhotoPreferences(),
            deviceCapabilities: PhotoDeviceCapabilities()
        )
        
        // Using alias - maps to .general internally
        let _ = platformPhotoCapture_L1(
            purpose: .vehiclePhoto,  // Alias for .general
            context: vehicleContext,
            onImageCaptured: { _ in }
        )
    }
    
    /// Example: Using custom purposes
    func exampleCustomPurposes() {
        let context = PhotoContext(
            screenSize: CGSize(width: 375, height: 812),
            availableSpace: CGSize(width: 375, height: 400),
            userPreferences: PhotoPreferences(),
            deviceCapabilities: PhotoDeviceCapabilities()
        )
        
        // Using custom purpose
        let _ = platformPhotoCapture_L1(
            purpose: .productPhoto,  // Custom purpose
            context: context,
            onImageCaptured: { _ in }
        )
        
        // Custom purposes default to .general behavior in framework logic
        // but you can identify them by their identifier for custom handling
        if PhotoPurpose.productPhoto.identifier == "product" {
            // Custom handling for product photos
        }
    }
    
    /// Example: Creating project-specific purposes
    func exampleProjectSpecificPurposes() {
        // In your project, you can create your own extension:
        // extension PhotoPurpose {
        //     static let myCustomPurpose = PhotoPurpose(identifier: "my_custom")
        // }
        
        // Then use it:
        let customPurpose = PhotoPurpose(identifier: "my_custom")
        let context = PhotoContext(
            screenSize: CGSize(width: 375, height: 812),
            availableSpace: CGSize(width: 375, height: 400),
            userPreferences: PhotoPreferences(),
            deviceCapabilities: PhotoDeviceCapabilities()
        )
        
        let _ = platformPhotoCapture_L1(
            purpose: customPurpose,
            context: context,
            onImageCaptured: { _ in }
        )
    }
}
