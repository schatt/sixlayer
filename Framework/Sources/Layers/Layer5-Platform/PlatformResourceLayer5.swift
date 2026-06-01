import SwiftUI

/// Layer 5: Platform - Resource Layer
///
/// This layer is responsible for managing platform-specific resources (e.g., images, fonts, data files)
/// and providing them in a cross-platform compatible way. It handles resource loading, caching,
/// and optimization based on the target platform's capabilities.
///
/// The tests for this component need to be improved to verify:
/// - Correct loading and management of resources across different platforms.
/// - Efficient caching and memory usage for platform-specific assets.
/// - Proper handling of resource variations (e.g., different image resolutions).
/// - Accessibility of loaded resources.
@MainActor
public class PlatformResourceLayer5 {
    
    // MARK: - Button Components
    
    /// Creates a platform-specific resource button
    public func createResourceButton(title: String, action: @escaping () -> Void) -> some View {
        #if os(iOS)
        return Button(title, action: action)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .automaticCompliance(named: "PlatformResourceLayer5")
        #elseif os(macOS)
        return Button(title, action: action)
            .buttonStyle(.bordered)
            .controlSize(.large)
            .automaticCompliance(named: "PlatformResourceLayer5")
        #else
        return Button(title, action: action)
            .automaticCompliance(named: "PlatformResourceLayer5")
        #endif
    }
    
    /// Creates a platform-specific image picker button
    public func createImagePickerButton(action: @escaping () -> Void) -> some View {
        #if os(iOS)
        return Button(action: action) {
            HStack {
                Image(systemName: "photo")
                let i18n = InternationalizationService()
                Text(i18n.localizedString(for: "SixLayerFramework.button.chooseImage"))
            }
        }
        .buttonStyle(.bordered)
        #elseif os(macOS)
        return Button(action: action) {
            HStack {
                Image(systemName: "photo")
                let i18n = InternationalizationService()
                Text(i18n.localizedString(for: "SixLayerFramework.button.chooseImage"))
            }
        }
        .buttonStyle(.bordered)
        #else
        let i18n = InternationalizationService()
        return Button(i18n.localizedString(for: "SixLayerFramework.button.chooseImage"), action: action)
        #endif
    }
    
    // MARK: - Text Field Components
    
    /// Creates a platform-specific resource text field
    public func createResourceTextField(placeholder: String, text: Binding<String>) -> some View {
        #if os(iOS) || os(macOS)
        return TextField(placeholder, text: text)
            .textFieldStyle(.roundedBorder)
            .platformTextInputAutocapitalization(.never)
        #else
        return TextField(placeholder, text: text)
            .platformTextInputAutocapitalization(.never)
        #endif
    }
    
    // MARK: - Image Components
    
    /// Creates a platform-specific image view
    public func createImageView(image: PlatformImage?, placeholder: String = "No Image") -> some View {
        Group {
            if let image = image {
                Image(platformImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                VStack {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text(placeholder)
                        .foregroundColor(.secondary)
                }
            }
        }
        .automaticCompliance(named: "PlatformResourceLayer5Image")
    }
    
    // MARK: - Loading Components
    
    /// Creates a platform-specific loading indicator
    public func createLoadingIndicator() -> some View {
        #if os(iOS)
        return ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .scaleEffect(1.2)
        #elseif os(macOS)
        return ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
        #else
        return ProgressView()
        #endif
    }
}
