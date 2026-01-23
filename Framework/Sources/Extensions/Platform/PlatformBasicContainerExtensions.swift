//
//  PlatformBasicContainerExtensions.swift
//  CarManager
//
//  Created by Platform Extensions System
//  Copyright © 2025 CarManager. All rights reserved.
//

import SwiftUI

// MARK: - Platform Basic Container Extensions

/// Platform-specific basic container extensions
/// Provides consistent container behavior across iOS and macOS
public extension View {
    
    /// Platform-specific VStack container with consistent styling and automatic accessibility
    /// iOS: Uses VStack with iOS-appropriate styling; macOS: Uses VStack with macOS-appropriate styling
    /// Automatically applies `.automaticCompliance()` for accessibility identifiers and HIG compliance
    ///
    /// - Parameters:
    ///   - alignment: The alignment of items in the stack
    ///   - spacing: The spacing between stack items
    ///   - content: The stack content
    /// - Returns: A view with platform-appropriate VStack styling and automatic accessibility compliance
    ///
    /// ## Usage Example
    /// ```swift
    /// EmptyView().platformVStackContainer(alignment: .leading, spacing: 12) {
    ///     ForEach(items) { item in
    ///         ItemView(item: item)
    ///     }
    /// }
    /// ```
    @ViewBuilder
    nonisolated func platformVStackContainer<Content: View>(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: alignment, spacing: spacing) {
            content()
        }
        .automaticCompliance()
        // CRITICAL: Container views apply .automaticCompliance() without identifierName
        // This applies HIG compliance features but skips identifier generation,
        // ensuring child identifiers take precedence over parent identifiers
    }
    
    /// Platform-specific HStack container with consistent styling and automatic accessibility
    /// iOS: Uses HStack with iOS-appropriate styling; macOS: Uses HStack with macOS-appropriate styling
    /// Automatically applies `.automaticCompliance()` for accessibility identifiers and HIG compliance
    ///
    /// - Parameters:
    ///   - alignment: The alignment of items in the stack
    ///   - spacing: The spacing between stack items
    ///   - content: The stack content
    /// - Returns: A view with platform-appropriate HStack styling and automatic accessibility compliance
    ///
    /// ## Usage Example
    /// ```swift
    /// EmptyView().platformHStackContainer(alignment: .top, spacing: 8) {
    ///     ForEach(items) { item in
    ///         ItemView(item: item)
    ///     }
    /// }
    /// ```
    @ViewBuilder
    nonisolated func platformHStackContainer<Content: View>(
        alignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: alignment, spacing: spacing) {
            content()
        }
        .automaticCompliance()
    }
    
    /// Platform-specific ZStack container with consistent styling and automatic accessibility
    /// iOS: Uses ZStack with iOS-appropriate styling; macOS: Uses ZStack with macOS-appropriate styling
    /// Automatically applies `.automaticCompliance()` for accessibility identifiers and HIG compliance
    ///
    /// - Parameters:
    ///   - alignment: The alignment of items in the stack
    ///   - content: The stack content
    /// - Returns: A view with platform-appropriate ZStack styling and automatic accessibility compliance
    ///
    /// ## Usage Example
    /// ```swift
    /// EmptyView().platformZStackContainer(alignment: .center) {
    ///     BackgroundView()
    ///     ForegroundView()
    /// }
    /// ```
    @ViewBuilder
    nonisolated func platformZStackContainer<Content: View>(
        alignment: Alignment = .center,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            content()
        }
        .automaticCompliance()
    }
    
    /// Platform-specific LazyVStack container with consistent styling
    /// iOS: Uses LazyVStack with iOS-appropriate styling; macOS: Uses LazyVStack with macOS-appropriate styling
    ///
    /// - Parameters:
    ///   - alignment: The alignment of items in the stack
    ///   - spacing: The spacing between stack items
    ///   - pinnedViews: The pinned views for the stack
    ///   - content: The stack content
    /// - Returns: A view with platform-appropriate LazyVStack styling
    ///
    /// ## Usage Example
    /// ```swift
    /// EmptyView().platformLazyVStackContainer(alignment: .leading, spacing: 12) {
    ///     ForEach(items) { item in
    ///         ItemView(item: item)
    ///     }
    /// }
    /// ```
    @ViewBuilder
    func platformLazyVStackContainer<Content: View>(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        pinnedViews: PinnedScrollableViews = .init(),
        @ViewBuilder content: () -> Content
    ) -> some View {
        LazyVStack(alignment: alignment, spacing: spacing, pinnedViews: pinnedViews) {
            content()
        }
        .automaticCompliance()
    }
    
    /// Platform-specific LazyHStack container with consistent styling
    /// iOS: Uses LazyHStack with iOS-appropriate styling; macOS: Uses LazyHStack with macOS-appropriate styling
    ///
    /// - Parameters:
    ///   - alignment: The alignment of items in the stack
    ///   - spacing: The spacing between stack items
    ///   - pinnedViews: The pinned views for the stack
    ///   - content: The stack content
    /// - Returns: A view with platform-appropriate LazyHStack styling
    ///
    /// ## Usage Example
    /// ```swift
    /// EmptyView().platformLazyHStackContainer(alignment: .top, spacing: 8) {
    ///     ForEach(items) { item in
    ///         ItemView(item: item)
    ///     }
    /// }
    /// ```
    @ViewBuilder
    func platformLazyHStackContainer<Content: View>(
        alignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        pinnedViews: PinnedScrollableViews = .init(),
        @ViewBuilder content: () -> Content
    ) -> some View {
        LazyHStack(alignment: alignment, spacing: spacing, pinnedViews: pinnedViews) {
            content()
        }
        .automaticCompliance()
    }
    
    /// Platform-specific ScrollView container with consistent styling
    /// iOS: Uses ScrollView with iOS-appropriate styling; macOS: Uses ScrollView with macOS-appropriate styling
    ///
    /// - Parameters:
    ///   - axes: The scroll axes
    ///   - showsIndicators: Whether to show scroll indicators
    ///   - content: The scrollable content
    /// - Returns: A view with platform-appropriate ScrollView styling
    ///
    /// ## Usage Example
    /// ```swift
    /// EmptyView().platformScrollViewContainer(.vertical, showsIndicators: false) {
    ///     VStack(spacing: 16) {
    ///         ForEach(items) { item in
    ///             ItemView(item: item)
    ///         }
    ///         .padding()
    ///     }
    /// }
    /// ```
    @ViewBuilder
    func platformScrollViewContainer<Content: View>(
        _ axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView(axes, showsIndicators: showsIndicators) {
            content()
        }
        .automaticCompliance()
        // CRITICAL: Container views apply .automaticCompliance() without identifierName
        // This applies HIG compliance features but skips identifier generation,
        // ensuring child identifiers take precedence over parent identifiers
    }
    
    /// Platform-specific GroupBox container with consistent styling
    /// iOS: Uses GroupBox with iOS-appropriate styling; macOS: Uses GroupBox with macOS-appropriate styling
    ///
    /// - Parameters:
    ///   - title: The title for the group box
    ///   - content: The group box content
    /// - Returns: A view with platform-appropriate GroupBox styling
    ///
    /// ## Usage Example
    /// ```swift
    /// EmptyView().platformGroupBoxContainer(title: "Settings") {
    ///     VStack(alignment: .leading) {
    ///         Toggle("Enable notifications", isOn: $notificationsEnabled)
    ///         Toggle("Auto-save", isOn: $autoSaveEnabled)
    ///     }
    /// }
    /// ```
    @ViewBuilder
    func platformGroupBoxContainer<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        GroupBox(title) {
            content()
        }
        .automaticCompliance()
    }
    
    /// Platform-specific Section container with consistent styling
    /// iOS: Uses Section with iOS-appropriate styling; macOS: Uses Section with macOS-appropriate styling
    ///
    /// - Parameters:
    ///   - header: The section header
    ///   - footer: The section footer
    ///   - content: The section content
    /// - Returns: A view with platform-appropriate Section styling
    ///
    /// ## Usage Example
    /// ```swift
    /// EmptyView().platformSectionContainer(
    ///     header: "Personal Information",
    ///     footer: "This information is kept private"
    /// ) {
    ///     TextField("Name", text: $name)
    ///     TextField("Email", text: $email)
    /// }
    /// ```
    @ViewBuilder
    func platformSectionContainer<Header: View, Footer: View, Content: View>(
        header: Header,
        footer: Footer,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Section(header: header, footer: footer) {
            content()
        }
        .automaticCompliance()
    }
    
    /// Platform-specific Section container with header only
    /// iOS: Uses Section with iOS-appropriate styling; macOS: Uses Section with macOS-appropriate styling
    ///
    /// - Parameters:
    ///   - header: The section header
    ///   - content: The section content
    /// - Returns: A view with platform-appropriate Section styling
    ///
    /// ## Usage Example
    /// ```swift
    /// EmptyView().platformSectionContainer(header: "Settings") {
    ///     Toggle("Enable notifications", isOn: $notificationsEnabled)
    ///     Toggle("Auto-save", isOn: $autoSaveEnabled)
    /// }
    /// ```
    @ViewBuilder
    func platformSectionContainer<Header: View, Content: View>(
        header: Header,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Section(header: header) {
            content()
        }
        .automaticCompliance()
    }
    
    /// Platform-specific Section container with string header
    /// iOS: Uses Section with iOS-appropriate styling; macOS: Uses Section with macOS-appropriate styling
    ///
    /// - Parameters:
    ///   - header: The section header text
    ///   - content: The section content
    /// - Returns: A view with platform-appropriate Section styling
    ///
    /// ## Usage Example
    /// ```swift
    /// EmptyView().platformSectionContainer(header: "Settings") {
    ///     Toggle("Enable notifications", isOn: $notificationsEnabled)
    ///     Toggle("Auto-save", isOn: $autoSaveEnabled)
    /// }
    /// ```
    @ViewBuilder
    func platformSectionContainer<Content: View>(
        header: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Section(header) {
            content()
        }
        .automaticCompliance()
    }
    
    /// Platform-specific List container with consistent styling
    /// iOS: Uses List with iOS-appropriate styling; macOS: Uses List with macOS-appropriate styling
    ///
    /// - Parameters:
    ///   - content: The list content
    /// - Returns: A view with platform-appropriate List styling
    ///
    /// ## Usage Example
    /// ```swift
    /// EmptyView().platformListContainer {
    ///     ForEach(items) { item in
    ///         ItemRow(item: item)
    ///     }
    /// }
    /// ```
    @MainActor
    @ViewBuilder
    func platformListContainer<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        List {
            content()
        }
        .automaticCompliance()
    }
}

