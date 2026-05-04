//
//  ExtensionsTests.swift
//  LeavesOfBlocksTests
//
//  Tests for small standalone extensions on Foundation/SwiftUI types.
//  Each one is small enough that one suite per type keeps things tidy.
//

import Foundation
import SwiftUI
import Testing
@testable import LeavesOfBlocks

// MARK: - TimeInterval Formatting

@Suite("TimeInterval.formattedAsClock")
struct TimeIntervalFormattedAsClockTests {
    @Test("Zero formats as 0:00")
    func zero() {
        #expect((0 as TimeInterval).formattedAsClock == "0:00")
    }

    @Test("Sub-minute durations zero-pad seconds")
    func subMinute() {
        #expect((5 as TimeInterval).formattedAsClock == "0:05")
        #expect((30 as TimeInterval).formattedAsClock == "0:30")
        #expect((59 as TimeInterval).formattedAsClock == "0:59")
    }

    @Test("Minute boundary rolls over correctly")
    func minuteBoundary() {
        #expect((60 as TimeInterval).formattedAsClock == "1:00")
        #expect((61 as TimeInterval).formattedAsClock == "1:01")
        #expect((125 as TimeInterval).formattedAsClock == "2:05")
    }

    @Test("Hours render as raw minutes (no h:mm:ss promotion)")
    func multipleHours() {
        // Documents current behavior — there's no h:mm:ss promotion;
        // 1 hour shows as 60:00. If you want hh:mm rollover for long
        // games, that'd be a code change with new tests.
        #expect((3600 as TimeInterval).formattedAsClock == "60:00")
        #expect((3725 as TimeInterval).formattedAsClock == "62:05")
    }

    @Test("Sub-second precision is truncated, not rounded")
    func subSecondTruncation() {
        #expect((0.999 as TimeInterval).formattedAsClock == "0:00")
        #expect((59.999 as TimeInterval).formattedAsClock == "0:59")
    }

    @Test("Output always matches the M:SS pattern for non-negative inputs", arguments: [
        0.0, 1.0, 59.0, 60.0, 125.0, 3599.0, 3600.0, 7325.0
    ])
    func formatPattern(input: TimeInterval) {
        let result = input.formattedAsClock
        // Pattern: one or more digits, colon, exactly two digits.
        let pattern = #/^\d+:\d{2}$/#
        #expect(result.contains(pattern), "value \(input) produced malformed: \(result)")
    }
}

@Suite("TimeInterval.formattedAsHoursAndMinutes")
struct TimeIntervalFormattedAsHoursMinutesTests {
    @Test("Zero produces a non-empty minutes-only string")
    func zero() {
        let result = (0 as TimeInterval).formattedAsHoursAndMinutes
        #expect(!result.isEmpty)
    }

    @Test("Sub-hour durations use the minutes-only format")
    func subHour() {
        let result = (1800 as TimeInterval).formattedAsHoursAndMinutes  // 30 min
        // Localized — assert it carries the digit "30" rather than the
        // exact wording, which depends on the string catalog.
        #expect(result.contains("30"))
    }

    @Test("Multi-hour durations include both hours and minutes")
    func multiHour() {
        let result = (5400 as TimeInterval).formattedAsHoursAndMinutes  // 1h 30m
        #expect(result.contains("1"))
        #expect(result.contains("30"))
    }

    @Test("Negative input is clamped to zero (no negative values surface)")
    func negativeClamped() {
        let result = (-100 as TimeInterval).formattedAsHoursAndMinutes
        // The implementation uses max(0, Int(self) / 60). Result should
        // be the same as 0 input (no '-' anywhere).
        #expect(!result.contains("-"))
    }
}

// MARK: - BlockColor → SwiftUI.Color

@Suite("BlockColor.color")
struct BlockColorSwiftUIColorTests {
    @Test("Every BlockColor maps to a SwiftUI Color without crashing",
          arguments: BlockColor.allCases)
    func everyCaseMaps(color: BlockColor) {
        // Catches a missing switch case (the compiler does too — but only
        // if the switch isn't @unknown default-shielded).
        _ = color.color
    }

    @Test("Distinct BlockColor cases map to distinct Color values")
    func mappingsAreDistinct() {
        // If two cases accidentally point at the same theme color (copy/
        // paste bug), users see two visually identical block types and
        // can't distinguish them. Compare via SwiftUI's Color description
        // since Color isn't directly Hashable in a stable way.
        let descriptions = BlockColor.allCases.map { String(describing: $0.color) }
        #expect(Set(descriptions).count == descriptions.count,
            "duplicate Color mapping across BlockColor cases: \(descriptions)")
    }
}
