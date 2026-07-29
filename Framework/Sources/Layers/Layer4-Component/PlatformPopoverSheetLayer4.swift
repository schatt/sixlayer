import SwiftUI

// MARK: - Platform Popover and Sheet Layer 4: Component Implementation

/// Platform-agnostic helpers for popover and sheet presentation
/// Implements Issue #11: Add Popover/Sheet Helpers to Six-Layer Architecture (Layer 4)
///
/// ## Cross-Platform Behavior
///
/// ### Popovers
/// **Semantic Purpose**: Contextual, temporary information or actions attached to a specific UI element
/// - **iOS (iPad)**: Floating panel with arrow pointing to source element. Dismisses when tapping outside.
///   - **iPhone**: Popovers are automatically converted to sheets (full-screen) by the system
/// - **macOS**: Floating panel attached to source element. More commonly used than on iOS.
///   - Appears as a detached window-like panel
///   - Typically used for tool palettes, contextual menus, or quick actions
///
/// **When to Use**: Quick actions, contextual information, tool palettes, secondary controls
/// **Size**: Defaults to `.small` via `PlatformPresentationSize` (#384)
///
/// ### Sheets
/// **Semantic Purpose**: Modal presentation for focused tasks or detailed content
/// - **iOS**:
///   - **iPhone**: Full-screen modal (default) or half-sheet; `sizes` project to `PresentationDetent` snap heights
///   - **iPad**: Centered modal; clamped min width **and** height (Split View / Stage Manager)
///   - Supports drag-to-dismiss gestures
/// - **macOS**: Modal window (not full-screen)
///   - `sizes` become clamped min width/height (no detents on macOS)
///   - User can move/resize the window
///
/// **When to Use**: Forms, detail views, editing interfaces, multi-step workflows
/// **Size**: Defaults to `[.large]` via `PlatformPresentationSize` (#384)
///
/// ## Platform Mapping
///
/// | Concept | iOS Behavior | macOS Behavior | Unified API |
/// |---------|-------------|----------------|------------|
/// | Popover | Floating panel (iPad) / Sheet (iPhone) | Floating panel | `platformPopover_L4()` |
/// | Sheet | Full-screen or half-sheet | Modal window | `platformSheet_L4()` |
///
/// **Note**: On iPhone, popovers are automatically converted to sheets by SwiftUI. The unified API
/// handles this automatically, so you can use `platformPopover_L4()` on all devices and it will
/// behave appropriately for each platform.
///
/// ## Nested Sheets (Sheet Presented From Another Sheet)
///
/// To prevent the inner sheet's dismissal from propagating up and dismissing the outer sheet:
///
/// 1. **Use separate state per sheet** – The outer sheet has its own `@State var showOuter`; the
///    inner sheet (presented from content inside the outer sheet) has its own `@State var showInner`.
///    Never bind the inner sheet to the outer sheet's binding.
///
/// 2. **Inner sheet's onDismiss must not affect the parent** – The `onDismiss` of the modifier
///    that presents the *inner* sheet runs when the inner sheet is dismissed. In that closure, do
///    only local cleanup (e.g. clear selection). Do **not** set the outer sheet's binding to
///    `false` or call any dismiss that would close the parent.
///
/// 3. **Dismiss only the current sheet from inside** – In the inner sheet's content, use
///    `@Environment(\.dismiss)` and call `dismiss()` once; that dismisses only the inner sheet.
///    Avoid passing the parent's binding or dismiss action into the child.
///
/// Example:
/// ```swift
/// @State private var showParent = false
/// @State private var showChild = false  // separate state for inner sheet
///
/// .sheet(isPresented: $showParent, onDismiss: { /* runs only when parent sheet dismisses */ }) {
///     ParentContent(showChild: $showChild)
/// }
/// // ParentContent presents:
/// .sheet(isPresented: $showChild, onDismiss: { /* only local cleanup */ }) {
///     ChildContent()  // uses dismiss() to close only itself
/// }
/// ```
public extension View {
    
