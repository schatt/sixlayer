//
//  ViewInspectorInspectableConformances.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE: Allow ViewInspector to traverse key framework views directly (Option A for Issue 178).
//  Conformances are in the test target so the framework does not depend on ViewInspector.
//

import SwiftUI
@testable import SixLayerFramework

#if canImport(ViewInspector)
import ViewInspector

// MARK: - Form views (direct inspection so ViewInspector can traverse — Option A for Issue 178)

extension DynamicFormView: ViewInspector.Inspectable {}
extension FormProgressIndicator: ViewInspector.Inspectable {}
extension DynamicFormSectionView: ViewInspector.Inspectable {}

// MARK: - Layer 5 platform components (so firstVStackInHierarchy(inspected) works)

extension PlatformRecognitionLayer5: ViewInspector.Inspectable {}
extension PlatformPrivacyLayer5: ViewInspector.Inspectable {}
extension PlatformSafetyLayer5: ViewInspector.Inspectable {}
extension PlatformProfilingLayer5: ViewInspector.Inspectable {}
extension PlatformOptimizationLayer5: ViewInspector.Inspectable {}
extension PlatformRoutingLayer5: ViewInspector.Inspectable {}
extension PlatformOrchestrationLayer5: ViewInspector.Inspectable {}
extension PlatformNotificationLayer5: ViewInspector.Inspectable {}
extension PlatformOrganizationLayer5: ViewInspector.Inspectable {}
extension PlatformInterpretationLayer5: ViewInspector.Inspectable {}
extension PlatformKnowledgeLayer5: ViewInspector.Inspectable {}
extension PlatformWisdomLayer5: ViewInspector.Inspectable {}
extension PlatformLoggingLayer5: ViewInspector.Inspectable {}
extension PlatformMaintenanceLayer5: ViewInspector.Inspectable {}

// MARK: - Layer 6 (performance)

extension PlatformPerformanceLayer6: ViewInspector.Inspectable {}
#endif
