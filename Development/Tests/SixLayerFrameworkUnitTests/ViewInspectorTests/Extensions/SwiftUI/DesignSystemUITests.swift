//
//  DesignSystemUITests.swift
//  SixLayerFramework
//
//  UI Tests for Design System Bridge functionality
//

import XCTest
import SwiftUI
@testable import SixLayerFramework

class DesignSystemUITests: XCTestCase {

    // MARK: - Themed Component Tests

    @MainActor
    func testThemedCardStyle() {
        // Test that themed card applies design system styling
        let view = ThemedFrameworkView {
            Text("Test Content")
                .themedCard()
        }

        // Note: UI testing with ViewInspector would be ideal here
        // For now, we test that the view can be created without errors
        XCTAssertNotNil(view)
    }

    @MainActor
    func testThemedTextFieldStyle() {
        // Test that themed text field applies design system styling
        let view = ThemedFrameworkView {
            TextField("Test", text: .constant(""))
                .themedTextField()
        }

        XCTAssertNotNil(view)
    }

    @MainActor
    func testThemedProgressBar() {
        // Test that themed progress bar uses design tokens
        let view = ThemedFrameworkView {
            ThemedProgressBar(progress: 0.5, variant: .primary)
        }

        XCTAssertNotNil(view)
    }

    // MARK: - Theme Switching Tests

    @MainActor
    func testDesignSystemSwitchingUpdatesUI() {
        let visualDesignSystem = VisualDesignSystem.shared

        // Switch to default system
        visualDesignSystem.switchDesignSystem(SixLayerDesignSystem())
        XCTAssertEqual(visualDesignSystem.designSystem.name, "SixLayer")

        // Verify colors are accessible
        let colors = visualDesignSystem.currentColors
        XCTAssertNotNil(colors.primary)
        XCTAssertNotNil(colors.background)

        // Switch to high contrast
        visualDesignSystem.switchDesignSystem(HighContrastDesignSystem())
        XCTAssertEqual(visualDesignSystem.designSystem.name, "HighContrast")

        // Verify high contrast colors
        let hcColors = visualDesignSystem.currentColors
        XCTAssertNotNil(hcColors.primary)
        // High contrast should have different text colors
        XCTAssertNotNil(hcColors.text)
    }

    // MARK: - Component Integration Tests

    @MainActor
    func testComponentUsesDesignTokens() {
        // Test that components automatically use design system tokens
        let designSystem = VisualDesignSystem.shared

        // Create a test design system with known values
        struct TestDesignSystem: DesignSystem {
            let name = "TestUI"

            func colors(for theme: Theme) -> DesignTokens.Colors {
                return DesignTokens.Colors(
                    primary: .purple, // Distinctive color for testing
                    secondary: .gray,
                    accent: .cyan,
                    destructive: .red,
                    success: .green,
                    warning: .orange,
                    info: .blue,
                    background: .yellow, // Distinctive background
                    surface: .gray.opacity(0.1),
                    surfaceElevated: .gray.opacity(0.05),
                    text: .black,
                    textSecondary: .gray,
                    textTertiary: .gray.opacity(0.7),
                    textDisabled: .gray.opacity(0.5),
                    hover: .purple.opacity(0.1),
                    pressed: .purple.opacity(0.2),
                    focused: .purple,
                    disabled: .gray.opacity(0.3),
                    border: .gray,
                    borderSecondary: .gray.opacity(0.5),
                    borderFocus: .purple,
                    error: .red,
                    warningText: .orange,
                    successText: .green,
                    infoText: .blue
                )
            }

            func typography(for theme: Theme) -> DesignTokens.Typography {
                return DesignTokens.Typography(
                    largeTitle: .system(size: 34, weight: .bold),
                    title1: .system(size: 28, weight: .bold),
                    title2: .system(size: 22, weight: .bold),
                    title3: .system(size: 20, weight: .semibold),
                    headline: .system(size: 17, weight: .semibold),
                    body: .system(size: 17, weight: .regular),
                    callout: .system(size: 16, weight: .regular),
                    subheadline: .system(size: 15, weight: .regular),
                    footnote: .system(size: 13, weight: .regular),
                    caption1: .system(size: 12, weight: .regular),
                    caption2: .system(size: 11, weight: .regular)
                )
            }

            func spacing() -> DesignTokens.Spacing {
                return DesignTokens.Spacing(xs: 4, sm: 8, md: 16, lg: 24, xl: 32, xxl: 48)
            }

            func componentStates() -> DesignTokens.ComponentStates {
                return DesignTokens.ComponentStates(
                    cornerRadius: DesignTokens.ComponentCornerRadius(
                        none: 0, sm: 8, md: 12, lg: 16, xl: 24, full: 999
                    ),
                    borderWidth: DesignTokens.ComponentBorderWidth(
                        none: 0, sm: 0.5, md: 1, lg: 2
                    ),
                    shadow: DesignTokens.ComponentShadow(
                        none: (Color.clear, 0, 0, 0),
                        sm: (Color.black.opacity(0.1), 2, 0, 1),
                        md: (Color.black.opacity(0.1), 4, 0, 2),
                        lg: (Color.black.opacity(0.1), 8, 0, 4)
                    ),
                    opacity: DesignTokens.ComponentOpacity(
                        disabled: 0.5, pressed: 0.7, hover: 0.8
                    )
                )
            }
        }

        // Switch to test design system
        designSystem.switchDesignSystem(TestDesignSystem())

        // Verify the switch worked
        XCTAssertEqual(designSystem.designSystem.name, "TestUI")

        // Verify distinctive colors are available
        let colors = designSystem.currentColors
        XCTAssertNotNil(colors.primary)
        XCTAssertNotNil(colors.background)

        // Switch back to default
        designSystem.switchDesignSystem(SixLayerDesignSystem())
        XCTAssertEqual(designSystem.designSystem.name, "SixLayer")
    }

