//
//  GenericDataItem.swift
//  SixLayerFramework
//
//  Minimal GenericDataItem for internal framework use
//  This is a simplified version used only for fallback data conversion
//  For examples and demonstrations, see Framework/Examples/GenericTypes.swift
//

import Foundation

/// Minimal generic data item for internal framework fallback use
/// This is used internally by the framework for data conversion
/// For examples and demonstrations, see Framework/Examples/GenericTypes.swift
///
/// `id` defaults to `title`. Duplicate titles collide in `ForEach` / `Hashable` (#475).
public struct GenericDataItem: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let data: [String: Any]
    
    public init(title: String, subtitle: String? = nil, data: [String: Any] = [:], id: String? = nil) {
        self.id = id ?? title
        self.title = title
        self.subtitle = subtitle
        self.data = data
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: GenericDataItem, rhs: GenericDataItem) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Minimal generic numeric data for internal framework use
///
/// `id` defaults to `label`. Duplicate labels collide in `ForEach` (#475).
public struct GenericNumericData: Identifiable, Hashable {
    public let id: String
    public let value: Double
    public let label: String
    public let unit: String?
    
    public init(value: Double, label: String, unit: String? = nil, id: String? = nil) {
        self.id = id ?? label
        self.value = value
        self.label = label
        self.unit = unit
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: GenericNumericData, rhs: GenericNumericData) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Minimal generic media item for internal framework use
///
/// `id` defaults to `url` or `title`. Duplicate keys collide in `ForEach` (#475).
public struct GenericMediaItem: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let url: String?
    public let thumbnail: String?
    
    public init(title: String, url: String? = nil, thumbnail: String? = nil, id: String? = nil) {
        self.id = id ?? url ?? title
        self.title = title
        self.url = url
        self.thumbnail = thumbnail
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: GenericMediaItem, rhs: GenericMediaItem) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Minimal generic hierarchical item for internal framework use
///
/// `id` defaults to `level:title`. Duplicate pairs collide in `ForEach` (#475).
public struct GenericHierarchicalItem: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let level: Int
    public let children: [GenericHierarchicalItem]
    
    public init(title: String, level: Int = 0, children: [GenericHierarchicalItem] = [], id: String? = nil) {
        self.id = id ?? "\(level):\(title)"
        self.title = title
        self.level = level
        self.children = children
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: GenericHierarchicalItem, rhs: GenericHierarchicalItem) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Minimal generic temporal item for internal framework use
///
/// `id` defaults to `title` plus `date`. Duplicate pairs collide in `ForEach` (#475).
public struct GenericTemporalItem: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let date: Date
    public let duration: TimeInterval?
    
    public init(title: String, date: Date, duration: TimeInterval? = nil, id: String? = nil) {
        self.id = id ?? "\(title)|\(date.timeIntervalSinceReferenceDate)"
        self.title = title
        self.date = date
        self.duration = duration
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: GenericTemporalItem, rhs: GenericTemporalItem) -> Bool {
        return lhs.id == rhs.id
    }
}
