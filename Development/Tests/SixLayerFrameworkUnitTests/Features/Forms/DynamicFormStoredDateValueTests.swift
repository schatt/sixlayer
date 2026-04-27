import Foundation
import Testing

@testable import SixLayerFramework

@Suite("DynamicFormStoredDateValue")
struct DynamicFormStoredDateValueTests {

    @Test func date_roundTripsDate() {
        let original = Date(timeIntervalSince1970: 1_700_000_000)
        let parsed = DynamicFormStoredDateValue.date(fromStoredValue: original)
        #expect(parsed == original)
    }

    @Test func date_parsesDoubleAsUnixInterval() {
        let interval = 1_700_000_000.0
        let parsed = DynamicFormStoredDateValue.date(fromStoredValue: interval)
        #expect(parsed == Date(timeIntervalSince1970: interval))
    }

    @Test func date_parsesISO8601() {
        let string = "2024-06-15T14:30:00Z"
        let parsed = DynamicFormStoredDateValue.date(fromStoredValue: string)
        #expect(parsed != nil)
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        #expect(parsed == iso.date(from: string))
    }

    @Test func date_parsesMediumDateString_enUSPOSIX() {
        let medium = DateFormatter()
        medium.locale = Locale(identifier: "en_US_POSIX")
        medium.dateStyle = .medium
        medium.timeStyle = .none
        let ref = Date(timeIntervalSince1970: 1_700_000_000)
        let string = medium.string(from: ref)
        let parsed = DynamicFormStoredDateValue.date(fromStoredValue: string)
        #expect(parsed != nil)
        if let parsed {
            let cal = Calendar(identifier: .gregorian)
            #expect(cal.isDate(parsed, inSameDayAs: ref))
        }
    }

    @Test func date_parsesMediumDateShortTimeString_enUSPOSIX() {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        let ref = Date(timeIntervalSince1970: 1_700_000_000)
        let string = fmt.string(from: ref)
        let parsed = DynamicFormStoredDateValue.date(fromStoredValue: string)
        #expect(parsed != nil)
        if let parsed, let expected = fmt.date(from: string) {
            #expect(abs(parsed.timeIntervalSince1970 - expected.timeIntervalSince1970) < 1)
        }
    }

    @Test func date_nilForNilOrEmptyString() {
        #expect(DynamicFormStoredDateValue.date(fromStoredValue: nil) == nil)
        #expect(DynamicFormStoredDateValue.date(fromStoredValue: "") == nil)
        #expect(DynamicFormStoredDateValue.date(fromStoredValue: "   ") == nil)
    }

    @Test @MainActor func formState_dateValueRoundTripsThroughFieldValues() {
        let config = DynamicFormConfiguration(id: "t", title: "T", sections: [])
        let state = DynamicFormState(configuration: config)
        let ref = Date(timeIntervalSince1970: 1_712_000_000)
        state.setValue(ref, for: "due")
        let parsed = DynamicFormStoredDateValue.date(fromStoredValue: state.fieldValues["due"])
        #expect(parsed == ref)
    }
}
