//
//  ItemCollectionPresentationStrategyResolver.swift
//  SixLayerFramework
//
//  Shared layout strategy for generic and custom item collections (#272).
//

import Foundation

/// Layout strategies Layer 1 selects for item collections.
internal enum ItemCollectionPresentationStrategy: Equatable {
    case expandableCards
    case coverFlow
    case grid
    case list
    case masonry
    case adaptive
}

/// Resolves `PresentationHints` + environment into a presentation strategy for item collections.
/// Used by both `GenericItemCollectionView` and `CustomItemCollectionView` so custom rows honor hints.
internal enum ItemCollectionPresentationStrategyResolver {
    internal static func resolve(
        hints: PresentationHints,
        itemCount: Int,
        platform: SixLayerPlatform,
        deviceType: DeviceType
    ) -> ItemCollectionPresentationStrategy {
        let itemTypeString = hints.customPreferences["itemType"] ?? "generic"
        let interactionStyleString = hints.customPreferences["interactionStyle"] ?? "static"
        let _ = hints.customPreferences["layoutPreference"] ?? "automatic"

        let itemType = ItemType.from(string: itemTypeString)
        let interactionStyle = InteractionStyle(rawValue: interactionStyleString) ?? .static

        if itemType == .featureCards && interactionStyle == .expandable {
            switch platform {
            case .visionOS:
                return .coverFlow
            case .macOS:
                return .expandableCards
            case .iOS:
                return deviceType == .pad ? .expandableCards : .adaptive
            case .watchOS, .tvOS:
                return .list
            }
        }

        if hints.dataType == .media {
            let preference = platform.defaultMediaPresentationPreference(deviceType: deviceType)
            return presentationStrategyFromPreference(preference)
        }

        if hints.dataType == .navigation {
            let preference = platform.defaultNavigationPresentationPreference()
            return presentationStrategyFromPreference(preference)
        }

        switch hints.presentationPreference {
        case .cards:
            return .expandableCards
        case .list:
            return .list
        case .grid:
            return .grid
        case .masonry:
            return .masonry
        case .coverFlow:
            return .coverFlow
        case .countBased(let lowCount, let highCount, let threshold):
            return itemCount <= threshold
                ? determineStrategyForPreference(
                    lowCount,
                    hints: hints,
                    itemCount: itemCount,
                    platform: platform,
                    deviceType: deviceType
                )
                : determineStrategyForPreference(
                    highCount,
                    hints: hints,
                    itemCount: itemCount,
                    platform: platform,
                    deviceType: deviceType
                )
        case .automatic:
            if hints.dataType == .generic || hints.dataType == .collection {
                if itemCount > 200 {
                    return .list
                }
                return determineCountAwareStrategy(
                    count: itemCount,
                    dataType: hints.dataType,
                    platform: platform,
                    deviceType: deviceType
                )
            }
            return .adaptive
        default:
            return .adaptive
        }
    }

    private static func determineCountAwareStrategy(
        count: Int,
        dataType: DataTypeHint,
        platform: SixLayerPlatform,
        deviceType: DeviceType
    ) -> ItemCollectionPresentationStrategy {
        let threshold = platform.countThreshold(dataType: dataType, deviceType: deviceType)

        if count <= threshold {
            switch (platform, deviceType) {
            case (.macOS, _), (.iOS, .pad):
                return .grid
            case (.iOS, .phone):
                return count <= 4 ? .expandableCards : .grid
            default:
                return .grid
            }
        } else {
            return .list
        }
    }

    private static func presentationStrategyFromPreference(_ preference: PresentationPreference)
        -> ItemCollectionPresentationStrategy
    {
        switch preference {
        case .cards, .card:
            return .expandableCards
        case .list:
            return .list
        case .grid:
            return .grid
        case .masonry:
            return .masonry
        case .coverFlow:
            return .coverFlow
        case .automatic:
            return .adaptive
        default:
            return .adaptive
        }
    }

    private static func determineStrategyForPreference(
        _ preference: PresentationPreference,
        hints: PresentationHints,
        itemCount: Int,
        platform: SixLayerPlatform,
        deviceType: DeviceType
    ) -> ItemCollectionPresentationStrategy {
        switch preference {
        case .cards, .card:
            return .expandableCards
        case .list:
            return .list
        case .grid:
            return .grid
        case .masonry:
            return .masonry
        case .coverFlow:
            return .coverFlow
        case .automatic:
            return determineCountAwareStrategy(
                count: itemCount,
                dataType: hints.dataType,
                platform: platform,
                deviceType: deviceType
            )
        case .countBased:
            return .adaptive
        default:
            return .adaptive
        }
    }
}
