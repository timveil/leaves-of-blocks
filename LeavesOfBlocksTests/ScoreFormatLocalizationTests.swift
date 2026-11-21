//
//  ScoreFormatLocalizationTests.swift
//  LeavesOfBlocksTests
//
//  Guards the strings that show a score against printing it ungrouped.
//

import Foundation
import Testing

@testable import LeavesOfBlocks

@Suite("Score format strings")
struct ScoreFormatLocalizationTests {

    /// A score already grouped by `Int.formattedScore`. `%lld` cannot group, so
    /// a format that takes the raw integer prints `12345` whatever the locale.
    private static let groupedScore = "12,345"

    @Test(
        "The continue-game line shows the score exactly as formatted",
        arguments: [LocalizationBundles.source] + LocalizationBundles.translations
    )
    func continueGameShowsFormattedScore(language: String) throws {
        let bundle = try LocalizationBundles.bundle(for: language)
        let format = LocalizationBundles.value("continue_game_format", in: bundle)

        let rendered = String(format: format, Self.groupedScore)

        #expect(rendered.contains(Self.groupedScore), "\(language): \(rendered)")
    }
}
