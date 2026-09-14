import Foundation

/// Default row copy for generic catalog L1 views (#479).
enum GenericCatalogRowCopy {
    struct Copy: Equatable {
        let title: String
        let detail: String?
    }

    static func media(_ item: GenericMediaItem) -> Copy {
        Copy(title: item.title, detail: item.url)
    }

    static func numeric(_ item: GenericNumericData) -> Copy {
        let valueText = formatValue(item.value)
        let detail = item.unit.map { "\(valueText) \($0)" } ?? valueText
        return Copy(title: item.label, detail: detail)
    }

    static func hierarchical(_ item: GenericHierarchicalItem) -> Copy {
        Copy(title: item.title, detail: "Level \(item.level)")
    }

    static func temporal(_ item: GenericTemporalItem) -> Copy {
        Copy(title: item.title, detail: isoDay.string(from: item.date))
    }

    private static func formatValue(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(value)
    }

    private static let isoDay: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}
