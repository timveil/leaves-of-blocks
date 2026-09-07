//
//  LocalizationEscapeTests.swift
//  LeavesOfBlocksTests
//
//  A string wanting a line break has a real one, in every language.
//

import Foundation
import Testing

@testable import LeavesOfBlocks

// MARK: - Helpers

/// The source language as well as the translations.
///
/// Unlike the other localization suites, this one has nothing to compare
/// against English — it asserts a property each value holds on its own. So
/// English is checked too, which matters: it is where the defect that prompted
/// this suite lived, and it is the version most players see.
private let allLanguages = [LocalizationBundles.source] + LocalizationBundles.translations

/// Two-character sequences that read as an escape but are not one.
///
/// A String Catalog value is data, not source: `NSLocalizedString` returns it
/// verbatim and performs no escape processing, so a backslash followed by `n`
/// reaches `Text` as two characters and is drawn as two characters.
private let unresolvedEscapes = ["\\n", "\\t", "\\r"]

// MARK: - Tests

@Suite("Localization escape sequences")
struct LocalizationEscapeTests {

    /// `shape_normal_blocks` held `Normal\nBlocks` in English and Spanish while
    /// the other eight languages held a real newline, so the How to Play screen
    /// drew a literal `\n` to anyone playing in either.
    ///
    /// It was invisible to everything already in place: `check-locales.sh` saw a
    /// translated value, the format-specifier suite saw no specifiers to
    /// compare, and coverage counted it as present. The string was simply wrong
    /// on screen.
    @Test("No value carries an unresolved escape sequence", arguments: allLanguages)
    func valuesCarryNoUnresolvedEscapes(language: String) throws {
        // Given the strings table a device actually loads
        let strings = try LocalizationBundles.strings(for: language)

        // When each value is examined for a backslash that was meant to be
        // whitespace
        let offenders = strings
            .filter { _, value in unresolvedEscapes.contains(where: value.contains) }
            .keys
            .sorted()

        // Then there are none: a line break is a line break, not two characters
        #expect(
            offenders.isEmpty,
            "\(language) renders a literal escape sequence in: \(offenders.joined(separator: ", "))"
        )
    }

    // Parameterized over the languages the bundle reports, and a parameterized
    // test over an empty array runs no cases and reports success. Without this,
    // a bundle that resolved to the XCTest runner would turn the suite green by
    // checking nothing.
    @Test("The app bundle carries languages to check")
    func theBundleCarriesLanguages() {
        #expect(!allLanguages.isEmpty, "no languages found in \(LocalizationBundles.app.bundlePath)")
        #expect(allLanguages.count > 1, "only the source language was found; translations are missing")
    }
}