// MARK: - Global Function Wrappers

/// Global function wrapper for platformVStackContainer
/// Provides backward compatibility for code that expects global functions
@ViewBuilder
public func platformVStackContainer<Content: View>(
    alignment: HorizontalAlignment = .center,
    spacing: CGFloat? = nil,
    @ViewBuilder content: () -> Content
) -> some View {
    EmptyView().platformVStackContainer(alignment: alignment, spacing: spacing, content: content)
}

/// Global function wrapper for platformHStackContainer
/// Provides backward compatibility for code that expects global functions
@ViewBuilder
public func platformHStackContainer<Content: View>(
    alignment: VerticalAlignment = .center,
    spacing: CGFloat? = nil,
    @ViewBuilder content: () -> Content
) -> some View {
    EmptyView().platformHStackContainer(alignment: alignment, spacing: spacing, content: content)
}

/// Global function wrapper for platformZStackContainer
/// Provides backward compatibility for code that expects global functions
@ViewBuilder
public func platformZStackContainer<Content: View>(
    alignment: Alignment = .center,
    @ViewBuilder content: () -> Content
) -> some View {
    EmptyView().platformZStackContainer(alignment: alignment, content: content)
}

// MARK: - Function Aliases

/// Alias for platformVStackContainer
/// Provides a shorter name for convenience
/// Note: VStack doesn't require @MainActor, so this function is nonisolated
@ViewBuilder
public func platformVStack<Content: View>(
    alignment: HorizontalAlignment = .center,
    spacing: CGFloat? = nil,
    @ViewBuilder content: () -> Content
) -> some View {
    platformVStackContainer(alignment: alignment, spacing: spacing, content: content)
}

