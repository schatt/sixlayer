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
    func resolveSettingsContainer_collapsesInner_whenConstrained() {
        let resolution = NavigationLayoutResolver.resolveSettingsContainer(availableWidth: 620)

        #expect(resolution.mode == .compactCollapsedInner)
    }
}
