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
/// which argument it consumes and whether that argument must be an object.
private struct Specifier: Hashable, CustomStringConvertible {
    let argument: Int
    let wantsObject: Bool

    var description: String { "%\(argument)$\(wantsObject ? "@" : "d")" }
}

/// `%[argnum$][flags][width][.precision][length]conversion`
private let specifierPattern = try! NSRegularExpression(
    pattern: #"%(?:(\d+)\$)?[-+ #0]*[\d*]*(?:\.\d+)?(?:hh|h|ll|l|q|L|z|t|j)?([@dDiuUxXoOfeEgGcCsSpaAF%])"#
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
        guard let conversion = Range(match.range(at: 2), in: format).map({ String(format[$0]) }) else { continue }
        if conversion == "%" { continue }  // "%%" is an escaped percent, not an argument

        let position: Int
        if let positional = Range(match.range(at: 1), in: format).map({ String(format[$0]) }), let number = Int(positional) {
            position = number
        } else {
            implicit += 1
            position = implicit
        }

        found.append(Specifier(argument: position, wantsObject: "@sSpC".contains(conversion)))
    }

    return found.sorted { $0.argument < $1.argument }
}

/// The compiled strings table for one language, as shipped.
///
/// Read from the built `.lproj` rather than the `.xcstrings` source so the
/// assertion covers what a device actually loads.
private func strings(for language: String) -> [String: String] {
    guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
          let bundle = Bundle(path: path),
          let url = bundle.url(forResource: "Localizable", withExtension: "strings"),
          let table = NSDictionary(contentsOf: url) as? [String: String] else {
        Issue.record("No compiled Localizable.strings for \(language)")
        return [:]
    }
    return table
}

/// Every language the app bundle carries, source language first.
private let sourceLanguage = "en"
private let translations: [String] = Bundle.main.localizations
    .filter { $0 != sourceLanguage && $0 != "Base" }
    .sorted()

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
    func translationsMatchTheSourceLanguageSpecifiers(language: String) {
        // Given the compiled tables for the source language and one translation
        let source = strings(for: sourceLanguage)
        let translated = strings(for: language)
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

    @Test("The specifier parser reads argument order, not appearance order")
    func specifierParsingHandlesPositionalForms() {
        // Given a format string that reorders its arguments positionally
        // When its specifiers are read
        // Then they come back in argument order, matching the unordered form
        #expect(specifiers(in: "%d-cell %@ block") == specifiers(in: "Bloque %2$@ de %1$d celdas"))
        #expect(specifiers(in: "%d%%") == specifiers(in: "%d por ciento"))
        #expect(specifiers(in: "%@ %@") != specifiers(in: "%@"))
    }
}
