import Testing
@testable import SixLayerFramework

/// Contract for `platformPresentDestination_L4` platform choice (#358).
@Suite("Platform present destination strategy")
struct PlatformPresentDestinationStrategyTests {

    @Test func resolve_iOS_usesNavigationDestination() {
        let strategy = PlatformPresentDestinationStrategy.resolve(platform: .iOS)
        #expect(
            strategy == .navigationDestination,
            "iOS should push via navigationDestination so PresentDestination matches stack navigation"
        )
    }

    @Test func resolve_macOS_usesSheet() {
        let strategy = PlatformPresentDestinationStrategy.resolve(platform: .macOS)
        #expect(
            strategy == .sheet,
            "macOS should present via sheet — navigationDestination is unreliable in split-view detail"
        )
    }

    @Test func resolve_tvOS_watchOS_visionOS_useSheet() {
        #expect(PlatformPresentDestinationStrategy.resolve(platform: .tvOS) == .sheet)
        #expect(PlatformPresentDestinationStrategy.resolve(platform: .watchOS) == .sheet)
        #expect(PlatformPresentDestinationStrategy.resolve(platform: .visionOS) == .sheet)
    }

    @Test func resolve_currentHost_matchesPlatformMatrix() {
        let expected = PlatformPresentDestinationStrategy.resolve(platform: SixLayerPlatform.current)
        #expect(PlatformPresentDestinationStrategy.resolve(platform: .current) == expected)
    }
}
