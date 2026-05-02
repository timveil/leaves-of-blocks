import SwiftUI

struct HistoryView: View {
    var gameState: GameState
    let onSelectSession: (GameSession) -> Void
    @State private var gameHistory: [GameSession] = []
    @State private var highScore: Int = 0

    private func loadGameHistory() {
        let records = CoreDataManager.shared.fetchGameHistory()

        var sessions: [GameSession] = []

        for record in records {
            if let date = record.date,
               let difficultyString = record.difficulty,
               let difficulty = DifficultyMode(rawValue: difficultyString) {
                sessions.append(GameSession(
                    date: date,
                    score: Int(record.score),
                    blocksPlaced: Int(record.blocksPlaced),
                    linesCleared: Int(record.linesCleared),
                    difficulty: difficulty,
                    gameTime: record.gameTime,
                    averageGridEfficiency: record.averageGridEfficiency > 0 ? record.averageGridEfficiency : nil,
                    averageFragmentation: record.averageFragmentation > 0 ? record.averageFragmentation : nil,
                    strategicPlayRating: record.strategicPlayRating > 0 ? record.strategicPlayRating : nil,
                    challengeMaintained: record.challengeMaintained > 0 ? record.challengeMaintained : nil,
                    fallbackActivations: nil,
                    efficiencyGrade: record.efficiencyGrade?.isEmpty == false ? record.efficiencyGrade : nil,
                    strategicGrade: record.strategicGrade?.isEmpty == false ? record.strategicGrade : nil,
                    tierUsageDistribution: record.tierUsageDistribution?.isEmpty == false ? record.tierUsageDistribution : nil
                ))
            }
        }

        gameHistory = sessions.sorted { $0.date > $1.date }
        highScore = CoreDataManager.shared.calculateStatistics().highScore
    }

    var body: some View {
        BaseScreenView {
            ScrollView {
                VStack(spacing: GameTheme.Layout.mediumPadding) {
                    if gameHistory.isEmpty {
                        Text("no_games_yet".localized)
                            .font(GameTheme.Typography.body)
                            .foregroundColor(GameTheme.Colors.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, GameTheme.Layout.extraLargePadding)
                    } else {
                        ForEach(gameHistory.indices, id: \.self) { index in
                            Button(action: {
                                onSelectSession(gameHistory[index])
                            }) {
                                GameSessionRow(
                                    session: gameHistory[index],
                                    isHighScore: gameHistory[index].score == highScore
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
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
        .onAppear {
            loadGameHistory()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange)) { _ in
            loadGameHistory()
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var hasLoadedData = false

        var body: some View {
            HistoryView(
                gameState: GameState(),
                onSelectSession: { _ in }
            )
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

                    CoreDataManager.shared.saveGameRecord(
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

    return PreviewWrapper()
}
