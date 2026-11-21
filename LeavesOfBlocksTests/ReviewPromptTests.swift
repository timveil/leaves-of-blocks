//
//  ReviewPromptTests.swift
//  LeavesOfBlocksTests
//
//  Tests for when the game asks for an App Store rating. The system sheet
//  itself (RequestReviewAction) is Apple's and is not exercised here; iOS
//  decides whether it actually appears.
//

import Foundation
import Testing
@testable import LeavesOfBlocks

// MARK: - Policy

@Suite("ReviewPrompt.shouldRequest")
struct ReviewPromptPolicyTests {

    @Test("A personal best after enough games asks for a rating")
    func personalBestAfterEnoughGamesAsks() {
        #expect(ReviewPrompt.shouldRequest(
            isNewHighScore: true,
            gamesPlayed: ReviewPrompt.minimumGamesPlayed,
            currentVersion: "2.1.1",
            lastRequestedVersion: nil
        ))
    }

    @Test("A game that is not a personal best never asks")
    func ordinaryGameDoesNotAsk() {
        #expect(!ReviewPrompt.shouldRequest(
            isNewHighScore: false,
            gamesPlayed: 50,
            currentVersion: "2.1.1",
            lastRequestedVersion: nil
        ))
    }

    @Test("A personal best in the first few games does not ask")
    func earlyPersonalBestDoesNotAsk() {
        // Every first game is a personal best, so this is the case that matters.
        #expect(!ReviewPrompt.shouldRequest(
            isNewHighScore: true,
            gamesPlayed: ReviewPrompt.minimumGamesPlayed - 1,
            currentVersion: "2.1.1",
            lastRequestedVersion: nil
        ))
    }

    @Test("Having asked in this version, it does not ask again")
    func alreadyAskedThisVersionDoesNotAsk() {
        #expect(!ReviewPrompt.shouldRequest(
            isNewHighScore: true,
            gamesPlayed: 50,
            currentVersion: "2.1.1",
            lastRequestedVersion: "2.1.1"
        ))
    }

    @Test("Having asked in an earlier version, it asks again")
    func askedInEarlierVersionAsksAgain() {
        #expect(ReviewPrompt.shouldRequest(
            isNewHighScore: true,
            gamesPlayed: 50,
            currentVersion: "2.2.0",
            lastRequestedVersion: "2.1.1"
        ))
    }
}

// MARK: - Persistence

@Suite("ReviewPrompt.lastRequestedVersion round-trip", .serialized)
struct ReviewPromptPersistenceTests {

    @Test("Nothing has been requested on a fresh install")
    func defaultsToNilWhenUnset() {
        let original = ReviewPrompt.lastRequestedVersion
        defer { ReviewPrompt.lastRequestedVersion = original }

        UserDefaults.standard.removeObject(forKey: "reviewPrompt.lastRequestedVersion")
        #expect(ReviewPrompt.lastRequestedVersion == nil)
    }

    @Test("A recorded version reads back")
    func setterPersistsToUserDefaults() {
        let original = ReviewPrompt.lastRequestedVersion
        defer { ReviewPrompt.lastRequestedVersion = original }

        ReviewPrompt.lastRequestedVersion = "2.1.1"
        #expect(ReviewPrompt.lastRequestedVersion == "2.1.1")
    }
}