/// Alias for platformHStackContainer
/// Provides a shorter name for convenience
/// Note: HStack doesn't require @MainActor, so this function is nonisolated
@ViewBuilder
public func platformHStack<Content: View>(
    alignment: VerticalAlignment = .center,
    spacing: CGFloat? = nil,
    @ViewBuilder content: () -> Content
) -> some View {
    platformHStackContainer(alignment: alignment, spacing: spacing, content: content)
}

/// Alias for platformZStackContainer
/// Provides a shorter name for convenience
/// Note: ZStack doesn't require @MainActor, so this function is nonisolated
@ViewBuilder
public func platformZStack<Content: View>(
    alignment: Alignment = .center,
    @ViewBuilder content: () -> Content
) -> some View {
    platformZStackContainer(alignment: alignment, content: content)
}

/// Global function wrapper for platformLazyVStackContainer
/// Provides backward compatibility for code that expects global functions
@MainActor
@ViewBuilder
func platformLazyVStackContainer<Content: View>(
    alignment: HorizontalAlignment = .center,
    spacing: CGFloat? = nil,
    pinnedViews: PinnedScrollableViews = .init(),
    @ViewBuilder content: () -> Content
) -> some View {
    EmptyView().platformLazyVStackContainer(alignment: alignment, spacing: spacing, pinnedViews: pinnedViews, content: content)
}

