//
//  SystemImagePickerPresentation.swift
//  SixLayerFramework
//
//  Presentation lifecycle for system image pickers.
//  GitHub #441 — hosts own SwiftUI sheets/covers; representables must not call UIKit dismiss by default.
//  GitHub #442 — the policy type is cross-platform (`UnifiedImagePicker` stores it on macOS);
//  `applySystemImagePickerDismissPolicy` stays iOS-only (UIViewController).
//

import Foundation

/// How a system image picker should finish its presentation after selection or cancel.
///
/// Default is ``hostManaged``: the consumer closes SwiftUI sheets, full-screen covers, or navigation
/// via bindings or `@Environment(\.dismiss)`. Embedded inline pickers (e.g. tabbed photo-first) must
/// use this policy so UIKit does not walk the presentation chain and tear down ancestor hosts.
public enum SystemImagePickerDismissPolicy: Sendable {
    /// Never call UIKit `dismiss` from the representable coordinator. The host owns presentation.
    case hostManaged
    /// Legacy UIKit modal path only: dismiss when `presentingViewController != nil`. Prefer ``hostManaged``.
    case dismissWhenModallyPresented
}

public extension SystemImagePickerDismissPolicy {
    /// Default for all framework image pickers.
    static let `default`: SystemImagePickerDismissPolicy = .hostManaged
}

#if os(iOS)
import UIKit

/// Applies ``SystemImagePickerDismissPolicy`` after selection/cancel.
///
/// Intentionally extracted for unit tests (#441).
func applySystemImagePickerDismissPolicy(
    _ policy: SystemImagePickerDismissPolicy,
    presentingViewController: UIViewController?,
    dismiss: () -> Void
) {
    switch policy {
    case .hostManaged:
        break
    case .dismissWhenModallyPresented:
        if presentingViewController != nil {
            dismiss()
        }
    }
}
#endif
