import Testing
import CoreGraphics
@testable import SixLayerFramework

@Suite("Navigation Layout Resolver")
struct NavigationLayoutResolverTests {

    @Test
    func resolve_usesSideBySide_whenWidthBudgetFits() {
        let resolution = NavigationLayoutResolver.resolve(
            availableWidth: 1200,
            outerProfile: .iconRail,
            innerProfile: .textSidebar,
            minimumDetailWidth: 400,
            policy: .automatic
        )

        #expect(resolution.mode == .sideBySide)
        #expect(resolution.outerWidth >= NavigationSidebarProfile.iconRail.minWidth)
        #expect(resolution.innerWidth >= NavigationSidebarProfile.textSidebar.minWidth)
        #expect(resolution.detailWidth >= 400)
    }

    @Test
    func resolve_usesCompactFallback_whenWidthBudgetDoesNotFit() {
        let resolution = NavigationLayoutResolver.resolve(
            availableWidth: 500,
            outerProfile: .textSidebar,
            innerProfile: .textSidebar,
            minimumDetailWidth: 400,
            policy: .automatic
        )

        #expect(resolution.mode == .compactCollapsedOuter)
    }

    @Test
    func resolve_respectsPolicy_whenWidthBudgetDoesNotFit() {
        let resolution = NavigationLayoutResolver.resolve(
            availableWidth: 500,
            outerProfile: .textSidebar,
            innerProfile: .textSidebar,
            minimumDetailWidth: 400,
            policy: .preferOuter
        )

        #expect(resolution.mode == .compactCollapsedInner)
    }

    @Test
    func customProfile_isExtensibleWithCustomValues() {
        let profile = NavigationSidebarProfile(
            id: "custom",
            minWidth: 140,
            idealWidthRatio: 0.2,
            maxWidth: 260
        )

        #expect(profile.id == "custom")
        #expect(profile.minWidth == 140)
        #expect(profile.idealWidthRatio == 0.2)
        #expect(profile.maxWidth == 260)
    }

    @Test
    func resolveSettingsContainer_usesSideBySide_whenWideEnough() {
        let resolution = NavigationLayoutResolver.resolveSettingsContainer(availableWidth: 1300)

        #expect(resolution.mode == .sideBySide)
    }

    @Test
    func resolveSettingsContainer_usesCompactCollapsedOuter_whenConstrained() {
        let resolution = NavigationLayoutResolver.resolveSettingsContainer(availableWidth: 620)

        #expect(resolution.mode == .compactCollapsedOuter)
    }

    @Test
    func layer4CompactPresentation_mapsResolutionModes() {
        let outer = NavigationLayoutResolution(
            mode: .compactCollapsedOuter,
            outerWidth: 140,
            innerWidth: 180,
            detailWidth: 300
        )
        #expect(NavigationLayoutCompactPresentation(resolution: outer) == .overlayOuterSidebar)

        let inner = NavigationLayoutResolution(
            mode: .compactCollapsedInner,
            outerWidth: 140,
            innerWidth: 180,
            detailWidth: 300
        )
        #expect(NavigationLayoutCompactPresentation(resolution: inner) == .detailOnlyCollapsedInner)

        let side = NavigationLayoutResolution(
            mode: .sideBySide,
            outerWidth: 140,
            innerWidth: 180,
            detailWidth: 500
        )
        #expect(NavigationLayoutCompactPresentation(resolution: side) == .fullSplit)
    }

    @Test
    func resolveSettingsContainer_constrained_matchesOverlayPresentation() {
        let resolution = NavigationLayoutResolver.resolveSettingsContainer(availableWidth: 620)
        #expect(NavigationLayoutCompactPresentation(resolution: resolution) == .overlayOuterSidebar)
    }

    @Test
    func resolveAppNavigationShell_matchesSettingsContainer_forParity() {
        let widths: [CGFloat] = [0, 320, 620, 900, 1300, 2000]
        for width in widths {
            let app = NavigationLayoutResolver.resolveAppNavigationShell(availableWidth: width)
            let settings = NavigationLayoutResolver.resolveSettingsContainer(availableWidth: width)
            #expect(app == settings)
        }
    }
}