/// Global function wrapper for platformLazyHStackContainer
/// Provides backward compatibility for code that expects global functions
@MainActor
@ViewBuilder
func platformLazyHStackContainer<Content: View>(
    alignment: VerticalAlignment = .center,
    spacing: CGFloat? = nil,
    pinnedViews: PinnedScrollableViews = .init(),
    @ViewBuilder content: () -> Content
) -> some View {
    EmptyView().platformLazyHStackContainer(alignment: alignment, spacing: spacing, pinnedViews: pinnedViews, content: content)
}

/// Global function wrapper for platformScrollViewContainer
/// Provides backward compatibility for code that expects global functions
@MainActor
@ViewBuilder
func platformScrollViewContainer<Content: View>(
    _ axes: Axis.Set = .vertical,
    showsIndicators: Bool = true,
    @ViewBuilder content: () -> Content
) -> some View {
    EmptyView().platformScrollViewContainer(axes, showsIndicators: showsIndicators, content: content)
}

/// Global function wrapper for platformGroupBoxContainer
/// Provides backward compatibility for code that expects global functions
@MainActor
@ViewBuilder
func platformGroupBoxContainer<Content: View>(
    title: String,
    @ViewBuilder content: () -> Content
) -> some View {
    EmptyView().platformGroupBoxContainer(title: title, content: content)
}

/// Global function wrapper for platformSectionContainer with header and footer
/// Provides backward compatibility for code that expects global functions
@MainActor
@ViewBuilder
func platformSectionContainer<Header: View, Footer: View, Content: View>(
    header: Header,
    footer: Footer,
    @ViewBuilder content: () -> Content
) -> some View {
    EmptyView().platformSectionContainer(header: header, footer: footer, content: content)
}

/// Global function wrapper for platformSectionContainer with header only
/// Provides backward compatibility for code that expects global functions
@MainActor
@ViewBuilder
func platformSectionContainer<Header: View, Content: View>(
    header: Header,
    @ViewBuilder content: () -> Content
) -> some View {
    EmptyView().platformSectionContainer(header: header, content: content)
}

/// Global function wrapper for platformSectionContainer with string header
/// Provides backward compatibility for code that expects global functions
@MainActor
@ViewBuilder
func platformSectionContainer<Content: View>(
    header: String,
    @ViewBuilder content: () -> Content
) -> some View {
    EmptyView().platformSectionContainer(header: header, content: content)
}

/// Global function wrapper for platformListContainer
/// Provides backward compatibility for code that expects global functions
@MainActor
@ViewBuilder
func platformListContainer<Content: View>(
    @ViewBuilder content: () -> Content
) -> some View {
    EmptyView().platformListContainer(content: content)
}

// MARK: - Platform Text Field Functions

/// Drop-in replacement for SwiftUI's TextField
/// Provides platform-specific text field with automatic accessibility compliance
/// Note: TextField doesn't require @MainActor for creation, only for binding access
///
/// - Parameters:
///   - title: The placeholder text
///   - text: Binding to the text value
/// - Returns: A platform-specific text field with automatic accessibility compliance
///
/// ## Usage Example
/// ```swift
/// platformTextField("Enter name", text: $name)
/// ```
public func platformTextField(
    _ title: String,
    text: Binding<String>
) -> some View {
    EmptyView().platformTextField(text: text, prompt: title)
        .automaticCompliance(
            identifierName: sanitizeLabelText(title),  // Auto-generate identifierName from title
            accessibilityLabel: title  // Issue #157: Auto-extract from title
        )
}

