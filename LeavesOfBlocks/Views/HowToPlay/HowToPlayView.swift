import SwiftUI

struct HowToPlayView: View {

    var body: some View {
        BaseScreenView {
            ScrollView {
                VStack(alignment: .leading, spacing: GameTheme.Layout.mediumPadding) {
                    StrokedTitle(text: "how_to_play".localized)
                        .accessibilityIdentifier("how_to_play_screen")
                        .padding(.bottom, GameTheme.Layout.smallSpacing)

                    WhitmanQuoteCard(
                        quote: "how_to_play_quote".localized,
                        title: "how_to_play_title".localized,
                        year: "how_to_play_year".localized
                    )

                    // Main content card
                    VStack(alignment: .leading, spacing: GameTheme.Layout.largePadding) {
                        sectionBlock("the_grid", "the_grid_description")
                        sectionBlock("drag_drop", "drag_drop_description")
                        sectionBlock("clear_lines", "clear_lines_description")
                        sectionBlock("game_over_rules", "game_over_description")
                        sectionBlock("advanced_features", "advanced_features_description")
                        sectionBlock("efficiency_system", "efficiency_system_description")
                        sectionBlock("strategic_grading", "strategic_grading_description")
                        sectionBlock("adaptive_difficulty", "adaptive_difficulty_description")

                        // Pro Tips
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            Text("pro_tips".localized)
                                .sectionHeaderStyle()

                            VStack(alignment: .leading, spacing: GameTheme.Layout.smallSpacing) {
                                TipRow(text: "tip_keep_organized".localized)
                                TipRow(text: "tip_multiple_lines".localized)
                                TipRow(text: "tip_plan_ahead".localized)
                                TipRow(text: "tip_corners_edges".localized)
                                TipRow(text: "tip_save_small_blocks".localized)
                                TipRow(text: "tip_efficiency_matters".localized)
                            }
                        }
                    }
                    .padding(GameTheme.Layout.largePadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentCard()

                    // Scoring table card
                    VStack(spacing: 0) {
                        ScoringTableHeaderView()

                        ScoringTableRowView(
                            points: "10",
                            description: "scoring_blocks_placed".localized,
                            color: GameTheme.Colors.blockBlue
                        )
                        ScoringTableRowView(
                            points: "100",
                            description: "scoring_clear_lines".localized,
                            color: GameTheme.Colors.blockGreen
                        )
                        ScoringTableRowView(
                            points: "+50",
                            description: "scoring_combo_bonus".localized,
                            color: GameTheme.Colors.blockOrange
                        )
                    }
                    .folkArtCard()

                    // Difficulty table card
                    VStack(spacing: 0) {
                        DifficultyTableHeaderView()

                        DifficultyTableRowView(
                            mode: .easy,
                            description: "difficulty_easy_desc".localized
                        )
                        DifficultyTableRowView(
                            mode: .moderate,
                            description: "difficulty_moderate_desc".localized
                        )
                        DifficultyTableRowView(
                            mode: .hard,
                            description: "difficulty_hard_desc".localized
                        )
                    }
                    .folkArtCard()

                    // Block Shapes table card
                    VStack(spacing: 0) {
                        ShapesTableHeaderView()

                        ShapesTableRowView(
                            shapeType: .normalBlocks,
                            description: "shape_normal_desc".localized
                        )
                        ShapesTableRowView(
                            shapeType: .horizontalClear,
                            description: "shape_horizontal_desc".localized
                        )
                        ShapesTableRowView(
                            shapeType: .verticalClear,
                            description: "shape_vertical_desc".localized
                        )
                        ShapesTableRowView(
                            shapeType: .areaClear,
                            description: "shape_area_desc".localized
                        )
                    }
                    .folkArtCard()
                }
                .padding(.horizontal, GameTheme.Layout.largePadding)
                .padding(.vertical, GameTheme.Layout.mediumPadding)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
            .scrollFadeMask()
        }
    }

    private func sectionBlock(_ titleKey: String, _ bodyKey: String) -> some View {
        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
            Text(titleKey.localized)
                .sectionHeaderStyle()

            Text(bodyKey.localized)
                .sectionTextStyle(color: GameTheme.Colors.secondaryText)
                .lineSpacing(6)
        }
    }
}

#Preview {
    HowToPlayView()
}
