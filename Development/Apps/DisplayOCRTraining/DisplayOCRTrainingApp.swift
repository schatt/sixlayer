//
//  DisplayOCRTrainingApp.swift
//  DisplayOCRTraining
//
//  Runnable app for the display OCR label harness (#609).
//  The window is the trainer. This shell is the wrong screen on purpose
//  until the test that demands the trainer goes green.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

@main
struct DisplayOCRTrainingApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(DisplayOCRTrainingMacDelegate.self) private var macDelegate
    #endif

    var body: some Scene {
        WindowGroup {
            DisplayOCRTrainingRootView()
        }
        #if os(macOS)
        .defaultSize(width: 980, height: 760)
        .defaultLaunchBehavior(.presented)
        #endif
    }
}

/// What the training app shows. Not the trainer yet.
struct DisplayOCRTrainingRootView: View {
    var body: some View {
        Text("Trainer shell")
    }
}

#if os(macOS)
enum DisplayOCRTrainingMacHost {
    @MainActor static func orderFront() {
        NSApp.setActivationPolicy(.regular)
        let keyable = NSApp.windows.filter(\.canBecomeKey)
        if keyable.isEmpty {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 980, height: 760),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Display OCR Training"
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: DisplayOCRTrainingRootView())
            window.center()
            window.makeKeyAndOrderFront(nil)
        } else {
            keyable.forEach { $0.makeKeyAndOrderFront(nil) }
        }
        NSApp.activate(ignoringOtherApps: true)
    }
}

final class DisplayOCRTrainingMacDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async {
            DisplayOCRTrainingMacHost.orderFront()
        }
    }
}
#endif
