import Testing
@testable import SixLayerFramework

@Suite("AppNavigationPaneDescriptor builders (#331)")
struct AppNavigationPaneDescriptorTests {

    private enum PaneID: String, Hashable, Sendable {
        case garage
        case trips
        case settings
        case about
    }

    @Test
    func groupedBySection_preservesStableSectionAndPaneOrder() throws {
        let descriptors: [AppNavigationPaneDescriptor<PaneID>] = [
            .init(id: .garage, titleKey: "nav.garage", systemImage: "car", section: "Main"),
            .init(id: .trips, titleKey: "nav.trips", systemImage: "map", section: "Main"),
            .init(id: .settings, titleKey: "nav.settings", systemImage: "gearshape", section: nil),
            .init(id: .about, titleKey: "nav.about", systemImage: "info.circle", section: "Other")
        ]

        let grouped = try AppNavigationPaneSectionBuilder.groupedBySection(descriptors)

        #expect(grouped.count == 3)
        #expect(grouped[0].section == "Main")
        #expect(grouped[0].descriptors.map(\.id) == [.garage, .trips])
        #expect(grouped[1].section == nil)
        #expect(grouped[1].descriptors.map(\.id) == [.settings])
        #expect(grouped[2].section == "Other")
        #expect(grouped[2].descriptors.map(\.id) == [.about])
    }

    @Test
    func groupedBySection_duplicateIDs_throwInvariantError() {
        let descriptors: [AppNavigationPaneDescriptor<PaneID>] = [
            .init(id: .garage, titleKey: "nav.garage", systemImage: "car", section: "Main"),
            .init(id: .garage, titleKey: "nav.garageDup", systemImage: "car.fill", section: "Other")
        ]

        #expect(throws: AppNavigationPaneSectionBuilderError.duplicatePaneID("garage")) {
            _ = try AppNavigationPaneSectionBuilder.groupedBySection(descriptors)
        }
    }

    @Test
    func rowPresentation_stepsDownWithRenderingProfile() {
        #expect(
            AppNavigationSidebarRowPresentation.forProfile(.textSidebar) == .labeled
        )
        #expect(
            AppNavigationSidebarRowPresentation.forProfile(.compactList) == .compactLabeled
        )
        #expect(
            AppNavigationSidebarRowPresentation.forProfile(.iconRail) == .iconOnly
        )
    }

    @Test
    func iconOnlyRow_retainsAccessibilityLabelFromTitleKey() {
        let pane = AppNavigationPaneDescriptor(
            id: PaneID.garage,
            titleKey: "Garage",
            systemImage: "car"
        )
        let surface = AppNavigationSidebarRowAccessibility.iconOnlyLabel(for: pane)
        #expect(surface == "Garage")
    }
}
