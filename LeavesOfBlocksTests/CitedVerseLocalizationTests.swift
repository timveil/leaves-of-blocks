//
//  CitedVerseLocalizationTests.swift
//  LeavesOfBlocksTests
//
//  Whitman is quoted, not translated.
//

import Foundation
import Testing

@testable import LeavesOfBlocks

// MARK: - Helpers

/// The quotation cards: verse, the poem it comes from, and the year.
///
/// `WhitmanQuoteCard` renders these with a title and a year, so they are
/// presented as citations. A citation reproduces its source; translating one
/// would be authoring a new poem and attributing it to Whitman, and the
/// published translations are separately copyrighted works besides.
private let citedVerseKeys = [
    "answer", "whitman_quote_1", "whitman_quote_2", "whitman_title", "whitman_year",
    "settings_quote", "settings_title", "settings_year",
    "how_to_play_quote", "how_to_play_title", "how_to_play_year"
]

/// The app's own line, shown on the game-over card with no attribution.
///
/// It echoes the cadence of the verse but is not a quotation, so it is copy
/// like any other and gets translated. Pinned here so the boundary between
/// "quoted" and "written in the style of" stays deliberate rather than
/// becoming whatever the next locale happens to do.
private let pasticheKey = "game_over_quote"

private let languages = LocalizationBundles.translations

// MARK: - Tests

@Suite("Cited verse localization")
struct CitedVerseLocalizationTests {

    @Test("Whitman reads identically in every language", arguments: languages, citedVerseKeys)
    func citedVerseIsNeverTranslated(language: String, key: String) throws {
        // Given a line the app presents as a quotation
        // When the language and the source language are compared
        let localized = LocalizationBundles.value(key, in: try LocalizationBundles.bundle(for: language))
        let source = LocalizationBundles.value(key, in: try LocalizationBundles.bundle(for: LocalizationBundles.source))

        // Then it carries Whitman's words, whatever the surrounding UI reads
        #expect(
            localized == source,
            "\(key) is translated in \(language) (\"\(localized)\"). Quoted verse stays in English."
        )
    }

    @Test("The game-over line is app copy, and is translated", arguments: languages)
    func thePasticheIsTranslated(language: String) throws {
        // Given the unattributed line the app wrote itself
        // When the language and the source language are compared
        let localized = LocalizationBundles.value(pasticheKey, in: try LocalizationBundles.bundle(for: language))
        let source = LocalizationBundles.value(pasticheKey, in: try LocalizationBundles.bundle(for: LocalizationBundles.source))

        // Then it reads in that language, because it is not a quotation
        #expect(
            localized != source,
            "\(pasticheKey) still reads as English in \(language). It is the app's own line, not Whitman's."
        )
    }
}
