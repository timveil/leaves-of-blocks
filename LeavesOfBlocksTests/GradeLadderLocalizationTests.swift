//
//  GradeLadderLocalizationTests.swift
//  LeavesOfBlocksTests
//
//  Coverage for the values a player reads at the end of a game, in every
//  language the app ships.
//

import Foundation
import Testing

@testable import LeavesOfBlocks

// MARK: - Helpers

/// The strategy ladder and the challenge tiers: prose, translated.
private let translatedKeys = [
    "grade_master", "grade_expert", "grade_skilled", "grade_learning", "grade_beginner",
    "challenge_high", "challenge_medium", "challenge_low"
]

/// The efficiency ladder: glyphs, deliberately identical in every language.
private let letterGradeKeys = [
    "grade_a_plus", "grade_a", "grade_b_plus", "grade_b", "grade_c_plus", "grade_c", "grade_d"
]

private let languages = LocalizationBundles.translations

// MARK: - Tests

@Suite("Grade ladder localization")
struct GradeLadderLocalizationTests {

    // Parameterized over the languages the bundle reports rather than a list
    // written here: German arrived with 187 keys and needed no edit to this
    // file, and Japanese will not either.
    @Test("Every grade and challenge key carries a value", arguments: languages, translatedKeys + letterGradeKeys)
    func everyGradeKeyIsLocalized(language: String, key: String) throws {
        // Given a key the Summary screen renders
        // When it is looked up in a shipped language
        let localized = LocalizationBundles.value(key, in: try LocalizationBundles.bundle(for: language))

        // Then the lookup resolves rather than handing back the key
        #expect(localized != key, "\(language) has no value for \(key), so it renders as its own key")
    }

    @Test("The strategy ladder and challenge tiers are translated", arguments: languages, translatedKeys)
    func prosePlainlyDiffersFromTheSourceLanguage(language: String, key: String) throws {
        // Given a key whose value is prose rather than a glyph
        // When the language and the source language are compared
        let localized = LocalizationBundles.value(key, in: try LocalizationBundles.bundle(for: language))
        let source = LocalizationBundles.value(key, in: try LocalizationBundles.bundle(for: LocalizationBundles.source))

        // Then the translation says something of its own
        #expect(localized != source, "\(language) \(key) still reads as English: \"\(source)\"")
    }

    // The letter ladder is a game rank, not a school grade. Spain and Mexico
    // grade 0-10 and Germany 1-6, so translating A+ into local academic words
    // or numbers would import a convention the app does not mean -- and the
    // Efficiency card is one glyph wide. The entries exist in every language so
    // the choice is recorded rather than arrived at by falling through.
    @Test("The letter ladder keeps its glyphs in every language", arguments: languages, letterGradeKeys)
    func letterGradesAreIdenticalInEveryLanguage(language: String, key: String) throws {
        // Given a letter grade
        // When the language and the source language are compared
        let localized = LocalizationBundles.value(key, in: try LocalizationBundles.bundle(for: language))
        let source = LocalizationBundles.value(key, in: try LocalizationBundles.bundle(for: LocalizationBundles.source))

        // Then it carries the same glyph, by decision
        #expect(localized == source, "\(key) diverges in \(language): \"\(localized)\" vs \"\(source)\"")
    }

    // A parameterized test over an empty array runs no cases and reports
    // success, so the language list is itself worth asserting.
    //
    // Only that it is non-empty. Which languages ship is .locales' business,
    // and scripts/check-locales.sh already holds the catalog to it — naming
    // them here too would mean editing this file for every locale added, and
    // failing the PR that adds one (conventions/invariants-not-counts.md).
    @Test("The app bundle carries languages to check")
    func theBundleCarriesTranslations() {
        #expect(!languages.isEmpty, "no translations found in \(LocalizationBundles.app.bundlePath)")
    }
}
