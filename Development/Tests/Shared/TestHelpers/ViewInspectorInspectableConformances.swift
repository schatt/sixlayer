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
extension DynamicFormViewInner: ViewInspector.Inspectable {}
extension DynamicFormFieldView: ViewInspector.Inspectable {}
extension FormProgressIndicator: ViewInspector.Inspectable {}
extension DynamicFormSectionView: ViewInspector.Inspectable {}
extension FormWizardView: ViewInspector.Inspectable {}
extension FormWizardViewInner: ViewInspector.Inspectable {}

// MARK: - Dynamic form field components (direct inspection — Issue 178 / #242)

extension DynamicTextField: ViewInspector.Inspectable {}
extension DynamicEmailField: ViewInspector.Inspectable {}
extension DynamicPasswordField: ViewInspector.Inspectable {}
extension DynamicPhoneField: ViewInspector.Inspectable {}
extension DynamicURLField: ViewInspector.Inspectable {}
extension DynamicNumberField: ViewInspector.Inspectable {}
extension DynamicIntegerField: ViewInspector.Inspectable {}
extension DynamicStepperField: ViewInspector.Inspectable {}
extension DynamicDateField: ViewInspector.Inspectable {}
extension DynamicTimeField: ViewInspector.Inspectable {}
extension DynamicDateTimeField: ViewInspector.Inspectable {}
extension DynamicMultiDateField: ViewInspector.Inspectable {}
extension DynamicMultiSelectField: ViewInspector.Inspectable {}
extension DynamicRadioField: ViewInspector.Inspectable {}
extension DynamicCheckboxField: ViewInspector.Inspectable {}
extension DynamicRichTextField: ViewInspector.Inspectable {}
extension DynamicFileField: ViewInspector.Inspectable {}
extension DynamicImageField: ViewInspector.Inspectable {}
extension DynamicRangeField: ViewInspector.Inspectable {}
extension DynamicArrayField: ViewInspector.Inspectable {}
extension DynamicDataField: ViewInspector.Inspectable {}
extension DynamicAutocompleteField: ViewInspector.Inspectable {}
extension DynamicEnumField: ViewInspector.Inspectable {}
extension DynamicCustomField: ViewInspector.Inspectable {}
extension DynamicColorField: ViewInspector.Inspectable {}
extension DynamicToggleField: ViewInspector.Inspectable {}
extension DynamicTextAreaField: ViewInspector.Inspectable {}
extension DynamicDisplayField: ViewInspector.Inspectable {}
extension DynamicGaugeField: ViewInspector.Inspectable {}

extension DynamicSelectField: ViewInspector.Inspectable {}

// MARK: - Field container shell (Issue #178 / #314)

extension DynamicFormFieldStandardContainer: ViewInspector.Inspectable where Content: ViewInspector.Inspectable {}

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

// MARK: - Card expansion components (direct inspection, avoid AnyView — Issue 178)

extension ExpandableCardCollectionView: ViewInspector.Inspectable where Item: Identifiable {}
extension ExpandableCardComponent: ViewInspector.Inspectable where Item: Identifiable {}
extension CoverFlowCollectionView: ViewInspector.Inspectable where Item: Identifiable {}
extension CoverFlowCardComponent: ViewInspector.Inspectable where Item: Identifiable {}
extension GridCollectionView: ViewInspector.Inspectable where Item: Identifiable {}
extension ListCollectionView: ViewInspector.Inspectable where Item: Identifiable {}
extension MasonryCollectionView: ViewInspector.Inspectable where Item: Identifiable {}
extension AdaptiveCollectionView: ViewInspector.Inspectable where Item: Identifiable {}
extension SimpleCardComponent: ViewInspector.Inspectable where Item: Identifiable {}
extension ListCardComponent: ViewInspector.Inspectable where Item: Identifiable {}
extension MasonryCardComponent: ViewInspector.Inspectable where Item: Identifiable {}
extension NativeExpandableCardView: ViewInspector.Inspectable where Item: Identifiable {}
extension iOSExpandableCardView: ViewInspector.Inspectable where Item: Identifiable {}
#if os(macOS)
extension macOSExpandableCardView: ViewInspector.Inspectable where Item: Identifiable {}
#endif
extension visionOSExpandableCardView: ViewInspector.Inspectable where Item: Identifiable {}
extension PlatformAwareExpandableCardView: ViewInspector.Inspectable where Item: Identifiable {}
#endif
