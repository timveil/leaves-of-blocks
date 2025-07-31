import SwiftUI

struct HowToPlayView: View {
    
    var body: some View {
        BaseScreenView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: GameTheme.Layout.largePadding) {
                    // Header
                    VStack(spacing: GameTheme.Layout.mediumSpacing) {
                        Text("how_to_play".localized)
                            .pageTitleStyle()
                            .padding(.top, GameTheme.Layout.mediumPadding)
                    }
                    
                    // Content sections
                    VStack(alignment: .leading, spacing: GameTheme.Layout.largePadding) {
                        // The Grid
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            Text("the_grid".localized)
                                .sectionHeaderStyle()
                            
                            Text("the_grid_description".localized)
                                .sectionTextStyle(color: GameTheme.Colors.secondaryText)
                                .lineSpacing(6)
                        }
                        
                        // Drag & Drop
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            Text("drag_drop".localized)
                                .sectionHeaderStyle()
                            
                            Text("drag_drop_description".localized)
                                .sectionTextStyle(color: GameTheme.Colors.secondaryText)
                                .lineSpacing(6)
                        }
                        
                        // Clear Lines
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            Text("clear_lines".localized)
                                .sectionHeaderStyle()
                            
                            Text("clear_lines_description".localized)
                                .sectionTextStyle(color: GameTheme.Colors.secondaryText)
                                .lineSpacing(6)
                        }
                        
                        // Game Over
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            Text("game_over_rules".localized)
                                .sectionHeaderStyle()
                            
                            Text("game_over_description".localized)
                                .sectionTextStyle(color: GameTheme.Colors.secondaryText)
                                .lineSpacing(6)
                        }
                        
                        // Pro Tips
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            Text("pro_tips".localized)
                                .sectionHeaderStyle()
                            
                            VStack(alignment: .leading, spacing: GameTheme.Layout.smallSpacing) {
                                TipRow(text: "tip_keep_empty".localized)
                                TipRow(text: "tip_multiple_lines".localized)
                                TipRow(text: "tip_dont_rush".localized)
                                TipRow(text: "tip_corners_edges".localized)
                                TipRow(text: "tip_plan_ahead".localized)
                            }
                        }
                        
                    
                        // Scoring Section - Table Style
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            
                            VStack(spacing: 0) {
                                // Table Header
                                ScoringTableHeaderView()
                                
                                ScoringTableRowView(
                                    points: "10",
                                    description: "scoring_blocks_placed".localized,
                                    color: GameTheme.Colors.blockBlue,
                                    isFirst: false,
                                    isLast: false
                                )
                                
                                ScoringTableRowView(
                                    points: "100",
                                    description: "scoring_clear_lines".localized,
                                    color: GameTheme.Colors.blockGreen,
                                    isFirst: false,
                                    isLast: false
                                )
                                
                                ScoringTableRowView(
                                    points: "+50",
                                    description: "scoring_combo_bonus".localized,
                                    color: GameTheme.Colors.blockOrange,
                                    isFirst: false,
                                    isLast: true
                                )
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                                    .stroke(GameTheme.Colors.gridBorder.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        // Difficulty Modes
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            
                            VStack(spacing: 0) {
                                // Table Header
                                DifficultyTableHeaderView()
                                
                                DifficultyTableRowView(
                                    mode: .easy,
                                    description: "difficulty_easy_desc".localized,
                                    isFirst: false,
                                    isLast: false
                                )
                                
                                DifficultyTableRowView(
                                    mode: .moderate,
                                    description: "difficulty_moderate_desc".localized,
                                    isFirst: false,
                                    isLast: false
                                )
                                
                                DifficultyTableRowView(
                                    mode: .hard,
                                    description: "difficulty_hard_desc".localized,
                                    isFirst: false,
                                    isLast: true
                                )
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                                    .stroke(GameTheme.Colors.gridBorder.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        // Block Shapes Section - Table Style
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            
                            VStack(spacing: 0) {
                                // Table Header
                                ShapesTableHeaderView()
                                
                                ShapesTableRowView(
                                    shapeType: .normalBlocks,
                                    description: "shape_normal_desc".localized,
                                    isFirst: false,
                                    isLast: false
                                )
                                
                                ShapesTableRowView(
                                    shapeType: .horizontalClear,
                                    description: "shape_horizontal_desc".localized,
                                    isFirst: false,
                                    isLast: false
                                )
                                
                                ShapesTableRowView(
                                    shapeType: .verticalClear,
                                    description: "shape_vertical_desc".localized,
                                    isFirst: false,
                                    isLast: false
                                )
                                
                                ShapesTableRowView(
                                    shapeType: .areaClear,
                                    description: "shape_area_desc".localized,
                                    isFirst: false,
                                    isLast: true
                                )
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                                    .stroke(GameTheme.Colors.gridBorder.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                    }
                    
                    Spacer(minLength: GameTheme.Layout.extraLargePadding)
                }
                .padding(.horizontal, GameTheme.Layout.largePadding)
                .padding(.bottom, 80)
                }
                .frame(height: geometry.size.height - 100) // Leave space for grass
            }
        }
    }
}

#Preview {
    HowToPlayView()
}
