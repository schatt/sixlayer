import Testing
import CoreGraphics
@testable import SixLayerFramework

/// App-nav single-sidebar width budget and progressive column sizing (GitHub #330).
@Suite("Navigation Layout Resolver App Navigation #330")
struct NavigationLayoutResolverAppNavigation330Tests {

    @Test
    func resolveAppNavigationShell_usesSingleSidebarBudget_notNestedTwoSidebars() {
        // Nested settings budget is compactList(140)+textSidebar(180)+480 = 800.
        // Single textSidebar(180)+480 = 660. Width 700 fits app-nav, not nested settings.
        let app = NavigationLayoutResolver.resolveAppNavigationShell(availableWidth: 700)
        let settings = NavigationLayoutResolver.resolveSettingsContainer(availableWidth: 700)
        #expect(app.mode == .sideBySide)
        #expect(settings.mode == .compactCollapsedOuter)
        #expect(app.outerWidth >= NavigationSidebarProfile.textSidebar.minWidth
            || app.outerWidth >= NavigationSidebarProfile.iconRail.minWidth)
        #expect(app.detailWidth >= 0)
    }

    @Test
    func resolveAppNavigationShell_goesCompact_whenSidebarMinPlusDetailCannotFit() {
        // textSidebar 180 + detail 480 = 660
        let resolution = NavigationLayoutResolver.resolveAppNavigationShell(availableWidth: 500)
        #expect(resolution.mode != .sideBySide)
    }

    @Test
    func appNavigationSidebarColumnSizing_shrinksIdealAsWidthDecreases() {
        let wide = NavigationLayoutResolver.appNavigationSidebarColumnSizing(availableWidth: 1400)
        let mid = NavigationLayoutResolver.appNavigationSidebarColumnSizing(availableWidth: 900)
        #expect(wide != nil)
        #expect(mid != nil)
        #expect(mid!.ideal <= wide!.ideal + 0.5)
        #expect(mid!.min <= mid!.ideal + 0.5)
        #expect(mid!.ideal <= mid!.max + 0.5)
    }

    @Test
    func appNavigationSidebarColumnSizing_allowsShrinkTowardIconRailFloor() {
        let sizing = NavigationLayoutResolver.appNavigationSidebarColumnSizing(availableWidth: 800)
        #expect(sizing != nil)
        #expect(sizing!.min == NavigationSidebarProfile.iconRail.minWidth)
    }

    @Test
    func appNavigationSidebarColumnSizing_nilWhenEvenIconRailPlusDetailCannotFit() {
        let floor = NavigationSidebarProfile.iconRail.minWidth
            + NavigationLayoutResolver.layer4NestedSplitShellMinimumDetailWidth
        let sizing = NavigationLayoutResolver.appNavigationSidebarColumnSizing(
            availableWidth: floor - 1
        )
        #expect(sizing == nil)
    }

    @Test
    func layer4AppNavigationCompactPresentation_fullSplitWhenSingleSidebarBudgetFits() {
        let presentation = NavigationLayoutResolver.layer4AppNavigationCompactPresentation(
            forAvailableWidth: 700
        )
        #expect(presentation == .fullSplit)
    }

    @Test
    func layer4AppNavigationCompactPresentation_leavesFullSplitWhenBudgetFails() {
        let presentation = NavigationLayoutResolver.layer4AppNavigationCompactPresentation(
            forAvailableWidth: 500
        )
        #expect(presentation != .fullSplit)
    }
}
