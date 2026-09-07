//
//  LocalizationFormatTests.swift
//  LeavesOfBlocksTests
//
//  Guards every localization against format-specifier drift.
//

import Foundation
import Testing

@testable import LeavesOfBlocks

// MARK: - Helpers

/// One format specifier, reduced to what `String(format:)` will do with it:
/// which argument it consumes, and how.
private struct Specifier: Hashable, CustomStringConvertible {
    let argument: Int

    /// Length modifier plus conversion character, e.g. `lld`, `d`, `f`, `@`.
    ///
    /// The pair together decides how the argument is pulled off the variadic
    /// list, so both halves have to match: `%lld` against `%d` reads a
    /// different width, and `%f` against `%d` reads a different register class
    /// entirely. Collapsing these to "object or not" would let a translation
    /// swap them and still pass, which is the case this suite exists to catch.
    ///
    /// Flags, width and precision are deliberately not compared — `%.2f`
    /// against `%f` renders differently but consumes the same argument, and a
    /// translation is entitled to that choice.
    let conversion: String

    var description: String { "%\(argument)$\(conversion)" }
}

/// `%[argnum$][flags][width][.precision][length]conversion`
private let specifierPattern = try! NSRegularExpression(
    pattern: #"%(?:(\d+)\$)?[-+ #0]*[\d*]*(?:\.\d+)?(hh|h|ll|l|q|L|z|t|j)?([@dDiuUxXoOfeEgGcCsSpaAF%])"#
)

/// The specifiers a format string will consume, in argument order.
///
/// Positional forms (`%1$d`) are compared by the argument they name rather
/// than by where they appear, which is the whole point: a translation is
/// free to reorder the sentence as long as it says which argument each
/// placeholder means.
private func specifiers(in format: String) -> [Specifier] {
    let range = NSRange(format.startIndex..., in: format)
    var found: [Specifier] = []
    var implicit = 0

    for match in specifierPattern.matches(in: format, range: range) {
        guard let conversion = Range(match.range(at: 3), in: format).map({ String(format[$0]) }) else { continue }
        if conversion == "%" { continue }  // "%%" is an escaped percent, not an argument

        let position: Int
        if let positional = Range(match.range(at: 1), in: format).map({ String(format[$0]) }), let number = Int(positional) {
            position = number
        } else {
            implicit += 1
            position = implicit
        }

        let length = Range(match.range(at: 2), in: format).map { String(format[$0]) } ?? ""
        found.append(Specifier(argument: position, conversion: length + conversion))
    }

    return found.sorted { $0.argument < $1.argument }
}

/// Every language the bundle carries, and the tables to compare, come from
/// LocalizationTestSupport so the grade-ladder suite and this one cannot drift
/// apart on how they resolve a bundle.
private let sourceLanguage = LocalizationBundles.source
private let translations = LocalizationBundles.translations

private func strings(for language: String) throws -> [String: String] {
    try LocalizationBundles.strings(for: language)
}

private let appBundle = LocalizationBundles.app

// MARK: - Tests

@Suite("Localization format specifiers")
struct LocalizationFormatTests {

    // A translation that reorders a sentence has to say which argument each
    // placeholder means. Spanish reordered `ax_block_format` without doing so,
    // and the Int argument was dereferenced as an object pointer -- a hard
    // crash on the board for every Spanish player, in the shipped build.
    //
    // German and Japanese reorder more aggressively than Spanish does, so this
    // matters more with each locale added, not less.
    @Test("Every translation consumes the same arguments as the source language", arguments: translations)
    func translationsMatchTheSourceLanguageSpecifiers(language: String) throws {
        // Given the compiled tables for the source language and one translation
        let source = try strings(for: sourceLanguage)
        let translated = try strings(for: language)
        #expect(!source.isEmpty, "no source strings to compare against")

        // When each shared key's specifiers are compared by argument
        for (key, sourceValue) in source.sorted(by: { $0.key < $1.key }) {
            guard let translatedValue = translated[key] else { continue }
            let expected = specifiers(in: sourceValue)
            let actual = specifiers(in: translatedValue)

            // Then the translation consumes the same arguments, in the same types
            #expect(
                actual == expected,
                """
                \(language) "\(key)" would consume \(actual) where \(sourceLanguage) consumes \(expected).
                  \(sourceLanguage): "\(sourceValue)"
                  \(language): "\(translatedValue)"
                Use positional specifiers (%1$d, %2$@) to reorder safely.
                """
            )
        }
    }

    // A parameterized test over an empty array runs no cases and reports
    // success, so the list of languages is itself worth asserting -- otherwise
    // a bundle that resolved to the wrong place would look like a pass.
    @Test("The app bundle carries the translations to check")
    func theBundleCarriesTranslations() {
        #expect(!translations.isEmpty, "no translations found in \(appBundle.bundlePath)")
        #expect(translations.contains("es"), "expected Spanish among \(translations)")
    }

    @Test("The specifier parser reads argument order, not appearance order")
    func specifierParsingHandlesPositionalForms() {
        // Given format strings that reorder their arguments positionally
        // When their specifiers are read
        // Then they come back in argument order, matching the unordered form
        #expect(specifiers(in: "%d-cell %@ block") == specifiers(in: "Bloque %2$@ de %1$d celdas"))
        #expect(specifiers(in: "%d%%") == specifiers(in: "%d por ciento"))
        #expect(specifiers(in: "%@ %@") != specifiers(in: "%@"))
    }

    // Width and register class are what make a mismatch dangerous rather than
    // merely wrong: %lld against %d reads a different number of bytes, and %f
    // against %d reads from a different register class. The catalog already
    // carries both %d and %lld strings, so a translation swapping them is a
    // reachable mistake and has to fail here.
    @Test("Conversions differing only in width or register class are not equal")
    func specifierComparisonIsNotCollapsedToObjectOrNot() {
        // Given two format strings whose arguments are consumed differently
        // When their specifiers are compared
        // Then they do not match
        #expect(specifiers(in: "%lld points") != specifiers(in: "%d points"))
        #expect(specifiers(in: "%d items") != specifiers(in: "%f items"))
        #expect(specifiers(in: "%@ name") != specifiers(in: "%s name"))

        // And an identical conversion still matches, reordered or not
        #expect(specifiers(in: "%lld of %lld") == specifiers(in: "%2$lld de %1$lld"))
    }
}
