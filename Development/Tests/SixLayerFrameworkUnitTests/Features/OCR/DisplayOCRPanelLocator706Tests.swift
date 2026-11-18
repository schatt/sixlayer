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
        let mapped = DisplayOCRPanelLocator.topLeftPixelRect(
            visionBox: CGRect(x: 0.1, y: 0.6, width: 0.3, height: 0.2),
            imageWidth: 1000,
            imageHeight: 500
        )
        let rect = mapped ?? .zero
        #expect(abs(rect.minX - 100) < 0.001)
        #expect(abs(rect.minY - 100) < 0.001)
        #expect(abs(rect.width - 300) < 0.001)
        #expect(abs(rect.height - 100) < 0.001)
    }

    @Test func chosenVisionBoxPicksHighestConfidentPanelLabel() {
        let panel = CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.1)
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
        #expect(abs((clipped?.width ?? -1) - 0.3) < 0.000_001)
        #expect(abs((clipped?.height ?? -1) - 0.8) < 0.000_001)
        #expect(DisplayOCRNormalizedBox(x: 0, y: 0, width: 0, height: 1).unitClamped == nil)

        let a = DisplayOCRNormalizedBox(x: 0, y: 0, width: 0.5, height: 0.5)
        let b = DisplayOCRNormalizedBox(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
        // Intersection 0.25×0.25; union 0.25+0.25-0.0625 = 0.4375 → IoU = 1/7
        #expect(abs(a.iou(b) - (0.0625 / 0.4375)) < 0.000_001)
    }
}
