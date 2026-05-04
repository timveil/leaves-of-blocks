//
//  DifficultyModeTests.swift
//  LeavesOfBlocksTests
//
//  Unit tests for DifficultyMode — the small enum that gates difficulty
//  presets, displayed names, icon assets, and acorn-cost UI. Untested for
//  a long time despite being referenced from many code paths.
//

import Foundation
import Testing
import UIKit
@testable import LeavesOfBlocks

@Suite("DifficultyMode")
struct DifficultyModeTests {

    @Test("allCases is exactly easy / moderate / hard, in order")
    func allCasesShape() {
        #expect(DifficultyMode.allCases == [.easy, .moderate, .hard])
    }

    @Test("rawValues match displayed enum spelling")
    func rawValueStrings() {
        #expect(DifficultyMode.easy.rawValue == "Easy")
        #expect(DifficultyMode.moderate.rawValue == "Moderate")
        #expect(DifficultyMode.hard.rawValue == "Hard")
    }

    @Test("acornCount matches the documented 1/2/3 progression")
    func acornCounts() {
        #expect(DifficultyMode.easy.acornCount == 1)
        #expect(DifficultyMode.moderate.acornCount == 2)
        #expect(DifficultyMode.hard.acornCount == 3)
    }

    @Test("acornCount is strictly increasing with difficulty",
          arguments: zip(
            [DifficultyMode.easy, .moderate],
            [DifficultyMode.moderate, .hard]
          ))
    func acornCountMonotonic(lower: DifficultyMode, higher: DifficultyMode) {
        #expect(lower.acornCount < higher.acornCount)
    }

    @Test("Every case has a non-empty displayName, description, and iconName",
          arguments: DifficultyMode.allCases)
    func allUserFacingFieldsPopulated(mode: DifficultyMode) {
        #expect(!mode.displayName.isEmpty, "\(mode) has empty displayName")
        #expect(!mode.localizedDescription.isEmpty, "\(mode) has empty localizedDescription")
        #expect(!mode.iconName.isEmpty, "\(mode) has empty iconName")
    }

    @Test("iconName is a distinct SF Symbol per case (no copy-paste bug)")
    func iconNamesAreDistinct() {
        let icons = DifficultyMode.allCases.map { $0.iconName }
        #expect(Set(icons).count == icons.count, "duplicate iconName across cases: \(icons)")
    }

    @Test("Codable round-trip preserves the value",
          arguments: DifficultyMode.allCases)
    func codableRoundTrip(mode: DifficultyMode) throws {
        let data = try JSONEncoder().encode(mode)
        let decoded = try JSONDecoder().decode(DifficultyMode.self, from: data)
        #expect(decoded == mode)
    }

    @Test("Decoding an unknown rawValue fails (no silent fallback)")
    func unknownRawValueRejected() {
        let json = Data(#""Impossible""#.utf8)
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(DifficultyMode.self, from: json)
        }
    }
}

@Suite("UIAccessibility.prefersReducedMotion")
struct UIAccessibilityPrefersReducedMotionTests {
    @Test("Mirrors UIAccessibility.isReduceMotionEnabled at the time of read")
    @MainActor
    func mirrorsSystemSetting() {
        // Can't toggle the iOS-level setting from a test, but we can verify
        // the helper is a true alias (value parity at this instant).
        #expect(UIAccessibility.prefersReducedMotion == UIAccessibility.isReduceMotionEnabled)
    }
}
