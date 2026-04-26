import SwiftUI

struct HistoryView: View {
    @ObservedObject var gameState: GameState
    let onSelectSession: (GameSession) -> Void
    @State private var gameHistory: [GameSession] = []
    @State private var statistics = GameStatistics(totalGames: 0, totalScore: 0, averageScore: 0, totalBlocksPlaced: 0, highScore: 0)

    private func loadGameHistory() {
        let records = CoreDataManager.shared.fetchGameHistory()

        var sessions: [GameSession] = []

        if gameState.score > 0 && !gameState.isGameOver {
            sessions.append(GameSession(
                date: Date(),
                score: gameState.score,
                blocksPlaced: gameState.blocksPlaced,
                linesCleared: gameState.linesCleared,
                difficulty: gameState.currentDifficulty,
                gameTime: gameState.currentGameTime,
                averageGridEfficiency: nil,
                averageFragmentation: nil,
                strategicPlayRating: nil,
                challengeMaintained: nil,
                fallbackActivations: nil,
                efficiencyGrade: nil,
                strategicGrade: nil,
                tierUsageDistribution: nil
            ))
        }

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
        statistics = CoreDataManager.shared.calculateStatistics()
    }

    private var totalGames: Int {
        gameHistory.count
    }

    private var averageScore: Int {
        guard totalGames > 0 else { return 0 }
        return gameHistory.reduce(0) { $0 + $1.score } / totalGames
    }

    private var totalBlocksPlaced: Int {
        gameHistory.reduce(0) { $0 + $1.blocksPlaced }
    }

    var body: some View {
        BaseScreenView {
            ScrollView {
                VStack(spacing: GameTheme.Layout.mediumPadding) {
                    HistoryStatCard(
                        title: "high_score".localized,
                        value: statistics.highScore.abbreviatedScore
                    )
                    HistoryStatCard(
                        title: "games_played".localized,
                        value: totalGames.abbreviatedScore
                    )
                    HistoryStatCard(
                        title: "average_score".localized,
                        value: averageScore.abbreviatedScore
                    )
                    HistoryStatCard(
                        title: "total_blocks".localized,
                        value: totalBlocksPlaced.abbreviatedScore
                    )

                    // Section divider
                    Text("past_games".localized)
                        .font(GameTheme.Typography.title)
                        .foregroundColor(GameTheme.Colors.buttonText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, GameTheme.Layout.mediumPadding)
                        .background(GameTheme.Colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                                .stroke(Color.black, lineWidth: 2.5)
                        )

                    ForEach(gameHistory.indices, id: \.self) { index in
                        Button(action: {
                            onSelectSession(gameHistory[index])
                        }) {
                            GameSessionRow(
                                session: gameHistory[index],
                                isHighScore: gameHistory[index].score == statistics.highScore
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityIdentifier("game_history_button_\(index)")
                    }
                }
                .padding(.horizontal, GameTheme.Layout.largePadding)
                .padding(.vertical, GameTheme.Layout.mediumPadding)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
            .mask(
                VStack(spacing: 0) {
                    Color.black
                    LinearGradient(
                        colors: [.black, .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 160)
                }
            )
        }
        .onAppear {
            loadGameHistory()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange)) { _ in
            loadGameHistory()
        }
    }
}

/// Represents a completed game session with all relevant statistics.
struct GameSession: Equatable {
    let date: Date
    let score: Int
    let blocksPlaced: Int
    let linesCleared: Int
    let difficulty: DifficultyMode
    let gameTime: TimeInterval
    let averageGridEfficiency: Double?
    let averageFragmentation: Double?
    let strategicPlayRating: Double?
    let challengeMaintained: Double?
    let fallbackActivations: Int?
    let efficiencyGrade: String?
    let strategicGrade: String?
    let tierUsageDistribution: String?

    var formattedGameTime: String {
        let minutes = Int(gameTime) / 60
        let seconds = Int(gameTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