/// Provides platform-specific text field with automatic accessibility compliance and explicit label
/// Note: TextField doesn't require @MainActor for creation, only for binding access
///
/// - Parameters:
///   - label: The accessibility label for VoiceOver (optional)
///   - prompt: The placeholder text
///   - text: Binding to the text value
/// - Returns: A platform-specific text field with automatic accessibility compliance
///
/// ## Usage Example
/// ```swift
/// platformTextField(label: "Full name", prompt: "Enter name", text: $name)
/// ```
public func platformTextField(
    label: String? = nil,
    prompt: String,
    text: Binding<String>
) -> some View {
    let identifierSource = label ?? prompt
    return EmptyView().platformTextField(text: text, prompt: prompt)
        .automaticCompliance(
            identifierName: sanitizeLabelText(identifierSource),  // Auto-generate identifierName from label or prompt
            accessibilityLabel: label ?? prompt  // Issue #157: Explicit label takes precedence, fallback to prompt
        )
}

/// Provides platform-specific text field with automatic accessibility compliance and explicit label (LocalizedStringKey)
/// - Parameters:
///   - label: The accessibility label for VoiceOver using LocalizedStringKey
///   - prompt: The placeholder text
///   - text: Binding to the text value
public func platformTextField(
    label: LocalizedStringKey,
    prompt: String,
    text: Binding<String>
) -> some View {
    EmptyView().platformTextField(text: text, prompt: prompt)
        .accessibilityLabel(label)
        .automaticCompliance()
}

/// Provides platform-specific text field with automatic accessibility compliance and explicit label (Text)
/// - Parameters:
///   - label: The accessibility label for VoiceOver using Text
///   - prompt: The placeholder text
///   - text: Binding to the text value
public func platformTextField(
    label: Text,
    prompt: String,
    text: Binding<String>
) -> some View {
    EmptyView().platformTextField(text: text, prompt: prompt)
        .accessibilityLabel(label)
        .automaticCompliance()
}

/// Drop-in replacement for SwiftUI's TextField with axis support (iOS 16+)
/// Provides platform-specific text field with automatic accessibility compliance
/// Note: TextField doesn't require @MainActor for creation, only for binding access
///
/// - Parameters:
///   - title: The placeholder text
///   - text: Binding to the text value
///   - axis: The text field axis (horizontal or vertical)
/// - Returns: A platform-specific text field with automatic accessibility compliance
///
/// ## Usage Example
/// ```swift
/// platformTextField("Enter description", text: $description, axis: .vertical)
/// ```
public func platformTextField(
    _ title: String,
    text: Binding<String>,
    axis: Axis
) -> some View {
    EmptyView().platformTextField(text: text, prompt: title, axis: axis)
        .automaticCompliance(
            identifierName: sanitizeLabelText(title),  // Auto-generate identifierName from title
            accessibilityLabel: title  // Issue #157: Auto-extract from title
        )
}

/// Drop-in replacement for SwiftUI's TextField with axis support and explicit label (iOS 16+)
/// Provides platform-specific text field with automatic accessibility compliance
/// Note: TextField doesn't require @MainActor for creation, only for binding access
///
/// - Parameters:
///   - label: The accessibility label for VoiceOver (optional)
///   - prompt: The placeholder text
///   - text: Binding to the text value
///   - axis: The text field axis (horizontal or vertical)
/// - Returns: A platform-specific text field with automatic accessibility compliance
///
/// ## Usage Example
/// ```swift
/// platformTextField(label: "Description field", prompt: "Enter description", text: $description, axis: .vertical)
/// ```
public func platformTextField(
    label: String? = nil,
    prompt: String,
    text: Binding<String>,
    axis: Axis
) -> some View {
    let identifierSource = label ?? prompt
    return EmptyView().platformTextField(text: text, prompt: prompt, axis: axis)
        .automaticCompliance(
            identifierName: sanitizeLabelText(identifierSource),  // Auto-generate identifierName from label or prompt
            accessibilityLabel: label ?? prompt  // Issue #157: Explicit label takes precedence, fallback to prompt
        )
}

/// platformTextField with LocalizedStringKey label and axis
public func platformTextField(
    label: LocalizedStringKey,
    prompt: String,
    text: Binding<String>,
    axis: Axis
) -> some View {
    EmptyView().platformTextField(text: text, prompt: prompt, axis: axis)
        .accessibilityLabel(label)
        .automaticCompliance()
}

/// platformTextField with Text label and axis
public func platformTextField(
    label: Text,
    prompt: String,
    text: Binding<String>,
    axis: Axis
) -> some View {
    EmptyView().platformTextField(text: text, prompt: prompt, axis: axis)
        .accessibilityLabel(label)
        .automaticCompliance()
}

