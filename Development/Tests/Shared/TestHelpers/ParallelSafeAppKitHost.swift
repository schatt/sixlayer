//
//  ParallelSafeAppKitHost.swift
//  SixLayerFrameworkUnitTests
//
//  Parallel-safe AppKit hosting for controls that need a window / field editor.
//  Uses a mutex around process-global key-window use — not suite `.serialized`
//  (see no-suite-serialization / #447).
//

import Foundation
import Testing

#if canImport(AppKit)
import AppKit

/// Serializes borrow of the process-global AppKit key window.
///
/// Suites stay parallelizable; only the key-window critical section is exclusive.
enum AppKitKeyWindowIsolation {
    private static let lock = NSLock()

    @MainActor
    static func withExclusiveKeyWindow<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }
}

/// Hosts AppKit text controls without racing `makeKeyAndOrderFront` teardown across workers.
enum ParallelSafeAppKitHost {
    /// Non-key window host for `NSTextView` (string mutation + `selectedRange` without TextInputUI abort).
    @MainActor
    static func withHostedTextView(
        frame: NSRect = NSRect(x: 0, y: 0, width: 240, height: 48),
        perform: (NSTextView) throws -> Void
    ) rethrows {
        let view = NSTextView(frame: frame)
        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: true
        )
        window.isReleasedWhenClosed = false
        window.contentView = view
        window.setFrame(
            NSRect(x: -10_000, y: -10_000, width: frame.width, height: frame.height),
            display: false
        )
        window.orderOut(nil)
        HostingControllerStorage.store(controller: window, window: window, for: view)
        try perform(view)
    }

    /// Exclusive key-window host so `NSTextField.currentEditor()` is observable under parallel xctest.
    @MainActor
    static func withHostedTextField(
        string: String,
        perform: (NSTextField) throws -> Void
    ) rethrows {
        try AppKitKeyWindowIsolation.withExclusiveKeyWindow {
            let frame = NSRect(x: 0, y: 0, width: 320, height: 80)
            let field = NSTextField(string: string)
            field.frame = NSRect(x: 8, y: 28, width: 300, height: 24)
            let container = NSView(frame: frame)
            container.addSubview(field)
            let window = NSWindow(
                contentRect: frame,
                styleMask: [.titled],
                backing: .buffered,
                defer: true
            )
            window.isReleasedWhenClosed = false
            window.contentView = container
            window.setFrame(
                NSRect(x: -10_000, y: -10_000, width: frame.width, height: frame.height),
                display: false
            )
            HostingControllerStorage.store(controller: window, window: window, for: field)
            window.makeKeyAndOrderFront(nil)
            defer {
                window.orderOut(nil)
                window.contentView = nil
            }
            _ = window.makeFirstResponder(field)
            try perform(field)
        }
    }
}
#endif
