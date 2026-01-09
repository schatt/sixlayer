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
@MainActor
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
    func platformVStackContainer<Content: View>(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: alignment, spacing: spacing) {
            content()
        }
        .automaticCompliance()
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
    func platformHStackContainer<Content: View>(
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
    func platformZStackContainer<Content: View>(
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
    }
}

// MARK: - Global Function Wrappers

/// Global function wrapper for platformVStackContainer
/// Provides backward compatibility for code that expects global functions
@MainActor
@ViewBuilder
func platformVStackContainer<Content: View>(
    alignment: HorizontalAlignment = .center,
    spacing: CGFloat? = nil,
    @ViewBuilder content: () -> Content
) -> some View {
    EmptyView().platformVStackContainer(alignment: alignment, spacing: spacing, content: content)
}

/// Global function wrapper for platformHStackContainer
/// Provides backward compatibility for code that expects global functions
@MainActor
@ViewBuilder
func platformHStackContainer<Content: View>(
    alignment: VerticalAlignment = .center,
    spacing: CGFloat? = nil,
    @ViewBuilder content: () -> Content
) -> some View {
    EmptyView().platformHStackContainer(alignment: alignment, spacing: spacing, content: content)
}

/// Global function wrapper for platformZStackContainer
/// Provides backward compatibility for code that expects global functions
@MainActor
@ViewBuilder
func platformZStackContainer<Content: View>(
    alignment: Alignment = .center,
    @ViewBuilder content: () -> Content
) -> some View {
    EmptyView().platformZStackContainer(alignment: alignment, content: content)
}

// MARK: - Function Aliases

/// Alias for platformVStackContainer
/// Provides a shorter name for convenience
@MainActor
@ViewBuilder
func platformVStack<Content: View>(
    alignment: HorizontalAlignment = .center,
    spacing: CGFloat? = nil,
    @ViewBuilder content: () -> Content
) -> some View {
    platformVStackContainer(alignment: alignment, spacing: spacing, content: content)
}

/// Alias for platformHStackContainer
/// Provides a shorter name for convenience
@MainActor
@ViewBuilder
func platformHStack<Content: View>(
    alignment: VerticalAlignment = .center,
    spacing: CGFloat? = nil,
    @ViewBuilder content: () -> Content
) -> some View {
    platformHStackContainer(alignment: alignment, spacing: spacing, content: content)
}

/// Alias for platformZStackContainer
/// Provides a shorter name for convenience
@MainActor
@ViewBuilder
func platformZStack<Content: View>(
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
@MainActor
func platformTextField(
    _ title: String,
    text: Binding<String>
) -> some View {
    EmptyView().platformTextField(text: text, prompt: title)
        .automaticCompliance()
}

/// Drop-in replacement for SwiftUI's TextField with axis support (iOS 16+)
/// Provides platform-specific text field with automatic accessibility compliance
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
@MainActor
func platformTextField(
    _ title: String,
    text: Binding<String>,
    axis: Axis
) -> some View {
    EmptyView().platformTextField(text: text, prompt: title, axis: axis)
        .automaticCompliance()
}

/// Drop-in replacement for SwiftUI's SecureField
/// Provides platform-specific secure text field with automatic accessibility compliance
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
@MainActor
func platformSecureField(
    _ title: String,
    text: Binding<String>
) -> some View {
    EmptyView().platformSecureTextField(text: text, prompt: title)
        .automaticCompliance()
}

/// Drop-in replacement for SwiftUI's Toggle
/// Provides platform-specific toggle with automatic accessibility compliance
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
@MainActor
func platformToggle(
    _ title: String,
    isOn: Binding<Bool>
) -> some View {
    EmptyView().platformToggle(isOn: isOn) {
        Text(title)
    }
    .automaticCompliance()
}

/// Drop-in replacement for SwiftUI's Form
/// Provides platform-specific form container with automatic accessibility compliance
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
@MainActor
@ViewBuilder
func platformForm<Content: View>(
    @ViewBuilder content: () -> Content
) -> some View {
    EmptyView().platformFormContainer(content: content)
        .automaticCompliance()
}

/// Drop-in replacement for SwiftUI's TextEditor
/// Provides platform-specific text editor with automatic accessibility compliance
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
@MainActor
func platformTextEditor(
    _ prompt: String,
    text: Binding<String>
) -> some View {
    EmptyView().platformTextEditor(text: text, prompt: prompt)
        .automaticCompliance()
}
