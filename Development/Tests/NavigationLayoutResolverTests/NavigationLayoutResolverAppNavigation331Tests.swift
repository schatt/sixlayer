import Testing
import CoreGraphics
@testable import SixLayerFramework

/// App-nav sidebar rendering profile step-down from column ideal width (GitHub #331).
@Suite("Navigation Layout Resolver App Navigation #331")
struct NavigationLayoutResolverAppNavigation331Tests {

    @Test
    func activeSidebarRenderingProfile_textSidebar_whenIdealAtOrAboveTextMin() {
        let profile = NavigationLayoutResolver.activeSidebarRenderingProfile(
            columnIdealWidth: NavigationSidebarProfile.textSidebar.minWidth
        )
        #expect(profile == .textSidebar)
    }

    @Test
    func activeSidebarRenderingProfile_compactList_whenIdealBetweenCompactAndTextMin() {
        let profile = NavigationLayoutResolver.activeSidebarRenderingProfile(
            columnIdealWidth: NavigationSidebarProfile.compactList.minWidth
        )
        #expect(profile == .compactList)

        let justBelowText = NavigationLayoutResolver.activeSidebarRenderingProfile(
            columnIdealWidth: NavigationSidebarProfile.textSidebar.minWidth - 1
        )
        #expect(justBelowText == .compactList)
    }

    @Test
    func activeSidebarRenderingProfile_iconRail_whenIdealBelowCompactMin() {
        let profile = NavigationLayoutResolver.activeSidebarRenderingProfile(
            columnIdealWidth: NavigationSidebarProfile.compactList.minWidth - 1
        )
        #expect(profile == .iconRail)

        let floor = NavigationLayoutResolver.activeSidebarRenderingProfile(
            columnIdealWidth: NavigationSidebarProfile.iconRail.minWidth
        )
        #expect(floor == .iconRail)
    }

    @Test
    func activeSidebarRenderingProfile_fromAvailableWidth_stepsDownAsWindowNarrows() {
        // Wide enough for textSidebar ideal near profile max.
        let wide = NavigationLayoutResolver.activeSidebarRenderingProfile(availableWidth: 1400)
        #expect(wide == .textSidebar)

        // Mid: column ideal shrinks toward compact band.
        let mid = NavigationLayoutResolver.activeSidebarRenderingProfile(availableWidth: 700)
        // 700 - 480 detail = 220 budget; profileIdeal = 175 → ideal 175 → compactList (< 180 text min)
        #expect(mid == .compactList)

        // Narrow but still fits icon-rail floor + detail (80+480=560).
        let narrow = NavigationLayoutResolver.activeSidebarRenderingProfile(availableWidth: 580)
        // budgetIdeal = 100 → ideal 100 → iconRail
        #expect(narrow == .iconRail)
    }

    @Test
    func activeSidebarRenderingProfile_fromAvailableWidth_nilSizingFallsBackToIconRail() {
        let floor = NavigationSidebarProfile.iconRail.minWidth
            + NavigationLayoutResolver.layer4NestedSplitShellMinimumDetailWidth
        let profile = NavigationLayoutResolver.activeSidebarRenderingProfile(
            availableWidth: floor - 1
        )
        #expect(profile == .iconRail)
    }
}
