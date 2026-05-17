import CoreData
import SwiftUI

struct HistoryView: View {
    var gameState: GameState
    let onSelectSession: (GameSession) -> Void

    @FetchRequest(
        entity: GameRecord.entity(),
        sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
    )
    private var records: FetchedResults<GameRecord>

    private var sessions: [GameSession] {
        records.compactMap(GameSession.init(record:))
    }

    private var highScore: Int {
        records.map { Int($0.score) }.max() ?? 0
    }

    var body: some View {
        BaseScreenView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: GameTheme.Layout.mediumPadding) {
                    StrokedTitle(text: "history_menu".localized)
                        .padding(.bottom, GameTheme.Layout.smallSpacing)

                    let sessions = self.sessions
                    if sessions.isEmpty {
                        Text("no_games_yet".localized)
                            .font(GameTheme.Typography.body)
                            .foregroundColor(GameTheme.Colors.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, GameTheme.Layout.extraLargePadding)
                    } else {
                        let topScore = highScore
                        ForEach(Array(sessions.enumerated()), id: \.offset) { index, session in
                            Button(action: {
                                HapticFeedback.tap()
                                onSelectSession(session)
                            }) {
                                GameSessionRow(
                                    session: session,
                                    isHighScore: session.score == topScore
                                )
                            }
                            .buttonStyle(.pressDarken)
                            .accessibilityIdentifier("game_history_button_\(index)")
                        }
                    }
                }
                .padding(.horizontal, GameTheme.Layout.largePadding)
                .padding(.vertical, GameTheme.Layout.mediumPadding)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
            .scrollFadeMask()
        }
    }
}

#Preview {
    // Use an isolated in-memory CoreDataManager so previews don't write
    // mock sessions into the developer's real game history (the previous
    // version did — every preview render saved 5 sample records to the
    // shared store).
    struct PreviewWrapper: View {
        @State private var hasLoadedData = false
        let coreDataManager: CoreDataManager

        var body: some View {
            HistoryView(
                gameState: GameState(),
                onSelectSession: { _ in }
            )
            .environment(\.managedObjectContext, coreDataManager.viewContext)
            .environment(\.coreDataManager, coreDataManager)
            .onAppear {
                guard !hasLoadedData else { return }
                hasLoadedData = true

                let sessions = [
                    (score: 2450, blocks: 45, lines: 12, difficulty: DifficultyMode.hard, combo: 3, time: 180.0, daysAgo: 0),
                    (score: 1890, blocks: 38, lines: 8, difficulty: DifficultyMode.moderate, combo: 2, time: 150.0, daysAgo: 1),
                    (score: 3200, blocks: 52, lines: 15, difficulty: DifficultyMode.hard, combo: 4, time: 220.0, daysAgo: 2),
                    (score: 1240, blocks: 28, lines: 6, difficulty: DifficultyMode.easy, combo: 1, time: 120.0, daysAgo: 3),
                    (score: 2780, blocks: 41, lines: 11, difficulty: DifficultyMode.moderate, combo: 3, time: 165.0, daysAgo: 5)
                ]

                for session in sessions {
                    let mockMetrics = PlayerBehaviorTracker.SessionMetrics(
                        score: session.score,
                        blocksPlaced: session.blocks,
                        linesCleared: session.lines,
                        longestCombo: session.combo,
                        gameTime: session.time,
                        difficulty: session.difficulty,
                        averageGridEfficiency: Double.random(in: 0.4...0.9),
                        averageFragmentation: Double.random(in: 0.2...0.6),
                        strategicPlayRating: Double.random(in: 0.3...0.8),
                        tierUsageDistribution: ["diverse": 10, "constrained": 15, "minimal": 5],
                        fallbackActivations: Int.random(in: 0...3),
                        challengeMaintained: Double.random(in: 0.3...0.8)
                    )

                    try? coreDataManager.saveGameRecord(
                        score: session.score,
                        difficulty: session.difficulty,
                        blocksPlaced: session.blocks,
                        linesCleared: session.lines,
                        longestCombo: session.combo,
                        gameTime: session.time,
                        sessionMetrics: mockMetrics
                    )
                }
            }
        }
    }

    return PreviewWrapper(coreDataManager: CoreDataManager.makeInMemoryForTests())
}
