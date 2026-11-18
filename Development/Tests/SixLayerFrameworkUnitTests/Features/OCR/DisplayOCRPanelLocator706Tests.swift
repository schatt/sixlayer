//
//  DisplayOCRPanelLocator706Tests.swift
//  SixLayerFrameworkUnitTests
//
//  Runtime panel-model load hook kept in SixLayer after lab extract (#706).
//  Geometry coverage migrated from DisplayOCRTraining609Tests.
//

import CoreGraphics
import Foundation
import Testing
@testable import SixLayerFramework

@Suite("Display OCR panel locator load (#706)")
struct DisplayOCRPanelLocator706Tests {

    @Test func coreMLReturnsNilWhenModelFileIsMissing() {
        let missing = URL(fileURLWithPath: "/tmp/display-ocr-lab-missing-\(UUID().uuidString).mlmodel")
        #expect(DisplayOCRPanelLocator.coreML(modelAt: missing) == nil)
    }

    @Test func topLeftPixelRectMapsVisionBottomLeftBox() {
        let vision = CGRect(x: 0.1, y: 0.2, width: 0.5, height: 0.25)
        let mapped = DisplayOCRPanelLocator.topLeftPixelRect(
            visionBox: vision,
            imageWidth: 200,
            imageHeight: 100
        )
        #expect(mapped != nil)
        #expect(abs((mapped?.minX ?? -1) - 20) < 0.5)
        #expect(abs((mapped?.width ?? -1) - 100) < 0.5)
        #expect(abs((mapped?.height ?? -1) - 25) < 0.5)
        // Vision y is bottom-left; top-left y = (1 - maxY) * height = 0.55 * 100
        #expect(abs((mapped?.minY ?? -1) - 55) < 0.5)
    }

    @Test func chosenVisionBoxPicksHighestConfidentPanelLabel() {
        let panel = CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.3)
        let chosen = DisplayOCRPanelLocator.chosenVisionBox(from: [
            DisplayOCRPanelCandidate(label: "other", confidence: 0.99, box: CGRect(x: 0, y: 0, width: 1, height: 1)),
            DisplayOCRPanelCandidate(label: DisplayOCRPanelLocator.panelLabel, confidence: 0.8, box: panel),
            DisplayOCRPanelCandidate(label: DisplayOCRPanelLocator.panelLabel, confidence: 0.4, box: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2)),
            DisplayOCRPanelCandidate(label: DisplayOCRPanelLocator.panelLabel, confidence: 0.29, box: CGRect(x: 0.5, y: 0.5, width: 0.2, height: 0.2))
        ])
        #expect(chosen == panel)
        let weak = DisplayOCRPanelLocator.chosenVisionBox(from: [
            DisplayOCRPanelCandidate(label: DisplayOCRPanelLocator.panelLabel, confidence: 0.29, box: panel)
        ])
        #expect(weak == nil)
    }

    @Test func normalizedBoxUnitClampAndIoU() {
        let clipped = DisplayOCRNormalizedBox(x: -0.2, y: 0.2, width: 0.5, height: 2).unitClamped
        #expect(clipped?.x == 0)
        #expect(clipped?.y == 0.2)
        #expect(abs((clipped?.width ?? -1) - 0.5) < 0.0001)
        #expect(abs((clipped?.height ?? -1) - 0.8) < 0.0001)

        let a = DisplayOCRNormalizedBox(x: 0, y: 0, width: 1, height: 1)
        let b = DisplayOCRNormalizedBox(x: 0.5, y: 0.5, width: 1, height: 1)
        #expect(abs(a.iou(b) - (0.25 / 1.75)) < 0.0001)
    }
}
