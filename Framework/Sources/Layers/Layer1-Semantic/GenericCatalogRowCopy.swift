import Foundation

/// Default row copy for generic catalog L1 views (#479).
enum GenericCatalogRowCopy {
    struct Copy: Equatable {
        let title: String
        let detail: String?
    }

    /// Stub: empty so #479 tests fail until green.
    static func media(_ item: GenericMediaItem) -> Copy {
        _ = item
        return Copy(title: "", detail: nil)
    }

    static func numeric(_ item: GenericNumericData) -> Copy {
        _ = item
        return Copy(title: "", detail: nil)
    }

    static func hierarchical(_ item: GenericHierarchicalItem) -> Copy {
        _ = item
        return Copy(title: "", detail: nil)
    }

    static func temporal(_ item: GenericTemporalItem) -> Copy {
        _ = item
        return Copy(title: "", detail: nil)
    }
}
