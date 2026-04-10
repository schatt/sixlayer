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
/// **Size**: Small to medium (typically 200-400 points wide)
///
/// ### Sheets
/// **Semantic Purpose**: Modal presentation for focused tasks or detailed content
/// - **iOS**: 
///   - **iPhone**: Full-screen modal (default) or half-sheet with detents (iOS 16+)
///   - **iPad**: Centered modal window (can be resized)
///   - Supports drag-to-dismiss gestures
/// - **macOS**: Modal window (not full-screen)
///   - Appears as a centered window with minimum size constraints
///   - User can move/resize the window
///   - More window-like than iOS sheets
///
/// **When to Use**: Forms, detail views, editing interfaces, multi-step workflows
/// **Size**: Medium to large (typically 400-800+ points)
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
    ///   - content: View builder for popover content
    /// - Returns: View with popover modifier applied
    @ViewBuilder
    func platformPopover_L4<Content: View>(
        isPresented: Binding<Bool>,
        attachmentAnchor: PopoverAttachmentAnchor = .point(.center),
        arrowEdge: Edge = .top,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        #if os(iOS)
        self.popover(
            isPresented: isPresented,
            attachmentAnchor: attachmentAnchor,
            arrowEdge: arrowEdge,
            content: content
        )
        .automaticCompliance(named: "platformPopover_L4")
        #elseif os(macOS)
        self.popover(
            isPresented: isPresented,
            attachmentAnchor: attachmentAnchor,
            arrowEdge: arrowEdge,
            content: content
        )
        .automaticCompliance(named: "platformPopover_L4")
        #else
        self.popover(
            isPresented: isPresented,
            attachmentAnchor: attachmentAnchor,
            arrowEdge: arrowEdge,
            content: content
        )
        .automaticCompliance(named: "platformPopover_L4")
        #endif
    }
    
    /// Unified sheet presentation helper
    ///
    /// **Cross-Platform Behavior:**
    /// - **iOS (iPhone)**: Full-screen modal (default) or half-sheet with detents (iOS 16+)
    ///   - Supports drag-to-dismiss gestures
    ///   - Can use `.medium` or `.large` detents for partial screen coverage
    /// - **iOS (iPad)**: Centered modal window (can be resized)
    /// - **macOS**: Modal window (not full-screen)
    ///   - Minimum size: 400x300 points
    ///   - User can move and resize the window
    ///   - Detents parameter is ignored (macOS doesn't support detents)
    ///
    /// **Use For**: Forms, detail views, editing interfaces, multi-step workflows
    ///
    /// - Parameters:
    ///   - isPresented: Binding to control sheet presentation
    ///   - onDismiss: Optional callback when this sheet is dismissed. For nested sheets, do only local cleanup here so it does not propagate to the parent (see file-level "Nested Sheets" docs).
    ///   - detents: Presentation detents for iOS (default: [.large]). Ignored on macOS.
    ///   - dragIndicator: Whether to show drag indicator (iOS only, ignored on macOS)
    ///   - content: View builder for sheet content
    /// - Returns: View with sheet modifier applied
    @ViewBuilder
    func platformSheet_L4<Content: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        detents: Set<PresentationDetent> = [.large],
        dragIndicator: Visibility = .automatic,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            self.sheet(isPresented: isPresented, onDismiss: onDismiss) {
                content()
                    .presentationDetents(detents)
                    .presentationDragIndicator(dragIndicator)
            }
            .automaticCompliance(named: "platformSheet_L4")
        } else {
            self.sheet(isPresented: isPresented, onDismiss: onDismiss, content: content)
                .automaticCompliance(named: "platformSheet_L4")
        }
        #elseif os(macOS)
        self.sheet(isPresented: isPresented, onDismiss: onDismiss) {
            content()
                .frame(minWidth: 400, minHeight: 300)
        }
        .automaticCompliance(named: "platformSheet_L4")
        #else
        self.sheet(isPresented: isPresented, onDismiss: onDismiss, content: content)
            .automaticCompliance(named: "platformSheet_L4")
        #endif
    }
    
    /// Unified sheet presentation with item-based binding
    /// - Parameters:
    ///   - item: Optional item binding for sheet presentation
    ///   - onDismiss: Optional callback when this sheet is dismissed. For nested sheets, do only local cleanup here so it does not propagate to the parent.
    ///   - detents: Presentation detents for iOS (default: [.large])
    ///   - dragIndicator: Whether to show drag indicator (iOS only)
    ///   - content: View builder for sheet content
    /// - Returns: View with sheet modifier applied
    @ViewBuilder
    func platformSheet_L4<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        detents: Set<PresentationDetent> = [.large],
        dragIndicator: Visibility = .automatic,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            self.sheet(item: item, onDismiss: onDismiss) { item in
                content(item)
                    .presentationDetents(detents)
                    .presentationDragIndicator(dragIndicator)
            }
            .automaticCompliance(named: "platformSheet_L4")
        } else {
            self.sheet(item: item, onDismiss: onDismiss, content: content)
                .automaticCompliance(named: "platformSheet_L4")
        }
        #elseif os(macOS)
        self.sheet(item: item, onDismiss: onDismiss) { item in
            content(item)
                .frame(minWidth: 400, minHeight: 300)
        }
        .automaticCompliance(named: "platformSheet_L4")
        #else
        self.sheet(item: item, onDismiss: onDismiss, content: content)
            .automaticCompliance(named: "platformSheet_L4")
        #endif
    }
}

