import SwiftUI
import CoreData

// MARK: - Statistics View

/// Aggregate stats across every persisted `GameRecord`. Refreshes when the
/// Core Data context changes (e.g. a new run finishes while this screen is open).
struct StatisticsView: View {
    @State private var statistics = GameHistoryStatistics(
        totalGames: 0,
        totalScore: 0,
        averageScore: 0,
        totalBlocksPlaced: 0,
        highScore: 0
    )

    private let columns = [
        GridItem(.flexible(), spacing: GameTheme.Layout.mediumPadding),
        GridItem(.flexible(), spacing: GameTheme.Layout.mediumPadding)
    ]

    var body: some View {
        BaseScreenView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: GameTheme.Layout.mediumPadding) {
                    CompactStatCard(
                        title: "high_score".localized,
                        value: statistics.highScore.abbreviatedScore
                    )
                    CompactStatCard(
                        title: "games_played".localized,
                        value: statistics.totalGames.abbreviatedScore
                    )
                    CompactStatCard(
                        title: "average_score".localized,
                        value: statistics.averageScore.abbreviatedScore
                    )
                    CompactStatCard(
                        title: "total_blocks".localized,
                        value: statistics.totalBlocksPlaced.abbreviatedScore
                    )
                }
                .padding(.horizontal, GameTheme.Layout.largePadding)
                .padding(.vertical, GameTheme.Layout.mediumPadding)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
            .scrollFadeMask()
        }
        .onAppear {
            loadStatistics()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange)) { _ in
            loadStatistics()
        }
    }

    private func loadStatistics() {
        statistics = CoreDataManager.shared.calculateStatistics()
    }
}

#Preview {
    StatisticsView()
}
