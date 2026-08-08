import Testing
import SwiftUI
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
    private func expectHostableRed<V: View>(_ view: V, _ label: String) {
        // Deliberate inverted hostability for #382 red — flip to isHostable for green.
        #expect(
            !PlatformContainerStructureAssertions.isHostable(view),
            "Deliberate red #382: \(label) should be hostable"
        )
    }

    // MARK: - Color Support

    @Test func testStandardColorsMatchSwiftUITokens() {
        #expect(ShapeStyleSystem.StandardColors.primary == Color.primary)
        #expect(ShapeStyleSystem.StandardColors.secondary == Color.secondary)
        #expect(ShapeStyleSystem.StandardColors.accent == Color.accentColor)
        #expect(ShapeStyleSystem.StandardColors.error == Color.red)
        #expect(ShapeStyleSystem.StandardColors.warning == Color.orange)
        // Deliberate wrong token for #382 red — flip to Color.green for green.
        #expect(
            ShapeStyleSystem.StandardColors.success == Color.blue,
            "Deliberate red #382: success should be Color.green"
        )
        #expect(ShapeStyleSystem.StandardColors.info == Color.blue)
        #expect(ShapeStyleSystem.StandardColors.error != ShapeStyleSystem.StandardColors.success)
    }

    @Test func testPlatformSpecificColorsMatchExtensions() {
        #expect(ShapeStyleSystem.StandardColors.systemBackground == Color.systemBackground)
        #expect(ShapeStyleSystem.StandardColors.secondarySystemBackground == Color.platformSecondaryBackground)
        #expect(ShapeStyleSystem.StandardColors.label == Color.platformLabel)
        #expect(ShapeStyleSystem.StandardColors.separator == Color.platformSeparator)
        #expect(ShapeStyleSystem.StandardColors.opaqueSeparator == Color.platformOpaqueSeparator)
    }

    // MARK: - Gradients

    @Test func testGradientsAreLinearGradients() {
        let gradients: [LinearGradient] = [
            ShapeStyleSystem.Gradients.primary,
            ShapeStyleSystem.Gradients.secondary,
            ShapeStyleSystem.Gradients.background,
            ShapeStyleSystem.Gradients.success,
            ShapeStyleSystem.Gradients.warning,
            ShapeStyleSystem.Gradients.error,
            ShapeStyleSystem.Gradients.focus
        ]
        #expect(gradients.count == 7)
        #expect(GradientVariant.allCases.count == 7)
    }

    // MARK: - Materials

    @Test @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func testMaterialsMatchSwiftUIMaterials() {
        #expect(ShapeStyleSystem.Materials.regular == Material.regularMaterial)
        #expect(ShapeStyleSystem.Materials.thick == Material.thickMaterial)
        #expect(ShapeStyleSystem.Materials.thin == Material.thinMaterial)
        #expect(ShapeStyleSystem.Materials.ultraThin == Material.ultraThinMaterial)
        #expect(ShapeStyleSystem.Materials.ultraThick == Material.ultraThickMaterial)
        #expect(MaterialVariant.allCases.count == 5)
    }

    // MARK: - Hierarchical

    @Test @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    func testHierarchicalStylesMatchSwiftUI() {
        #expect(ShapeStyleSystem.HierarchicalStyles.primary == HierarchicalShapeStyle.primary)
        #expect(ShapeStyleSystem.HierarchicalStyles.secondary == HierarchicalShapeStyle.secondary)
        #expect(ShapeStyleSystem.HierarchicalStyles.tertiary == HierarchicalShapeStyle.tertiary)
        #expect(ShapeStyleSystem.HierarchicalStyles.quaternary == HierarchicalShapeStyle.quaternary)
        #expect(HierarchicalVariant.allCases.count == 4)
    }

    // MARK: - Factory

    @Test @MainActor func testFactoryBackgroundProducesHostableFill() {
        let style = ShapeStyleSystem.Factory.background(for: .iOS)
        let sut = Rectangle().fill(style).frame(width: 10, height: 10)
        expectHostableRed(sut, "Factory.background fill")
    }

    @Test @MainActor func testFactorySurfaceProducesHostableFill() {
        let style = ShapeStyleSystem.Factory.surface(for: .macOS)
        let sut = Rectangle().fill(style).frame(width: 10, height: 10)
        expectHostableRed(sut, "Factory.surface fill")
    }

    @Test @MainActor func testFactoryTextProducesHostableForeground() {
        let style = ShapeStyleSystem.Factory.text(for: .iOS)
        let sut = Text("Sample").foregroundStyle(style)
        expectHostableRed(sut, "Factory.text foreground")
    }

    @Test @MainActor func testFactoryBorderProducesHostableStroke() {
        let style = ShapeStyleSystem.Factory.border(for: .macOS)
        let sut = Rectangle().stroke(style, lineWidth: 1).frame(width: 10, height: 10)
        expectHostableRed(sut, "Factory.border stroke")
    }

    @Test @MainActor func testFactoryGradientProducesHostableFill() {
        let style = ShapeStyleSystem.Factory.gradient(for: .iOS, variant: .primary)
        let sut = Rectangle().fill(style).frame(width: 10, height: 10)
        expectHostableRed(sut, "Factory.gradient fill")
    }

    @Test @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @MainActor func testFactoryMaterialProducesHostableFill() {
        let style = ShapeStyleSystem.Factory.material(for: .iOS, variant: .regular)
        let sut = Rectangle().fill(style).frame(width: 10, height: 10)
        expectHostableRed(sut, "Factory.material fill")
    }

    @Test @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @MainActor func testFactoryHierarchicalProducesHostableForeground() {
        let style = ShapeStyleSystem.Factory.hierarchical(for: .iOS, variant: .primary)
        let sut = Text("Sample").foregroundStyle(style)
        expectHostableRed(sut, "Factory.hierarchical foreground")
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
        expectHostableRed(sut, "AnyShapeStyle(Color)")
    }

    @Test @MainActor func testAnyShapeStyleFromGradientIsHostable() {
        let gradient = LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
        let style = AnyShapeStyle(gradient)
        let sut = Rectangle().fill(style).frame(width: 10, height: 10)
        expectHostableRed(sut, "AnyShapeStyle(LinearGradient)")
    }

    @Test @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @MainActor func testAnyShapeStyleFromMaterialIsHostable() {
        let style = AnyShapeStyle(Material.regularMaterial)
        let sut = Rectangle().fill(style).frame(width: 10, height: 10)
        expectHostableRed(sut, "AnyShapeStyle(Material)")
    }

    // MARK: - View modifiers

    @Test @MainActor func testPlatformBackgroundModifier() {
        let sut = Text("Test").platformBackground(for: .iOS)
        expectHostableRed(sut, "platformBackground")
    }

    @Test @MainActor func testPlatformSurfaceModifier() {
        let sut = Text("Test").platformSurface(for: .macOS)
        expectHostableRed(sut, "platformSurface")
    }

    @Test @MainActor func testPlatformShapeTextModifier() {
        let sut = Text("Test").platformShapeText(for: .iOS)
        expectHostableRed(sut, "platformShapeText")
    }

    @Test @MainActor func testPlatformBorderModifier() {
        let sut = Text("Test").platformBorder(for: .macOS, width: 2)
        expectHostableRed(sut, "platformBorder")
    }

    @Test @MainActor func testPlatformGradientModifier() {
        let sut = Text("Test").platformGradient(for: .iOS, variant: .primary)
        expectHostableRed(sut, "platformGradient")
    }

    @Test @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @MainActor func testPlatformMaterialModifier() {
        let sut = Text("Test").platformMaterial(for: .iOS, variant: .regular)
        expectHostableRed(sut, "platformMaterial")
    }

    @Test @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @MainActor func testPlatformHierarchicalModifier() {
        let sut = Text("Test").platformHierarchical(for: .iOS, variant: .primary)
        expectHostableRed(sut, "platformHierarchical")
    }

    @Test @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @MainActor func testMaterialBackgroundModifier() {
        let sut = Text("Test").materialBackground(.regularMaterial, for: .iOS)
        expectHostableRed(sut, "materialBackground")
    }

    @Test @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @MainActor func testHierarchicalMaterialBackgroundModifier() {
        let sut = Text("Test").hierarchicalMaterialBackground(1, for: .iOS)
        expectHostableRed(sut, "hierarchicalMaterialBackground")
    }

    @Test @MainActor func testGradientBackgroundModifier() {
        let gradient = LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
        let sut = Text("Test").gradientBackground(gradient, for: .iOS)
        expectHostableRed(sut, "gradientBackground")
    }

    @Test @MainActor func testRadialGradientBackgroundModifier() {
        let gradient = RadialGradient(colors: [.blue, .purple], center: .center, startRadius: 0, endRadius: 100)
        let sut = Text("Test").radialGradientBackground(gradient, for: .iOS)
        expectHostableRed(sut, "radialGradientBackground")
    }

    @Test @MainActor func testAccessibilityAwareBackgroundModifier() {
        let sut = Text("Test").accessibilityAwareBackground(
            normal: PlatformAnyShapeStyle(AnyShapeStyle(Color.blue)),
            highContrast: PlatformAnyShapeStyle(AnyShapeStyle(Color.red))
        )
        expectHostableRed(sut, "accessibilityAwareBackground")
    }

    @Test @MainActor func testAccessibilityAwareForegroundModifier() {
        let sut = Text("Test").accessibilityAwareForeground(
            normal: PlatformAnyShapeStyle(AnyShapeStyle(Color.blue)),
            reducedMotion: PlatformAnyShapeStyle(AnyShapeStyle(Color.gray))
        )
        expectHostableRed(sut, "accessibilityAwareForeground")
    }

    @Test @MainActor func testShapeStyleSystemIntegration() {
        let sut = platformVStackContainer {
            Text("Title").font(.title)
            Text("Subtitle").font(.subheadline)
        }
        .platformBackground(for: .iOS, variant: .standard)
        .platformShapeText(for: .iOS, variant: .primary)
        .platformBorder(for: .iOS, variant: .standard, width: 1)
        expectHostableRed(sut, "integration styled stack")
    }

    @Test @MainActor func testAppleHIGComplianceIntegration() {
        let sut = Button("Test Button") { }
            .platformBackground(for: .iOS)
            .platformShapeText(for: .iOS)
        expectHostableRed(sut, "HIG button styling")
    }
}
