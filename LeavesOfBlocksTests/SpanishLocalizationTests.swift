//
//  SpanishLocalizationTests.swift
//  LeavesOfBlocksTests
//
//  Coverage for the Spanish values a player reads at the end of a game.
//

import Foundation
import Testing

@testable import LeavesOfBlocks

// MARK: - Helpers

/// The app bundle, resolved through a type that lives in the app module.
///
/// `Bundle.main` is the app only for as long as these tests are hosted by it.
/// If the target ever ran unhosted, `.main` would be the XCTest runner, no
/// `.lproj` would be found, and assertions about localization would quietly
/// stop meaning anything. A class from the app module resolves to the bundle
/// that actually carries the compiled strings either way.
private let appBundle = Bundle(for: CoreDataManager.self)

/// The compiled strings for one language, read the way the app reads them.
///
/// A String Catalog compiles only the keys that carry a value for the
/// language, so a key with no Spanish translation is simply absent from
/// `es.lproj` and `localizedString(forKey:)` hands back the key itself. That
/// is exactly what a player sees: the raw key, or the English source through
/// the fallback chain. It is also what makes the absence assertable here.
///
/// A missing `.lproj` fails here rather than substituting a fallback bundle:
/// comparing one bundle against itself would report agreement it never
/// established.
private func bundle(for language: String) throws -> Bundle {
    let path = try #require(
        appBundle.path(forResource: language, ofType: "lproj"),
        "No \(language).lproj in \(appBundle.bundlePath)"
    )
    return try #require(Bundle(path: path), "\(language).lproj is not loadable as a bundle")
}

private func value(_ key: String, in bundle: Bundle) -> String {
    bundle.localizedString(forKey: key, value: nil, table: nil)
}

/// The strategy ladder and the challenge tiers: prose, translated.
private let translatedKeys = [
    "grade_master", "grade_expert", "grade_skilled", "grade_learning", "grade_beginner",
    "challenge_high", "challenge_medium", "challenge_low"
]

/// The efficiency ladder: glyphs, deliberately identical in both languages.
private let letterGradeKeys = [
    "grade_a_plus", "grade_a", "grade_b_plus", "grade_b", "grade_c_plus", "grade_c", "grade_d"
]

// MARK: - Tests

@Suite("Spanish localization of the grade ladders")
struct SpanishGradeLocalizationTests {

    @Test("Every grade and challenge key carries a Spanish value", arguments: translatedKeys + letterGradeKeys)
    func everyGradeKeyHasASpanishValue(key: String) throws {
        // Given a key the Summary screen renders
        // When it is looked up in the Spanish bundle
        let localized = value(key, in: try bundle(for: "es"))

        // Then the lookup resolves rather than handing back the key
        #expect(localized != key, "\(key) has no Spanish value, so it renders as its own key")
    }

    @Test("The strategy ladder and challenge tiers read in Spanish", arguments: translatedKeys)
    func prosePlainlyDiffersFromEnglish(key: String) throws {
        // Given a key whose value is prose rather than a glyph
        // When both languages are looked up
        let localized = value(key, in: try bundle(for: "es"))
        let source = value(key, in: try bundle(for: "en"))

        // Then Spanish says something of its own
        #expect(localized != source, "\(key) still reads as English: \"\(source)\"")
    }

    // The letter ladder is a game rank, not a school grade. Spain and Mexico
    // both grade 0-10, so translating A+ into either a Spanish academic word or
    // a number would import a convention the app does not mean -- and the
    // Efficiency card is one glyph wide. The entries exist so the choice is
    // recorded rather than arrived at by falling through to English.
    @Test("The letter ladder keeps its glyphs in Spanish", arguments: letterGradeKeys)
    func letterGradesAreIdenticalInBothLanguages(key: String) throws {
        // Given a letter grade
        // When both languages are looked up
        let localized = value(key, in: try bundle(for: "es"))
        let source = value(key, in: try bundle(for: "en"))

        // Then Spanish carries the same glyph, by decision
        #expect(localized == source, "\(key) diverges: es \"\(localized)\" vs en \"\(source)\"")
    }
}
