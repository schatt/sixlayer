import SwiftUI

// MARK: - Platform List Extensions

/// Platform-specific List extensions that provide consistent behavior
/// across iOS and macOS while handling platform differences appropriately
public extension View {

    // MARK: - List Toolbar Extensions

    /// Platform-specific list toolbar
    /// Provides consistent toolbar for list views that need an add button
    ///
    /// - Parameters:
    ///   - onAdd: Action to perform when add is tapped
    ///   - addButtonTitle: Title for the add button (default: "Add")
    ///   - addButtonIcon: Icon for the add button (default: "plus")
    /// - Returns: A view with platform-specific toolbar
    func platformListToolbar(
        onAdd: @escaping () -> Void,
        addButtonTitle: String = "Add",
        addButtonIcon: String = "plus"
    ) -> some View {
        #if os(iOS)
        return self.toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: onAdd) {
                    Image(systemName: addButtonIcon)
                        .accessibilityLabel(addButtonTitle)
                }
            }
        }
        #elseif os(macOS)
        return self.toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: onAdd) {
                    Image(systemName: addButtonIcon)
                        .accessibilityLabel(addButtonTitle)
                }
            }
        }
        #else
        return self
        #endif
    }

    // MARK: - List Style Extensions

    /// Platform-specific list style modifier
    /// Applies platform-specific list styling to existing List views
    ///
    /// - Returns: A view with platform-specific list style
    func platformListStyle() -> some View {
        #if os(iOS)
        self.listStyle(InsetGroupedListStyle())
        #else
        self.listStyle(DefaultListStyle())
        #endif
    }

    /// Platform-specific sidebar list styling
    /// On macOS, applies sidebar style. On iOS, applies insetGrouped style.
    ///
    /// - Returns: A view with platform-specific sidebar list style
    func platformSidebarListStyle() -> some View {
        #if os(iOS)
        return self.listStyle(.insetGrouped)
        #elseif os(macOS)
        return self.listStyle(.sidebar)
        #else
        return self.listStyle(.plain)
        #endif
    }

    // MARK: - List Selection Extensions

    /// Platform-specific list selection (multiple)
    /// Provides consistent list selection behavior across platforms
    ///
    /// - Parameters:
    ///   - selection: Binding to the selected items
    ///   - content: The list content
    /// - Returns: A platform-specific list with selection
    @MainActor
    func platformListWithSelection<SelectionValue: Hashable, Content: View>(
        selection: Binding<Set<SelectionValue>>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        #if os(watchOS)
        // List(selection:) is unavailable on watchOS; selection binding is ignored (graceful degradation).
        return List { content() }
        #else
        return List(selection: selection, content: content)
        #endif
    }

    /// Platform-specific list selection (single)
    /// Provides consistent single-selection list behavior across platforms
    ///
    /// - Parameters:
    ///   - selection: Binding to the selected item
    ///   - content: The list content
    /// - Returns: A platform-specific list with single selection
    @MainActor
    func platformListWithSelection<SelectionValue: Hashable, Content: View>(
        selection: Binding<SelectionValue?>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        #if os(watchOS)
        return List { content() }
        #else
        return List(selection: selection, content: content)
        #endif
    }

    // MARK: - List Container Extensions

    /// Platform-specific backup list container
    /// iOS: Wraps in NavigationView; macOS: Returns content directly with frame
    @ViewBuilder
    func platformBackupListContainer<Content: View>(
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        #if os(iOS)
        NavigationView {
            content()
        }
        .navigationViewStyle(StackNavigationViewStyle())
        #else
        content()
            .frame(minWidth: 600, minHeight: 400)
        #endif
    }
}