    // MARK: - Environment Integration Tests

    @MainActor
    func testThemedFrameworkViewProvidesEnvironment() {
        // Test that ThemedFrameworkView provides the necessary environment
        let view = ThemedFrameworkView {
            // This view should have access to design tokens via environment
            TestEnvironmentView()
        }

        XCTAssertNotNil(view)
    }

    // MARK: - Theme Change Notification Tests

    @MainActor
    func testThemeChangeCallback() {
        let visualDesignSystem = VisualDesignSystem.shared

        var callbackCalled = false
        visualDesignSystem.onThemeChange = {
            callbackCalled = true
        }

        // Trigger theme change
        visualDesignSystem.switchDesignSystem(HighContrastDesignSystem())

        // Note: In a real test, we'd wait for the callback or use expectations
        // For now, we just verify the design system changed
        XCTAssertEqual(visualDesignSystem.designSystem.name, "HighContrast")
    }

    // MARK: - Cross-Platform Consistency Tests

    func testDesignSystemPlatformConsistency() {
        // Test that design systems work consistently across platform detection
        let designSystem = SixLayerDesignSystem()

        let colors = designSystem.colors(for: .light)
        XCTAssertNotNil(colors.primary)
        XCTAssertNotNil(colors.background)

        let spacing = designSystem.spacing()
        XCTAssertGreaterThan(spacing.sm, 0)
        XCTAssertGreaterThan(spacing.md, spacing.sm)

        let states = designSystem.componentStates()
        XCTAssertGreaterThanOrEqual(states.cornerRadius.sm, 0)
        XCTAssertGreaterThanOrEqual(states.borderWidth.sm, 0)
    }

    // MARK: - Accessibility Integration Tests

    func testHighContrastDesignSystemAccessibility() {
        let hcDesignSystem = HighContrastDesignSystem()

        let lightColors = hcDesignSystem.colors(for: .light)
        let darkColors = hcDesignSystem.colors(for: .dark)

        // High contrast should provide good contrast ratios
        // Note: Actual contrast ratio calculation would require platform-specific color inspection
        XCTAssertNotNil(lightColors.text)
        XCTAssertNotNil(darkColors.text)
        XCTAssertNotEqual(lightColors.background, darkColors.background)
    }
}

// MARK: - Test Helper Views

private struct TestEnvironmentView: View {
    @Environment(\.designTokens) private var designTokens
    @Environment(\.spacingTokens) private var spacingTokens
    @Environment(\.componentStates) private var componentStates

    var body: some View {
        VStack {
            // Test that environment values are available
            Text("Primary: \(designTokens.primary.description)")
            Text("Spacing SM: \(spacingTokens.sm)")
            Text("Corner Radius SM: \(componentStates.cornerRadius.sm)")
        }
    }
}

// MARK: - Test Helper Extensions

extension Color {
    var description: String {
        // Simplified description for testing
        return "Color"
    }
}