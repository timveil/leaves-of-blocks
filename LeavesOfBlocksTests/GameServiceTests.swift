//
//  GameServiceTests.swift
//  LeavesOfBlocksTests
//
//  Tests for GameService time formatting and timer lifecycle.
//

import Testing
@testable import LeavesOfBlocks

// MARK: - Formatted Game Time

@Suite("GameService.formattedGameTime")
struct GameServiceFormatTests {
    @Test @MainActor
    func zeroIsRenderedAsClock() {
        let service = GameService()
        #expect(service.formattedGameTime() == "0:00")
    }

    @Test @MainActor
    func reflectsCurrentGameTime() {
        let service = GameService()
        // currentGameTime is settable; the formatter delegates to
        // TimeInterval.formattedAsClock.
        service.currentGameTime = 125
        #expect(service.formattedGameTime() == "2:05")
    }

    @Test @MainActor
    func gameTimeAccessorMirrorsCurrentGameTime() {
        let service = GameService()
        service.currentGameTime = 42
        #expect(service.gameTime == 42)
    }
}

// MARK: - Timer Lifecycle

@Suite("GameService timer lifecycle")
struct GameServiceTimerLifecycleTests {
    @Test @MainActor
    func startResetsAndKicksOffTheTimer() {
        let service = GameService()
        service.currentGameTime = 999

        service.startGameTimer()

        #expect(service.currentGameTime == 0)

        // Cleanup
        service.stopGameTimer()
    }

    @Test @MainActor
    func resetTimerKeepsTimerRunningAndZeroesElapsed() {
        let service = GameService()
        service.startGameTimer()
        service.currentGameTime = 10

        service.resetGameTimer()

        #expect(service.currentGameTime == 0)

        // Cleanup
        service.stopGameTimer()
    }

    @Test @MainActor
    func stopTimerLeavesElapsedAlone() {
        let service = GameService()
        service.startGameTimer()
        service.currentGameTime = 7

        service.stopGameTimer()

        #expect(service.currentGameTime == 7)
    }

    @Test @MainActor
    func startSessionResetsTime() {
        let service = GameService()
        service.currentGameTime = 50
        service.startGameSession(difficulty: .moderate)
        #expect(service.currentGameTime == 0)
        service.endGameSession()
    }
}