/// Drop-in replacement for SwiftUI's SecureField
/// Provides platform-specific secure text field with automatic accessibility compliance
/// Note: SecureField doesn't require @MainActor for creation, only for binding access
///
/// - Parameters:
///   - title: The placeholder text
///   - text: Binding to the text value
/// - Returns: A platform-specific secure text field with automatic accessibility compliance
///
/// ## Usage Example
/// ```swift
/// platformSecureField("Enter password", text: $password)
/// ```
public func platformSecureField(
    _ title: String,
    text: Binding<String>
) -> some View {
    return EmptyView().platformSecureTextField(text: text, prompt: title)
        .automaticCompliance(
            identifierName: sanitizeLabelText(title),  // Auto-generate identifierName from title
            accessibilityLabel: title  // Issue #157: Auto-extract from title
        )
}

/// Drop-in replacement for SwiftUI's SecureField with explicit label
/// Provides platform-specific secure text field with automatic accessibility compliance
/// Note: SecureField doesn't require @MainActor for creation, only for binding access
///
/// - Parameters:
///   - label: The accessibility label for VoiceOver (optional)
///   - prompt: The placeholder text
///   - text: Binding to the text value
/// - Returns: A platform-specific secure text field with automatic accessibility compliance
///
/// ## Usage Example
/// ```swift
/// platformSecureField(label: "Password field", prompt: "Enter password", text: $password)
/// ```
public func platformSecureField(
    label: String? = nil,
    prompt: String,
    text: Binding<String>
) -> some View {
    let identifierSource = label ?? prompt
    return EmptyView().platformSecureTextField(text: text, prompt: prompt)
        .automaticCompliance(
            identifierName: sanitizeLabelText(identifierSource),  // Auto-generate identifierName from label or prompt
            accessibilityLabel: label ?? prompt  // Issue #157: Explicit label takes precedence, fallback to prompt
        )
}

/// platformSecureField with LocalizedStringKey label
public func platformSecureField(
    label: LocalizedStringKey,
    prompt: String,
    text: Binding<String>
) -> some View {
    EmptyView().platformSecureTextField(text: text, prompt: prompt)
        .accessibilityLabel(label)
        .automaticCompliance()
}

/// platformSecureField with Text label
public func platformSecureField(
    label: Text,
    prompt: String,
    text: Binding<String>
) -> some View {
    EmptyView().platformSecureTextField(text: text, prompt: prompt)
        .accessibilityLabel(label)
        .automaticCompliance()
}

/// Drop-in replacement for SwiftUI's Toggle
/// Provides platform-specific toggle with automatic accessibility compliance
/// Note: Toggle doesn't require @MainActor for creation, only for binding access
///
/// - Parameters:
///   - title: The toggle label text
///   - isOn: Binding to the toggle state
/// - Returns: A platform-specific toggle with automatic accessibility compliance
///
/// ## Usage Example
/// ```swift
/// platformToggle("Enable notifications", isOn: $notificationsEnabled)
/// ```
public func platformToggle(
    _ title: String,
    isOn: Binding<Bool>
) -> some View {
    EmptyView().platformToggle(isOn: isOn) {
        Text(title)
    }
    .automaticCompliance(
        identifierName: sanitizeLabelText(title),  // Auto-generate identifierName from title
        accessibilityLabel: title  // Issue #157: Auto-extract from title
    )
}

/// Drop-in replacement for SwiftUI's Toggle with explicit accessibility label
/// Provides platform-specific toggle with automatic accessibility compliance
/// Note: Toggle doesn't require @MainActor for creation, only for binding access
///
/// - Parameters:
///   - label: The accessibility label for VoiceOver (optional, separate from visible title)
///   - isOn: Binding to the toggle state
/// - Returns: A platform-specific toggle with automatic accessibility compliance
///
/// ## Usage Example
/// ```swift
/// platformToggle(label: "Enable notifications", isOn: $notificationsEnabled)
/// ```
/// Note: This version uses the label as the accessibility label only. For visible text, use the original `platformToggle(_:isOn:)` function.
public func platformToggle(
    label: String? = nil,
    isOn: Binding<Bool>
) -> some View {
    let toggleLabel = label ?? "Toggle"
    return EmptyView().platformToggle(isOn: isOn) {
        Text(toggleLabel) // Use label as visible text if provided, fallback for Toggle requirement
    }
    .automaticCompliance(
        identifierName: sanitizeLabelText(toggleLabel),  // Auto-generate identifierName from label
        accessibilityLabel: label  // Issue #154: Parameter-based approach
    )
}

