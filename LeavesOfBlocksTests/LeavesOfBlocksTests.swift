//
//  LeavesOfBlocksTests.swift
//  LeavesOfBlocksTests
//
//  Tests for foundational extensions used across the app.
//

import Testing
import Foundation
@testable import LeavesOfBlocks

// MARK: - Int Extensions

@Suite("Int.formattedScore")
struct IntFormattedScoreTests {
    @Test("Zero is rendered with no separators")
    func zero() {
        #expect(0.formattedScore == "0")
    }

    @Test("Three-digit values are not separated")
    func threeDigits() {
        #expect(123.formattedScore == "123")
    }

    @Test("Four-digit and larger values use grouping separators")
    func grouping() {
        // The locale-driven separator may vary but the digit body should match.
        let formatted = 1_234.formattedScore
        #expect(formatted.contains("1") && formatted.contains("234"))
        #expect(formatted.count >= 5) // "1,234" or "1.234" or "1 234"
    }
}

@Suite("Int.abbreviatedScore")
struct IntAbbreviatedScoreTests {
    @Test("Values under 10K use the standard formatter")
    func underTenThousand() {
        #expect(9_999.abbreviatedScore == 9_999.formattedScore)
    }

    @Test("Round 10K boundary renders as '10K'")
    func roundTenThousand() {
        #expect(10_000.abbreviatedScore == "10K")
    }

    @Test("Non-round 10K values render with one decimal")
    func nonRoundTenThousand() {
        #expect(12_500.abbreviatedScore == "12.5K")
    }

    @Test("Round million boundary renders as '1M'")
    func roundMillion() {
        #expect(1_000_000.abbreviatedScore == "1M")
    }

    @Test("Non-round million values render with one decimal")
    func nonRoundMillion() {
        #expect(2_500_000.abbreviatedScore == "2.5M")
    }
}

@Suite("Int.isValidGridIndex")
struct IntIsValidGridIndexTests {
    @Test("Zero is a valid grid index")
    func zero() {
        #expect(0.isValidGridIndex)
    }

    @Test("Last in-range index is valid")
    func lastInRange() {
        #expect(7.isValidGridIndex)
    }

    @Test("Negative indices are invalid")
    func negative() {
        #expect(!(-1).isValidGridIndex)
    }

    @Test("Index equal to the grid size is invalid")
    func atSize() {
        #expect(!8.isValidGridIndex)
    }
}

// MARK: - String Extensions

@Suite("String.localized")
struct StringLocalizedTests {
    @Test("Returns the original string when the key has no entry")
    func unknownKeyFallsThrough() {
        let key = "this_key_does_not_exist_12345"
        #expect(key.localized == key)
    }

    @Test("localized(with:) substitutes positional arguments")
    func parameterizedFormatting() {
        let formatted = "Score %d: %d".localized(with: 1, 2)
        #expect(formatted == "Score 1: 2")
    }
}

@Suite("String.localizedGrade")
struct StringLocalizedGradeTests {
    @Test("Legacy English values map to localized labels")
    func legacyMaster() {
        // The legacy "Master" persisted in older records is mapped to grade_master.
        // The English value defined in Localizable.xcstrings is "Master".
        #expect("Master".localizedGrade == "Master")
    }

    @Test("New stable keys localize directly")
    func stableKey() {
        #expect("grade_a_plus".localizedGrade == "A+")
    }

    @Test("Unknown values fall through unchanged")
    func unknownValue() {
        // Anything not in the legacy map is treated as a key; if no key exists,
        // NSLocalizedString returns the input.
        let arbitrary = "totally_unknown_grade_zzz"
        #expect(arbitrary.localizedGrade == arbitrary)
    }
}

// MARK: - TimeInterval Extension

@Suite("TimeInterval.formattedAsClock")
struct TimeIntervalClockTests {
    @Test("Zero is rendered as 0:00")
    func zero() {
        #expect(TimeInterval(0).formattedAsClock == "0:00")
    }

    @Test("Sub-minute values render with leading zero seconds")
    func underOneMinute() {
        #expect(TimeInterval(45).formattedAsClock == "0:45")
    }

    @Test("Exact-minute values render with :00 seconds")
    func exactMinute() {
        #expect(TimeInterval(60).formattedAsClock == "1:00")
    }

    @Test("Multi-minute values render with two-digit seconds padded")
    func multiMinute() {
        #expect(TimeInterval(125).formattedAsClock == "2:05")
    }

    @Test("Fractional seconds are truncated, not rounded")
    func fractionalSeconds() {
        #expect(TimeInterval(59.9).formattedAsClock == "0:59")
    }
}

// MARK: - Bundle Extension

@Suite("Bundle helpers")
struct BundleExtensionTests {
    @Test("displayName returns a non-empty string for the test bundle")
    func displayName() {
        // Bundle.main inside an XCTest runner refers to the test host or the
        // test bundle depending on configuration. Either way the value should
        // not be empty after our extension's fallback chain.
        #expect(!Bundle.main.displayName.isEmpty)
    }

    @Test("appVersion returns a non-empty string")
    func appVersion() {
        #expect(!Bundle.main.appVersion.isEmpty)
    }

    @Test("buildNumber returns a non-empty string")
    func buildNumber() {
        #expect(!Bundle.main.buildNumber.isEmpty)
    }

    @Test("versionAndBuild combines version and build")
    func versionAndBuild() {
        let combined = Bundle.main.versionAndBuild
        #expect(combined.contains(Bundle.main.appVersion))
        #expect(combined.contains(Bundle.main.buildNumber))
    }
}
