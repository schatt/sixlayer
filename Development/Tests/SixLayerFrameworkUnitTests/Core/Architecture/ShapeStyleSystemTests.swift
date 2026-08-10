import Testing
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
@testable import SixLayerFramework

/**
 * BUSINESS PURPOSE: ShapeStyleSystem exposes platform-aware colors, gradients, materials,
 * hierarchical styles, and view modifiers for consistent HIG-aligned styling.
 *
 * TESTING SCOPE: Color identity vs SwiftUI tokens, factory AnyShapeStyle production,
 * variant enum coverage, hostability of modifier outputs.
 *
 * METHODOLOGY: Unit contracts — no Bool(true) / non-optional theater (#382).
 */
@Suite("Shape Style System", HostedViewTestIsolationTrait())
open class ShapeStyleSystemTests: BaseTestClass {

    @MainActor
    private func expectHostable<V: View>(_ view: V, _ label: String) {
        #expect(
            PlatformContainerStructureAssertions.isHostable(view),
            "\(label) should be hostable (#382)"
        )
    }

    #if canImport(UIKit)
    private func uiColor(_ color: Color) -> UIColor { UIColor(color) }
    #elseif canImport(AppKit)
    private func nsColor(_ color: Color) -> NSColor { NSColor(color) }
    #endif

    // MARK: - Color Support

    @Test func testStandardColorsMatchSwiftUITokens() {
        // SwiftUI Color.== is not a reliable semantic check; resolve via platform UI color.
        #if canImport(UIKit)
        #expect(uiColor(ShapeStyleSystem.StandardColors.error) == uiColor(Color.red))
        #expect(uiColor(ShapeStyleSystem.StandardColors.success) == uiColor(Color.green))
        #expect(uiColor(ShapeStyleSystem.StandardColors.warning) == uiColor(Color.orange))
        #expect(uiColor(ShapeStyleSystem.StandardColors.info) == uiColor(Color.blue))
        #expect(uiColor(ShapeStyleSystem.StandardColors.error) != uiColor(ShapeStyleSystem.StandardColors.success))
        #elseif canImport(AppKit)
        #expect(nsColor(ShapeStyleSystem.StandardColors.error) == nsColor(Color.red))
        #expect(nsColor(ShapeStyleSystem.StandardColors.success) == nsColor(Color.green))
        #expect(nsColor(ShapeStyleSystem.StandardColors.warning) == nsColor(Color.orange))
        #expect(nsColor(ShapeStyleSystem.StandardColors.info) == nsColor(Color.blue))
        #expect(nsColor(ShapeStyleSystem.StandardColors.error) != nsColor(ShapeStyleSystem.StandardColors.success))
        #endif
    }

    @Test func testPlatformSpecificColorsMatchExtensions() {
        #if canImport(UIKit)
        #expect(uiColor(ShapeStyleSystem.StandardColors.systemBackground) == uiColor(Color.systemBackground))
        #expect(uiColor(ShapeStyleSystem.StandardColors.label) == uiColor(Color.platformLabel))
        #expect(uiColor(ShapeStyleSystem.StandardColors.separator) == uiColor(Color.platformSeparator))
        #elseif canImport(AppKit)
        #expect(nsColor(ShapeStyleSystem.StandardColors.systemBackground) == nsColor(Color.systemBackground))
        #expect(nsColor(ShapeStyleSystem.StandardColors.label) == nsColor(Color.platformLabel))
        #expect(nsColor(ShapeStyleSystem.StandardColors.separator) == nsColor(Color.platformSeparator))
        #endif
    }

    // MARK: - Gradients

    @Test func testGradientsExposeExpectedVariants() {
        // focus is RadialGradient; others are LinearGradient — bind by concrete type.
        let linear: [LinearGradient] = [
            ShapeStyleSystem.Gradients.primary,
            ShapeStyleSystem.Gradients.secondary,
            ShapeStyleSystem.Gradients.background,
            ShapeStyleSystem.Gradients.success,
            ShapeStyleSystem.Gradients.warning,
            ShapeStyleSystem.Gradients.error
        ]
        let _: RadialGradient = ShapeStyleSystem.Gradients.focus
        #expect(linear.count == 6)
        #expect(GradientVariant.allCases.count == 7)
    }

    // MARK: - Materials

    @Test @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @MainActor func testMaterialsProduceHostableFills() {
        // Material is not Equatable; observe factory variants + hostability.
        let materials: [Material] = [
            ShapeStyleSystem.Materials.regular,
            ShapeStyleSystem.Materials.thick,
            ShapeStyleSystem.Materials.thin,
            ShapeStyleSystem.Materials.ultraThin,
            ShapeStyleSystem.Materials.ultraThick
        ]
        #expect(materials.count == 5)
        #expect(MaterialVariant.allCases.count == 5)
        let sut = Rectangle().fill(materials[0]).frame(width: 10, height: 10)
        expectHostable(sut, "Materials.regular fill")
    }

    // MARK: - Hierarchical

    @Test @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @MainActor func testHierarchicalStylesProduceHostableForeground() {
        // HierarchicalShapeStyle is not Equatable; bind concrete types + host.
        let styles: [HierarchicalShapeStyle] = [
            ShapeStyleSystem.HierarchicalStyles.primary,
            ShapeStyleSystem.HierarchicalStyles.secondary,
            ShapeStyleSystem.HierarchicalStyles.tertiary,
            ShapeStyleSystem.HierarchicalStyles.quaternary
        ]
        #expect(styles.count == 4)
        #expect(HierarchicalVariant.allCases.count == 4)
        let sut = Text("Sample").foregroundStyle(styles[0])
        expectHostable(sut, "HierarchicalStyles.primary foreground")
    }

    // MARK: - Factory

    @Test @MainActor func testFactoryBackgroundProducesHostableFill() {
        let style = ShapeStyleSystem.Factory.background(for: .iOS)
        let sut = Rectangle().fill(style).frame(width: 10, height: 10)
        expectHostable(sut, "Factory.background fill")
    }

    @Test @MainActor func testFactorySurfaceProducesHostableFill() {
        let style = ShapeStyleSystem.Factory.surface(for: .macOS)
        let sut = Rectangle().fill(style).frame(width: 10, height: 10)
        expectHostable(sut, "Factory.surface fill")
    }

    @Test @MainActor func testFactoryTextProducesHostableForeground() {
        let style = ShapeStyleSystem.Factory.text(for: .iOS)
        let sut = Text("Sample").foregroundStyle(style)
        expectHostable(sut, "Factory.text foreground")
    }

    @Test @MainActor func testFactoryBorderProducesHostableStroke() {
        let style = ShapeStyleSystem.Factory.border(for: .macOS)
        let sut = Rectangle().stroke(style, lineWidth: 1).frame(width: 10, height: 10)
        expectHostable(sut, "Factory.border stroke")
    }

    @Test @MainActor func testFactoryGradientProducesHostableFill() {
        let style = ShapeStyleSystem.Factory.gradient(for: .iOS, variant: .primary)
        let sut = Rectangle().fill(style).frame(width: 10, height: 10)
        expectHostable(sut, "Factory.gradient fill")
    }

    @Test @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @MainActor func testFactoryMaterialProducesHostableFill() {
        let style = ShapeStyleSystem.Factory.material(for: .iOS, variant: .regular)
        let sut = Rectangle().fill(style).frame(width: 10, height: 10)
        expectHostable(sut, "Factory.material fill")
    }

    @Test @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @MainActor func testFactoryHierarchicalProducesHostableForeground() {
        let style = ShapeStyleSystem.Factory.hierarchical(for: .iOS, variant: .primary)
        let sut = Text("Sample").foregroundStyle(style)
        expectHostable(sut, "Factory.hierarchical foreground")
    }

    // MARK: - Supporting Types

    @Test func testBackgroundVariantEnum() {
        let cases = BackgroundVariant.allCases
        #expect(cases.contains(.standard))
        #expect(cases.contains(.grouped))
        #expect(cases.contains(.elevated))
        #expect(cases.contains(.transparent))
    }

    @Test func testSurfaceVariantEnum() {
        let cases = SurfaceVariant.allCases
        #expect(cases.contains(.standard))
        #expect(cases.contains(.elevated))
        #expect(cases.contains(.card))
        #expect(cases.contains(.modal))
    }

    @Test func testTextVariantEnum() {
        let cases = TextVariant.allCases
        #expect(cases.contains(.primary))
        #expect(cases.contains(.secondary))
        #expect(cases.contains(.tertiary))
        #expect(cases.contains(.quaternary))
    }

    @Test func testBorderVariantEnum() {
        let cases = BorderVariant.allCases
        #expect(cases.contains(.standard))
        #expect(cases.contains(.subtle))
        #expect(cases.contains(.prominent))
        #expect(cases.contains(.none))
    }

    @Test func testGradientVariantEnum() {
        let cases = GradientVariant.allCases
        #expect(cases.contains(.primary))
        #expect(cases.contains(.secondary))
        #expect(cases.contains(.background))
        #expect(cases.contains(.success))
        #expect(cases.contains(.warning))
        #expect(cases.contains(.error))
        #expect(cases.contains(.focus))
    }

    @Test @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func testMaterialVariantEnum() {
        let cases = MaterialVariant.allCases
        #expect(cases.contains(.regular))
        #expect(cases.contains(.thick))
        #expect(cases.contains(.thin))
        #expect(cases.contains(.ultraThin))
        #expect(cases.contains(.ultraThick))
    }

    @Test @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    func testHierarchicalVariantEnum() {
        let cases = HierarchicalVariant.allCases
        #expect(cases.contains(.primary))
        #expect(cases.contains(.secondary))
        #expect(cases.contains(.tertiary))
        #expect(cases.contains(.quaternary))
    }

    // MARK: - AnyShapeStyle

    @Test @MainActor func testAnyShapeStyleFromColorIsHostable() {
        let style = AnyShapeStyle(Color.blue)
        let sut = Rectangle().fill(style).frame(width: 10, height: 10)
        expectHostable(sut, "AnyShapeStyle(Color)")
    }

    @Test @MainActor func testAnyShapeStyleFromGradientIsHostable() {
        let gradient = LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
        let style = AnyShapeStyle(gradient)
        let sut = Rectangle().fill(style).frame(width: 10, height: 10)
        expectHostable(sut, "AnyShapeStyle(LinearGradient)")
    }

    @Test @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @MainActor func testAnyShapeStyleFromMaterialIsHostable() {
        let style = AnyShapeStyle(Material.regularMaterial)
        let sut = Rectangle().fill(style).frame(width: 10, height: 10)
        expectHostable(sut, "AnyShapeStyle(Material)")
    }

    // MARK: - View modifiers

    @Test @MainActor func testPlatformBackgroundModifier() {
        let sut = Text("Test").platformBackground(for: .iOS)
        expectHostable(sut, "platformBackground")
    }

    @Test @MainActor func testPlatformSurfaceModifier() {
        let sut = Text("Test").platformSurface(for: .macOS)
        expectHostable(sut, "platformSurface")
    }

    @Test @MainActor func testPlatformShapeTextModifier() {
        let sut = Text("Test").platformShapeText(for: .iOS)
        expectHostable(sut, "platformShapeText")
    }

    @Test @MainActor func testPlatformBorderModifier() {
        let sut = Text("Test").platformBorder(for: .macOS, width: 2)
        expectHostable(sut, "platformBorder")
    }

    @Test @MainActor func testPlatformGradientModifier() {
        let sut = Text("Test").platformGradient(for: .iOS, variant: .primary)
        expectHostable(sut, "platformGradient")
    }

    @Test @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @MainActor func testPlatformMaterialModifier() {
        let sut = Text("Test").platformMaterial(for: .iOS, variant: .regular)
        expectHostable(sut, "platformMaterial")
    }

    @Test @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @MainActor func testPlatformHierarchicalModifier() {
        let sut = Text("Test").platformHierarchical(for: .iOS, variant: .primary)
        expectHostable(sut, "platformHierarchical")
    }

    @Test @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @MainActor func testMaterialBackgroundModifier() {
        let sut = Text("Test").materialBackground(.regularMaterial, for: .iOS)
        expectHostable(sut, "materialBackground")
    }

    @Test @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @MainActor func testHierarchicalMaterialBackgroundModifier() {
        let sut = Text("Test").hierarchicalMaterialBackground(1, for: .iOS)
        expectHostable(sut, "hierarchicalMaterialBackground")
    }

    @Test @MainActor func testGradientBackgroundModifier() {
        let gradient = LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
        let sut = Text("Test").gradientBackground(gradient, for: .iOS)
        expectHostable(sut, "gradientBackground")
    }

    @Test @MainActor func testRadialGradientBackgroundModifier() {
        let gradient = RadialGradient(colors: [.blue, .purple], center: .center, startRadius: 0, endRadius: 100)
        let sut = Text("Test").radialGradientBackground(gradient, for: .iOS)
        expectHostable(sut, "radialGradientBackground")
    }

    @Test @MainActor func testAccessibilityAwareBackgroundModifier() {
        let sut = Text("Test").accessibilityAwareBackground(
            normal: PlatformAnyShapeStyle(AnyShapeStyle(Color.blue)),
            highContrast: PlatformAnyShapeStyle(AnyShapeStyle(Color.red))
        )
        expectHostable(sut, "accessibilityAwareBackground")
    }

    @Test @MainActor func testAccessibilityAwareForegroundModifier() {
        let sut = Text("Test").accessibilityAwareForeground(
            normal: PlatformAnyShapeStyle(AnyShapeStyle(Color.blue)),
            reducedMotion: PlatformAnyShapeStyle(AnyShapeStyle(Color.gray))
        )
        expectHostable(sut, "accessibilityAwareForeground")
    }

    @Test @MainActor func testShapeStyleSystemIntegration() {
        let sut = platformVStackContainer {
            Text("Title").font(.title)
            Text("Subtitle").font(.subheadline)
        }
        .platformBackground(for: .iOS, variant: .standard)
        .platformShapeText(for: .iOS, variant: .primary)
        .platformBorder(for: .iOS, variant: .standard, width: 1)
        expectHostable(sut, "integration styled stack")
    }

    @Test @MainActor func testAppleHIGComplianceIntegration() {
        let sut = Button("Test Button") { }
            .platformBackground(for: .iOS)
            .platformShapeText(for: .iOS)
        expectHostable(sut, "HIG button styling")
    }
}