/// platformToggle with LocalizedStringKey label
public func platformToggle(
    label: LocalizedStringKey,
    isOn: Binding<Bool>
) -> some View {
    EmptyView().platformToggle(isOn: isOn) {
        Text(label)
    }
    .accessibilityLabel(label)
    .automaticCompliance()
}

/// platformToggle with Text label
public func platformToggle(
    label: Text,
    isOn: Binding<Bool>
) -> some View {
    EmptyView().platformToggle(isOn: isOn) {
        label
    }
    .accessibilityLabel(label)
    .automaticCompliance()
}

/// Drop-in replacement for SwiftUI's Form
/// Provides platform-specific form container with automatic accessibility compliance
/// Note: Form doesn't require @MainActor for creation
///
/// - Parameter content: The form content
/// - Returns: A platform-specific form container with automatic accessibility compliance
///
/// ## Usage Example
/// ```swift
/// platformForm {
///     platformTextField("Name", text: $name)
///     platformToggle("Enabled", isOn: $enabled)
/// }
/// ```
@ViewBuilder
public func platformForm<Content: View>(
    @ViewBuilder content: () -> Content
) -> some View {
    EmptyView().platformFormContainer(content: content)
        .automaticCompliance()
}

/// Drop-in replacement for SwiftUI's TextEditor
/// Provides platform-specific text editor with automatic accessibility compliance
/// Note: TextEditor doesn't require @MainActor for creation, only for binding access
///
/// - Parameters:
///   - prompt: The placeholder text (shown when editor is empty)
///   - text: Binding to the text value
/// - Returns: A platform-specific text editor with automatic accessibility compliance
///
/// ## Usage Example
/// ```swift
/// platformTextEditor("Enter description", text: $description)
/// ```
public func platformTextEditor(
    _ prompt: String,
    text: Binding<String>
) -> some View {
    EmptyView().platformTextEditor(text: text, prompt: prompt)
        .automaticCompliance(
            identifierName: sanitizeLabelText(prompt),  // Auto-generate identifierName from prompt
            accessibilityLabel: prompt  // Issue #157: Auto-extract from prompt
        )
}

/// Drop-in replacement for SwiftUI's TextEditor with explicit label
/// Provides platform-specific text editor with automatic accessibility compliance
/// Note: TextEditor doesn't require @MainActor for creation, only for binding access
///
/// - Parameters:
///   - label: The accessibility label for VoiceOver (optional)
///   - prompt: The placeholder text (shown when editor is empty)
///   - text: Binding to the text value
/// - Returns: A platform-specific text editor with automatic accessibility compliance
///
/// ## Usage Example
/// ```swift
/// platformTextEditor(label: "Description editor", prompt: "Enter description", text: $description)
/// ```
public func platformTextEditor(
    label: String? = nil,
    prompt: String,
    text: Binding<String>
) -> some View {
    let identifierSource = label ?? prompt
    return EmptyView().platformTextEditor(text: text, prompt: prompt)
        .automaticCompliance(
            identifierName: sanitizeLabelText(identifierSource),  // Auto-generate identifierName from label or prompt
            accessibilityLabel: label ?? prompt  // Issue #157: Explicit label takes precedence, fallback to prompt
        )
}

/// platformTextEditor with LocalizedStringKey label
public func platformTextEditor(
    label: LocalizedStringKey,
    prompt: String,
    text: Binding<String>
) -> some View {
    EmptyView().platformTextEditor(text: text, prompt: prompt)
        .accessibilityLabel(label)
        .automaticCompliance()
}

/// platformTextEditor with Text label
public func platformTextEditor(
    label: Text,
    prompt: String,
    text: Binding<String>
) -> some View {
    EmptyView().platformTextEditor(text: text, prompt: prompt)
        .accessibilityLabel(label)
        .automaticCompliance()
}

// MARK: - Platform Text Functions

/// Drop-in replacement for SwiftUI's Text
/// Returns Text, allowing chaining of Text-specific modifiers like .bold(), .font(), etc.
/// Note: Text doesn't require @MainActor for creation
/// 
/// **Limitation**: SwiftUI's type system prevents applying `.automaticCompliance()` 
/// (which returns `some View`) while preserving the `Text` type needed for chaining.
/// Apply `.automaticCompliance()` after Text modifiers if you need full compliance:
/// ```swift
/// platformText("Hello").bold().automaticCompliance()
/// ```
///
/// - Parameter content: The text content
/// - Returns: A Text view (true drop-in replacement)
///
/// ## Usage Example
/// ```swift
/// platformText("Hello, World!")
/// platformText("Hello").bold()
/// platformText("Hello").bold().automaticCompliance()  // For full compliance
/// ```
public func platformText(_ content: String) -> Text {
    Text(content)
}

