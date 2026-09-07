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

/// The app bundle, resolved through a type that lives in the app module.
///
/// `Bundle.main` is the app only for as long as these tests are hosted by it.
/// Run unhosted, `.main` would be the XCTest runner, which carries no `.lproj`
/// at all -- and a check that silently finds no languages to compare is worse
/// than no check, because it stays green.
private let appBundle = Bundle(for: CoreDataManager.self)

/// The compiled strings table for one language, as shipped.
///
/// Read from the built `.lproj` rather than the `.xcstrings` source so the
/// assertion covers what a device actually loads. A missing table fails the
/// case rather than returning an empty dictionary, which would compare
/// nothing and report success.
private func strings(for language: String) throws -> [String: String] {
    let path = try #require(
        appBundle.path(forResource: language, ofType: "lproj"),
        "No \(language).lproj in \(appBundle.bundlePath)"
    )
    let bundle = try #require(Bundle(path: path), "\(language).lproj is not loadable as a bundle")
    let url = try #require(
        bundle.url(forResource: "Localizable", withExtension: "strings"),
        "No compiled Localizable.strings in \(language).lproj"
    )
    return try #require(NSDictionary(contentsOf: url) as? [String: String],
                        "\(language) Localizable.strings is not a string table")
}

/// Every language the app bundle carries, source language first.
private let sourceLanguage = "en"
private let translations: [String] = appBundle.localizations
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
        // Given a format string that reorders its arguments positionally
        // When its specifiers are read
        // Then they come back in argument order, matching the unordered form
        #expect(specifiers(in: "%d-cell %@ block") == specifiers(in: "Bloque %2$@ de %1$d celdas"))
        #expect(specifiers(in: "%d%%") == specifiers(in: "%d por ciento"))
        #expect(specifiers(in: "%@ %@") != specifiers(in: "%@"))
    }
}
