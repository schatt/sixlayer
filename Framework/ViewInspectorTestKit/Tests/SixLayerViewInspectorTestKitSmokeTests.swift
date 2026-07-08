//
//  SixLayerViewInspectorTestKitSmokeTests.swift
//  SixLayerViewInspectorTestKitTests
//
//  Verifies the consumer test kit exports canonical ViewInspector helpers (#327).
//

import SwiftUI
import Testing
import ViewInspector
import SixLayerViewInspectorTestKit

@Suite("SixLayerViewInspectorTestKit smoke")
@MainActor
struct SixLayerViewInspectorTestKitSmokeTests {

    private struct SampleView: View, Inspectable {
        var body: some View {
            VStack {
                Text("hello")
            }
        }
    }

    @Test("inspectView returns typed hierarchy for Inspectable views")
    func inspectViewReturnsTypedHierarchy() throws {
        let view = SampleView()
        let inspected = try #require(inspectView(view))
        let vStack = try inspected.vStack()
        #expect(vStack.count == 1)
    }

    @Test("firstVStackInView resolves VStack from Inspectable root")
    func firstVStackInViewResolvesVStack() throws {
        let view = SampleView()
        let vStack = try firstVStackInView(view, minChildren: 1)
        #expect(vStack.count == 1)
    }
}