/// Drop-in replacement for SwiftUI's Text with explicit accessibility label
/// Returns Text, allowing chaining of Text-specific modifiers like .bold(), .font(), etc.
/// Note: Text doesn't require @MainActor for creation
/// Note: Apply .automaticCompliance() manually if you need SixLayer accessibility benefits
///
/// - Parameters:
///   - content: The text content to display
///   - accessibilityLabel: The accessibility label for VoiceOver (applied via .accessibilityLabel())
/// - Returns: A Text view with accessibility label applied (true drop-in replacement)
///
/// ## Usage Example
/// ```swift
/// platformText("42", accessibilityLabel: "Answer: forty-two")
/// platformText("42", accessibilityLabel: "Answer").bold()
/// ```
public func platformText(
    _ content: String,
    accessibilityLabel: String
) -> Text {
    Text(content)
        .accessibilityLabel(accessibilityLabel)
}

/// platformText with LocalizedStringKey
/// Returns Text, allowing chaining of Text-specific modifiers like .bold(), .font(), etc.
/// Note: Text doesn't require @MainActor for creation
/// Note: Apply .automaticCompliance() manually if you need SixLayer accessibility benefits
///
/// - Parameter content: The localized text content
/// - Returns: A Text view with accessibility label applied (true drop-in replacement)
///
/// ## Usage Example
/// ```swift
/// platformText("greeting")
/// platformText("greeting").bold()
/// ```
public func platformText(_ content: LocalizedStringKey) -> Text {
    Text(content)
        .accessibilityLabel(content)
}

/// platformText with Text view
/// Returns the Text view as-is, allowing further chaining
/// Note: Text doesn't require @MainActor for creation
/// Note: Apply .automaticCompliance() manually if you need SixLayer accessibility benefits
///
/// - Parameter content: The Text view
/// - Returns: The Text view unchanged (true drop-in replacement)
///
/// ## Usage Example
/// ```swift
/// platformText(Text("Hello").bold())
/// ```
public func platformText(_ content: Text) -> Text {
    content
}

/// Drop-in replacement for SwiftUI's Button with simple label (auto-extracts accessibility label)
/// Provides platform-specific button with automatic accessibility compliance
/// Note: Button doesn't require @MainActor for creation
///
/// - Parameters:
///   - label: The button label text (also used as accessibility label)
///   - action: The action to perform when button is tapped
/// - Returns: A platform-specific button with automatic accessibility compliance
///
/// ## Usage Example
/// ```swift
/// platformButton("Save") {
///     save()
/// }
/// ```
public func platformButton(
    _ label: String,
    action: @escaping () -> Void
) -> some View {
    Button(action: action) {
        Text(label)
    }
    .automaticCompliance(
        identifierName: sanitizeLabelText(label),  // Auto-generate identifierName from label
        accessibilityLabel: label  // Issue #157: Auto-extract from label parameter
    )
}

/// Drop-in replacement for SwiftUI's Button with explicit accessibility label
/// Provides platform-specific button with automatic accessibility compliance
/// Note: Button doesn't require @MainActor for creation
///
/// - Parameters:
///   - label: The accessibility label for VoiceOver (optional)
///   - action: The action to perform when button is tapped
/// - Returns: A platform-specific button with automatic accessibility compliance
///
/// ## Usage Example
/// ```swift
/// platformButton(label: "Save document") {
///     save()
/// }
/// ```
public func platformButton(
    label: String? = nil,
    action: @escaping () -> Void
) -> some View {
    let buttonLabel = label ?? "Button"
    return Button(action: action) {
        Text(buttonLabel)
    }
    .automaticCompliance(
        identifierName: sanitizeLabelText(buttonLabel),  // Auto-generate identifierName from label
        accessibilityLabel: label  // Issue #154: Parameter-based approach
    )
}

/// platformButton with LocalizedStringKey label
public func platformButton(
    label: LocalizedStringKey,
    action: @escaping () -> Void
) -> some View {
    Button(action: action) {
        Text(label)
    }
    .accessibilityLabel(label)
    .automaticCompliance()
}

/// platformButton with Text label
public func platformButton(
    label: Text,
    action: @escaping () -> Void
) -> some View {
    Button(action: action) {
        label
    }
    .accessibilityLabel(label)
    .automaticCompliance()
}