    /// Unified popover presentation helper
    ///
    /// **Cross-Platform Behavior:**
    /// - **iOS (iPad)**: Floating panel with arrow, dismisses on outside tap
    /// - **iOS (iPhone)**: Automatically converted to full-screen sheet by SwiftUI
    /// - **macOS**: Floating panel attached to source element
    ///
    /// **Use For**: Contextual actions, tool palettes, quick information displays
    ///
    /// - Parameters:
    ///   - isPresented: Binding to control popover presentation
    ///   - attachmentAnchor: Point where popover attaches (default: .point(.center))
    ///   - arrowEdge: Edge where arrow appears (default: .top)
    ///   - sizes: Presentation size hints (default: `[.small]`). Clamped min frame on all platforms.
    ///   - content: View builder for popover content
    /// - Returns: View with popover modifier applied
    @MainActor
    @ViewBuilder
    func platformPopover_L4<Content: View>(
        isPresented: Binding<Bool>,
        attachmentAnchor: PopoverAttachmentAnchor = .point(.center),
        arrowEdge: Edge = .top,
        sizes: [PlatformPresentationSize] = [.small],
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        #if os(iOS)
        self.popover(
            isPresented: isPresented,
            attachmentAnchor: attachmentAnchor,
            arrowEdge: arrowEdge
        ) {
            content()
                .platformPresentationFrame(sizes: sizes)
        }
        .automaticCompliance(named: "platformPopover_L4")
        #elseif os(macOS)
        self.popover(
            isPresented: isPresented,
            attachmentAnchor: attachmentAnchor,
            arrowEdge: arrowEdge
        ) {
            content()
                .platformPresentationFrame(sizes: sizes)
        }
        .automaticCompliance(named: "platformPopover_L4")
        #else
        // `.popover` SwiftUI API is unavailable on tvOS (#237); use full-screen sheet-style at call sites instead.
        self
        #endif
    }
    
    /// Unified sheet presentation helper
    ///
    /// **Cross-Platform Behavior:**
    /// - **iOS (iPhone)**: `sizes` project to `PresentationDetent` snap heights (iOS 16+)
    ///   - Supports drag-to-dismiss gestures
    /// - **iOS (iPad)**: Clamped min width and height for multitasking windows
    /// - **macOS**: Modal window with clamped min frame from the same `sizes` (no detents)
    ///
    /// **Use For**: Forms, detail views, editing interfaces, multi-step workflows
    ///
    /// - Parameters:
    ///   - isPresented: Binding to control sheet presentation
    ///   - onDismiss: Optional callback when this sheet is dismissed. For nested sheets, do only local cleanup here so it does not propagate to the parent (see file-level "Nested Sheets" docs).
    ///   - sizes: Cross-platform size hints (default: `[.large]`). iOS also projects these to presentation detents.
    ///   - dragIndicator: Whether to show drag indicator (iOS only, ignored on macOS)
    ///   - content: View builder for sheet content
    /// - Returns: View with sheet modifier applied
    @MainActor
    @ViewBuilder
    func platformSheet_L4<Content: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        sizes: [PlatformPresentationSize] = [.large],
        dragIndicator: Visibility = .automatic,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            // Plain `sheet` + detents on the presented root. ZStack/compliance pins correlated with
            // XCUITest seeing `Sheet` but no child nodes on iOS 26 (#193). Named sheet compliance was
            // flattening when chained on the same root as real content; omit until a non-invasive anchor exists.
            let detents = PlatformPresentationSizeResolver.presentationDetents(for: sizes)
            self.sheet(isPresented: isPresented, onDismiss: onDismiss) {
                content()
                    .platformPresentationFrame(sizes: sizes)
                    .presentationDetents(detents)
                    .presentationDragIndicator(dragIndicator)
            }
        } else {
            self.sheet(isPresented: isPresented, onDismiss: onDismiss) {
                content()
                    .platformPresentationFrame(sizes: sizes)
            }
        }
        #elseif os(macOS)
        self.sheet(isPresented: isPresented, onDismiss: onDismiss) {
            content()
                .platformPresentationFrame(sizes: sizes)
        }
        #else
        self.sheet(isPresented: isPresented, onDismiss: onDismiss) {
            content()
                .platformPresentationFrame(sizes: sizes)
        }
        #endif
    }
    
    /// Unified sheet presentation with item-based binding
    /// - Parameters:
    ///   - item: Optional item binding for sheet presentation
    ///   - onDismiss: Optional callback when this sheet is dismissed. For nested sheets, do only local cleanup here so it does not propagate to the parent.
    ///   - sizes: Cross-platform size hints (default: `[.large]`). iOS also projects these to presentation detents.
    ///   - dragIndicator: Whether to show drag indicator (iOS only)
    ///   - content: View builder for sheet content
    /// - Returns: View with sheet modifier applied
    @MainActor
    @ViewBuilder
    func platformSheet_L4<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        sizes: [PlatformPresentationSize] = [.large],
        dragIndicator: Visibility = .automatic,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            let detents = PlatformPresentationSizeResolver.presentationDetents(for: sizes)
            self.sheet(item: item, onDismiss: onDismiss) { item in
                content(item)
                    .platformPresentationFrame(sizes: sizes)
                    .presentationDetents(detents)
                    .presentationDragIndicator(dragIndicator)
            }
        } else {
            self.sheet(item: item, onDismiss: onDismiss) { item in
                content(item)
                    .platformPresentationFrame(sizes: sizes)
            }
        }
        #elseif os(macOS)
        self.sheet(item: item, onDismiss: onDismiss) { item in
            content(item)
                .platformPresentationFrame(sizes: sizes)
        }
        #else
        self.sheet(item: item, onDismiss: onDismiss) { item in
            content(item)
                .platformPresentationFrame(sizes: sizes)
        }
        #endif
    }
}
