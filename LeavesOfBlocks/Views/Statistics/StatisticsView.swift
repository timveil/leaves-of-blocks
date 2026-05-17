import SwiftUI
import CoreData

// MARK: - Statistics View

/// Aggregate stats across every persisted `GameRecord`. Refreshes
/// automatically via `@FetchRequest` when a new run finishes.
struct StatisticsView: View {
    @FetchRequest(
        entity: GameRecord.entity(),
        sortDescriptors: []
    )
    private var records: FetchedResults<GameRecord>

    private var stats: ExtendedStatistics {
        ExtendedStatistics.aggregate(records.map(GameRecordSnapshot.init(record:)))
    }

    private let columns = [
        GridItem(.flexible(), spacing: GameTheme.Layout.mediumPadding),
        GridItem(.flexible(), spacing: GameTheme.Layout.mediumPadding)
    ]

    var body: some View {
        BaseScreenView {
            ScrollView {
                VStack(alignment: .leading, spacing: GameTheme.Layout.largePadding) {
                    section(
                        title: "stats_section_records".localized,
                        cards: recordsCards
                    )

                    section(
                        title: "stats_section_activity".localized,
                        cards: activityCards
                    )

                    section(
                        title: "stats_section_skill".localized,
                        cards: skillCards
                    )
                }
                .padding(.horizontal, GameTheme.Layout.largePadding)
                .padding(.vertical, GameTheme.Layout.mediumPadding)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
            .scrollFadeMask()
        }
    }

    private func section(title: String, cards: [StatCardData]) -> some View {
        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumPadding) {
            StrokedTitle(text: title)
                .padding(.leading, GameTheme.Layout.smallSpacing)

            LazyVGrid(columns: columns, spacing: GameTheme.Layout.mediumPadding) {
                ForEach(cards) { card in
                    CompactStatCard(title: card.title, value: card.value)
                }
            }
        }
    }

    // MARK: - Card Data

    private var recordsCards: [StatCardData] {
        [
            StatCardData(title: "high_score".localized, value: stats.highScore.abbreviatedScore),
            StatCardData(title: "stats_best_combo".localized, value: stats.bestCombo.abbreviatedScore),
            StatCardData(title: "stats_most_lines_game".localized, value: stats.mostLinesInGame.abbreviatedScore),
            StatCardData(title: "stats_longest_game".localized, value: stats.longestGameTime.formattedAsClock)
        ]
    }

    private var activityCards: [StatCardData] {
        [
            StatCardData(title: "games_played".localized, value: stats.totalGames.abbreviatedScore),
            StatCardData(title: "total_blocks".localized, value: stats.totalBlocksPlaced.abbreviatedScore),
            StatCardData(title: "stats_total_play_time".localized, value: stats.totalPlayTime.formattedAsHoursAndMinutes),
            StatCardData(title: "stats_days_played".localized, value: stats.daysPlayed.abbreviatedScore),
            StatCardData(
                title: "stats_favorite_difficulty".localized,
                value: stats.favoriteDifficulty?.displayName ?? "stats_value_unavailable".localized
            )
        ]
    }

    private var skillCards: [StatCardData] {
        let efficiencyPercent = Int((stats.averageEfficiency * 100).rounded())
        let efficiencyValue = stats.averageEfficiency > 0
            ? "stats_efficiency_format".localized(with: efficiencyPercent)
            : "stats_value_unavailable".localized

        let gradeValue = stats.typicalEfficiencyGradeKey.map { $0.localizedGrade }
            ?? "stats_value_unavailable".localized

        return [
            StatCardData(title: "average_score".localized, value: stats.averageScore.abbreviatedScore),
            StatCardData(title: "stats_avg_efficiency".localized, value: efficiencyValue),
            StatCardData(title: "stats_typical_grade".localized, value: gradeValue)
        ]
    }

}

// MARK: - Card Data Helper

private struct StatCardData: Identifiable {
    let id = UUID()
    let title: String
    let value: String
}

#Preview {
    let manager = CoreDataManager.makeInMemoryForTests()
    return StatisticsView()
        .environment(\.managedObjectContext, manager.viewContext)
        .environment(\.coreDataManager, manager)
}
