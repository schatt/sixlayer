import Testing


//
//  ResponsiveLayoutComponentAccessibilityTests.swift
//  SixLayerFrameworkTests
//
//  Comprehensive accessibility tests for ALL ResponsiveLayout components
//

import SwiftUI
@testable import SixLayerFramework

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Responsive Layout Component Accessibility")
open class ResponsiveLayoutComponentAccessibilityTests: BaseTestClass {
    
    // MARK: - ResponsiveGrid Tests
    
    @Test @MainActor func testResponsiveGridGeneratesAccessibilityIdentifiers() async {
            initializeTestConfig()
        runWithTaskLocalConfig {

            // Given: Test grid items
            let gridItems = [
                GridItemData(title: "Grid Item 1", subtitle: "Subtitle 1", icon: "star", color: .blue),
                GridItemData(title: "Grid Item 2", subtitle: "Subtitle 2", icon: "heart", color: .red),
                GridItemData(title: "Grid Item 3", subtitle: "Subtitle 3", icon: "circle", color: .green)
            ]
        
            // When: Creating ResponsiveGrid with framework components
            let view = ResponsiveGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                ForEach(gridItems) { item in
                    platformPresentContent_L1(
                        content: "\(item.title) - \(item.subtitle)",
                        hints: PresentationHints()
                    )
                }
            }
        
            // Then: Should generate accessibility identifiers
            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "SixLayer.main.ui.*",
                platform: SixLayerPlatform.iOS,
                componentName: "ResponsiveGrid"
            )
            #expect(hasAccessibilityID, "ResponsiveGrid should generate accessibility identifiers ")
        }
    }

    
    // MARK: - ResponsiveNavigation Tests
    
    @Test @MainActor func testResponsiveNavigationGeneratesAccessibilityIdentifiers() async {
            initializeTestConfig()
        runWithTaskLocalConfig {

            // Given: Test navigation content
            let navigationContent = { (isHorizontal: Bool) in
                platformVStackContainer {
                    platformPresentContent_L1(
                        content: "Navigation Content",
                        hints: PresentationHints()
                    )
                }
            }
        
            // When: Creating ResponsiveNavigation
            let view = ResponsiveNavigation(content: navigationContent)
            // Then: Should generate accessibility identifiers
            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "SixLayer.main.ui.*",
                platform: SixLayerPlatform.iOS,
                componentName: "ResponsiveNavigation"
            )
            #expect(hasAccessibilityID, "ResponsiveNavigation should generate accessibility identifiers ")
        }
    }

    
    // MARK: - ResponsiveStack Tests
    
    @Test @MainActor func testResponsiveStackGeneratesAccessibilityIdentifiers() async {
            initializeTestConfig()
        runWithTaskLocalConfig {

            // Given: Test stack content
            let stackContent = {
                platformVStackContainer {
                    platformPresentContent_L1(content: "Stack Item 1", hints: PresentationHints())
                    platformPresentContent_L1(content: "Stack Item 2", hints: PresentationHints())
                    platformPresentContent_L1(content: "Stack Item 3", hints: PresentationHints())
                }
            }
        
            // When: Creating ResponsiveStack
            let view = ResponsiveStack(content: stackContent)
            // Then: Should generate accessibility identifiers
            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "SixLayer.main.ui.*",
                platform: SixLayerPlatform.iOS,
                componentName: "ResponsiveStack"
            )
            #expect(hasAccessibilityID, "ResponsiveStack should generate accessibility identifiers ")
        }
    }

    
    // MARK: - ResponsiveLayoutExample Tests
    
    @Test @MainActor func testResponsiveLayoutExampleGeneratesAccessibilityIdentifiers() async {
            initializeTestConfig()
        runWithTaskLocalConfig {

            // When: Creating ResponsiveLayoutExample
            let view = ResponsiveLayoutExample()
        
            // Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: ResponsiveLayoutExample DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Components/Views/ResponsiveLayout.swift:207.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "SixLayer.main.ui.*",
                platform: SixLayerPlatform.iOS,
                componentName: "ResponsiveLayoutExample"
            )
            #expect(hasAccessibilityID, "ResponsiveLayoutExample should generate accessibility identifiers ")
        }
    }

    
    // MARK: - ResponsiveNavigationExample Tests
    
    @Test @MainActor func testResponsiveNavigationExampleGeneratesAccessibilityIdentifiers() async {
            initializeTestConfig()
        runWithTaskLocalConfig {

            // When: Creating ResponsiveNavigationExample
            let view = ResponsiveNavigationExample()
        
            // Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: ResponsiveNavigationExample DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Components/Views/ResponsiveLayout.swift:233.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "SixLayer.main.ui.*",
                platform: SixLayerPlatform.iOS,
                componentName: "ResponsiveNavigationExample"
            )
            #expect(hasAccessibilityID, "ResponsiveNavigationExample should generate accessibility identifiers ")
        }
    }

    
    // MARK: - ResponsivePadding Modifier Tests
    
    @Test @MainActor func testResponsivePaddingModifierGeneratesAccessibilityIdentifiers() async {
            initializeTestConfig()
        runWithTaskLocalConfig {

            // Given: Test content
            let testContent = platformPresentContent_L1(
                content: "Test Content",
                hints: PresentationHints()
            )
        
            // When: Applying ResponsivePadding modifier
            let view = testContent.modifier(ResponsivePadding())
            // Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: ResponsivePadding DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Components/Views/ResponsiveLayout.swift:100.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "SixLayer.main.ui.*",
                platform: SixLayerPlatform.iOS,
                componentName: "ResponsivePadding"
            )
            #expect(hasAccessibilityID, "ResponsivePadding modifier should generate accessibility identifiers ")
        }
    }

}
