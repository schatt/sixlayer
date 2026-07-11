import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite("ManagedAppNavigationPaneList (#331)")
struct ManagedAppNavigationPaneListTests {

    private enum PaneID: String, Hashable, Sendable {
        case garage
        case trips
        case settings
    }

    private final class TopHolder: @unchecked Sendable {
        var state: PlatformAppNavigationTopLevelState<PaneID>
        init(_ state: PlatformAppNavigationTopLevelState<PaneID>) { self.state = state }
        var binding: Binding<PlatformAppNavigationTopLevelState<PaneID>> {
            Binding(get: { self.state }, set: { self.state = $0 })
        }
    }

    @Test @MainActor
    func init_throwsOnDuplicatePaneIDs() {
        let descriptors: [AppNavigationPaneDescriptor<PaneID>] = [
            .init(id: .garage, titleKey: "Garage", systemImage: "car", section: "Main"),
            .init(id: .garage, titleKey: "Garage Dup", systemImage: "car.fill", section: "Other")
        ]
        let holder = TopHolder(
            PlatformAppNavigationTopLevelState(orderedPaneIDs: [.garage, .trips], deviceType: .pad)
        )

        #expect(throws: AppNavigationPaneSectionBuilderError.duplicatePaneID("garage")) {
            _ = try ManagedAppNavigationPaneList(descriptors: descriptors, state: holder.binding)
        }
    }

    @Test @MainActor
    func testDescriptorRowCount_matchesFlattenedDescriptors() throws {
        let descriptors: [AppNavigationPaneDescriptor<PaneID>] = [
            .init(id: .garage, titleKey: "Garage", systemImage: "car", section: "Main"),
            .init(id: .trips, titleKey: "Trips", systemImage: "map", section: "Main"),
            .init(id: .settings, titleKey: "Settings", systemImage: "gearshape", section: nil)
        ]
        let holder = TopHolder(
            PlatformAppNavigationTopLevelState(
                orderedPaneIDs: [.garage, .trips, .settings],
                deviceType: .pad
            )
        )
        let list = try ManagedAppNavigationPaneList(descriptors: descriptors, state: holder.binding)

        #expect(list.testDescriptorRowCount == 3)
    }

    @Test @MainActor
    func defaultSelectionBinding_updatesTopLevelState() throws {
        let descriptors: [AppNavigationPaneDescriptor<PaneID>] = [
            .init(id: .garage, titleKey: "Garage", systemImage: "car"),
            .init(id: .trips, titleKey: "Trips", systemImage: "map")
        ]
        let holder = TopHolder(
            PlatformAppNavigationTopLevelState(orderedPaneIDs: [.garage, .trips], deviceType: .pad)
        )
        let list = try ManagedAppNavigationPaneList(descriptors: descriptors, state: holder.binding)

        list.testSelectionBinding.wrappedValue = .trips

        #expect(holder.state.selectedPane == .trips)
    }

    @Test @MainActor
    func testRowPresentation_followsEnvironmentProfile() throws {
        let descriptors: [AppNavigationPaneDescriptor<PaneID>] = [
            .init(id: .garage, titleKey: "Garage", systemImage: "car")
        ]
        let holder = TopHolder(
            PlatformAppNavigationTopLevelState(orderedPaneIDs: [.garage], deviceType: .pad)
        )
        let list = try ManagedAppNavigationPaneList(descriptors: descriptors, state: holder.binding)

        // Default environment is textSidebar → labeled.
        #expect(list.testRowPresentation() == .labeled)
    }
}
