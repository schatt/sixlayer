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

    @Test
    func layer4CompactPresentation_forConstrainedWidth_isOverlayOuterSidebar() {
        let p = NavigationLayoutResolver.layer4CompactPresentation(forAvailableWidth: 620)
        #expect(p == .overlayOuterSidebar)
    }

    @Test
    func layer4CompactPresentation_forWideWidth_isFullSplit() {
        let p = NavigationLayoutResolver.layer4CompactPresentation(forAvailableWidth: 1300)
        #expect(p == .fullSplit)
    }

    @Test
    func layer4CompactPresentation_matchesComposedResolutionMapping() {
        for w in stride(from: 0, through: 2500, by: 17) {
            let width = CGFloat(w)
            let resolution = NavigationLayoutResolver.resolveSettingsContainer(availableWidth: width)
            let expected = NavigationLayoutCompactPresentation(resolution: resolution)
            let actual = NavigationLayoutResolver.layer4CompactPresentation(forAvailableWidth: width)
            #expect(actual == expected, "width \(width)")
        }
    }

    @Test
    func layer4OverlayAccessibilityState_hidesUnderlyingContent_whenPresented() {
        let state = NavigationLayoutResolver.layer4OverlayAccessibilityState(isOverlayPresented: true)
        #expect(state.isUnderlyingContentAccessibilityHidden)
        #expect(state.focusTarget == .overlayContent)
    }

    @Test
    func layer4OverlayAccessibilityState_showsUnderlyingContent_whenDismissed() {
        let state = NavigationLayoutResolver.layer4OverlayAccessibilityState(isOverlayPresented: false)
        #expect(state.isUnderlyingContentAccessibilityHidden == false)
        #expect(state.focusTarget == .expandSidebarButton)
    }

    @Test
    func layer4OverlayAccessibilityTransition_movesFocusIntoOverlay_onPresent() {
        let focus = NavigationLayoutResolver.layer4OverlayAccessibilityTransition(
            previouslyPresented: false,
            currentlyPresented: true
        )
        #expect(focus == .overlayContent)
    }

    @Test
    func layer4OverlayAccessibilityTransition_returnsFocusToButton_onDismiss() {
        let focus = NavigationLayoutResolver.layer4OverlayAccessibilityTransition(
            previouslyPresented: true,
            currentlyPresented: false
        )
        #expect(focus == .expandSidebarButton)
    }

    @Test
    func layer4OverlayAccessibilityTransition_noFocusMove_whenStateUnchanged() {
        let noChangeClosed = NavigationLayoutResolver.layer4OverlayAccessibilityTransition(
            previouslyPresented: false,
            currentlyPresented: false
        )
        let noChangeOpen = NavigationLayoutResolver.layer4OverlayAccessibilityTransition(
            previouslyPresented: true,
            currentlyPresented: true
        )
        #expect(noChangeClosed == nil)
        #expect(noChangeOpen == nil)
    }

    @Test
    func layer4CompactPresentationForTransition_preservesPreviousCompactPresentation_duringConstrainedResizeChurn() {
        let widths: [CGFloat] = [620, 700, 760, 680, 640]
        var previous = NavigationLayoutCompactPresentation.detailOnlyCollapsedInner

        for width in widths {
            previous = NavigationLayoutResolver.layer4CompactPresentationForTransition(
                availableWidth: width,
                previousPresentation: previous
            )
            #expect(previous == .detailOnlyCollapsedInner, "width \(width)")
        }
    }

    @Test
    func layer4CompactPresentationForTransition_resetsToFullSplit_whenWidthRecovers() {
        let first = NavigationLayoutResolver.layer4CompactPresentationForTransition(
            availableWidth: 620,
            previousPresentation: .detailOnlyCollapsedInner
        )
        #expect(first == .detailOnlyCollapsedInner)

        let recovered = NavigationLayoutResolver.layer4CompactPresentationForTransition(
            availableWidth: 1300,
            previousPresentation: first
        )
        #expect(recovered == .fullSplit)
    }
}
