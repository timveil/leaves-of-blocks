//
//  LocalizationTestSupport.swift
//  LeavesOfBlocksTests
//
//  Shared access to the compiled strings tables the localization suites assert
//  against. Two suites needed the same three helpers; a third locale would have
//  made it three copies.
//

import Foundation
import Testing

@testable import LeavesOfBlocks

enum LocalizationBundles {

    /// The language every other one is checked against.
    static let source = "en"

    /// The app bundle, resolved through a type that lives in the app module.
    ///
    /// `Bundle.main` is the app only for as long as these tests are hosted by
    /// it. Run unhosted, `.main` would be the XCTest runner, which carries no
    /// `.lproj` at all — and a suite that silently finds no languages to
    /// compare is worse than no suite, because it stays green.
    static let app = Bundle(for: CoreDataManager.self)

    /// Every language the app ships, source language and Xcode's `Base`
    /// pseudo-entry excluded. Reading this from the bundle rather than a list
    /// means a locale added to `.locales` is covered the day it compiles, not
    /// the day someone remembers to add it here.
    static let translations: [String] = app.localizations
        .filter { $0 != source && $0 != "Base" }
        .sorted()

    /// A missing `.lproj` fails the case rather than substituting a fallback:
    /// comparing one bundle against itself would report agreement it never
    /// established.
    static func bundle(for language: String) throws -> Bundle {
        let path = try #require(
            app.path(forResource: language, ofType: "lproj"),
            "No \(language).lproj in \(app.bundlePath)"
        )
        return try #require(Bundle(path: path), "\(language).lproj is not loadable as a bundle")
    }

    /// The compiled strings table for one language, as shipped.
    ///
    /// Read from the built `.lproj` rather than the `.xcstrings` source, so
    /// assertions cover what a device actually loads. A missing table fails
    /// rather than returning an empty dictionary, which would compare nothing
    /// and report success.
    static func strings(for language: String) throws -> [String: String] {
        let bundle = try Self.bundle(for: language)
        let url = try #require(
            bundle.url(forResource: "Localizable", withExtension: "strings"),
            "No compiled Localizable.strings in \(language).lproj"
        )
        return try #require(NSDictionary(contentsOf: url) as? [String: String],
                            "\(language) Localizable.strings is not a string table")
    }

    /// One key's value in one language, looked up the way the app looks it up.
    ///
    /// A String Catalog compiles only the keys carrying a value for the
    /// language, so an untranslated key is absent and the lookup hands back the
    /// key itself — which is exactly what a player would see.
    static func value(_ key: String, in bundle: Bundle) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}
