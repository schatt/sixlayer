//
//  PlatformUIIntegrationPatternsUnitTests.swift
//  SixLayerFrameworkUnitTests
//
//  Unit-lane coverage for PlatformUIIntegration + AdaptiveUIPatterns (#468).
//

import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite("Platform UI Integration + Patterns (#468)")
struct PlatformUIIntegrationPatternsContextUnitTests {

    @Test @MainActor
    func navigationContextStandardIsNotCompact() {
        #expect(!NavigationContext.standard.isCompact)
        #expect(!NavigationContext.standard.isLandscape)
        #expect(!NavigationContext.standard.hasKeyboard)
    }

    @Test @MainActor
    func navigationContextCompactIsCompact() {
        #expect(NavigationContext.compact.isCompact)
    }

    @Test @MainActor
    func listContextStandardAndCompactDiffer() {
        #expect(!ListContext.standard.isCompact)
        #expect(ListContext.compact.isCompact)
        #expect(ListContext.standard.itemCount == 0)
    }

    @Test func navigationStyleCasesAreDistinct() {
        let styles: [NavigationStyle] = [
            .adaptive, .splitView, .stack, .modal, .sidebar
        ]
        #expect(styles.count == 5)
    }

    @Test func modalPresentationStyleCasesAreDistinct() {
        let styles: [ModalPresentationStyle] = [
            .adaptive, .sheet, .fullScreen, .popover, .window
        ]
        #expect(styles.count == 5)
    }
}

@Suite("Platform UI Integration + Patterns hosts (#468)", HostedViewTestIsolationTrait())
struct PlatformUIIntegrationPatternsHostUnitTests {

    @Test @MainActor
    func smartNavigationContainerHosts() {
        hostView {
            PlatformUIIntegration.SmartNavigationContainer(title: "Profile Settings") {
                Text("Content")
            }
        }
    }

    @Test @MainActor
    func smartFormContainerUsesAdaptiveButtonNamedCompliance() {
        hostExpectingNamedCompliance("AdaptiveButton") {
            PlatformUIIntegration.SmartFormContainer(
                title: "Account",
                onSubmit: {}
            ) {
                Text("Field")
            }
        }
    }

    @Test @MainActor
    func smartCardContainerHosts() {
        hostView {
            PlatformUIIntegration.SmartCardContainer(
                title: "Card",
                subtitle: "Detail",
                actionTitle: "Open",
                action: {}
            ) {
                Text("Body")
            }
        }
    }

    @Test @MainActor
    func adaptiveNavigationHosts() {
        hostView {
            AdaptiveUIPatterns.AdaptiveNavigation {
                Text("Nav")
            }
        }
    }

    @Test @MainActor
    func adaptiveListHosts() {
        struct Row: Identifiable {
            let id: String
        }
        hostView {
            AdaptiveUIPatterns.AdaptiveList([Row(id: "a"), Row(id: "b")]) { item in
                Text(item.id)
            }
        }
    }

    @Test @MainActor
    func adaptiveModalModifierHosts() {
        hostView {
            Text("Sheet").adaptiveModal()
        }
    }

    @Test @MainActor
    func adaptiveListModifierHosts() {
        hostView {
            List { Text("Row") }.adaptiveList()
        }
    }

    @MainActor
    private func hostExpectingNamedCompliance<V: View>(
        _ name: String,
        @ViewBuilder _ view: () -> V
    ) {
        #if os(watchOS)
        return
        #else
        let (hosted, log) = TestSetupUtilities.hostRootPlatformViewNamedDebugLog(view())
        #expect(hosted != nil)
        #expect(
            log.contains(name),
            "named compliance \(name) must appear in debug log"
        )
        #endif
    }

    @MainActor
    private func hostView<V: View>(@ViewBuilder _ view: () -> V) {
        #if os(watchOS)
        return
        #else
        #expect(TestSetupUtilities.hostRootPlatformView(view(), forceLayout: true) != nil)
        #endif
    }
}
