import SwiftUI

// MARK: - Platform Menu System Extensions

/// Platform-specific menu system extensions that provide consistent behavior
/// across iOS and macOS using SwiftUI `Menu`.
public extension View {

    /// Platform menu with menu items.
    ///
    /// Presents a SwiftUI `Menu` on iOS and macOS (toolbar overflow, action sheets, etc.).
    /// Supersedes the iOS no-op behavior from [#62](https://github.com/schatt/sixlayer/issues/62);
    /// see [#321](https://github.com/schatt/sixlayer/issues/321).
    ///
    /// - Parameter content: The menu items to display
    /// - Returns: A view with platform-appropriate menu behavior
    ///
    /// ## Usage Example
    /// ```swift
    /// Button("Actions")
    ///     .platformMenu {
    ///         Button("Copy") { copyText() }
    ///         Button("Delete") { deleteText() }
    ///     }
    /// ```
    @ViewBuilder
    func platformMenu<MenuItems: View>(
        @ViewBuilder content: () -> MenuItems
    ) -> some View {
        Menu {
            content()
        } label: {
            self
        }
    }

    /// Platform menu with menu items and label.
    ///
    /// Presents a SwiftUI `Menu` on iOS and macOS.
    ///
    /// - Parameters:
    ///   - label: The label for the menu
    ///   - content: The menu items to display
    /// - Returns: A view with platform-appropriate menu behavior
    ///
    /// ## Usage Example
    /// ```swift
    /// Button("Actions")
    ///     .platformMenu(
    ///         label: Text("More Actions"),
    ///         content: {
    ///             Button("Copy") { copyText() }
    ///             Button("Delete") { deleteText() }
    ///         }
    ///     )
    /// ```
    @ViewBuilder
    func platformMenu<Label: View, MenuItems: View>(
        label: Label,
        @ViewBuilder content: () -> MenuItems
    ) -> some View {
        Menu {
            content()
        } label: {
            label
        }
    }

    /// Platform menu with menu items and title.
    ///
    /// Presents a SwiftUI `Menu` on iOS and macOS.
    ///
    /// - Parameters:
    ///   - title: The title for the menu
    ///   - content: The menu items to display
    /// - Returns: A view with platform-appropriate menu behavior
    ///
    /// ## Usage Example
    /// ```swift
    /// Button("Actions")
    ///     .platformMenu(
    ///         title: "More Actions",
    ///         content: {
    ///             Button("Copy") { copyText() }
    ///             Button("Delete") { deleteText() }
    ///         }
    ///     )
    /// ```
    @ViewBuilder
    func platformMenu<MenuItems: View>(
        title: String,
        @ViewBuilder content: () -> MenuItems
    ) -> some View {
        Menu {
            content()
        } label: {
            Text(title)
        }
    }
}

