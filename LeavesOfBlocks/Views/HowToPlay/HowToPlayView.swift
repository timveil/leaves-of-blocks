import SwiftUI

struct HowToPlayView: View {
    
    var body: some View {
        BaseScreenView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: GameTheme.Layout.largePadding) {
                    // Header
                    VStack(spacing: GameTheme.Layout.mediumSpacing) {
                        Text("How to Play")
                            .pageTitleStyle()
                            .padding(.top, GameTheme.Layout.mediumPadding)
                    }
                    
                    // Content sections
                    VStack(alignment: .leading, spacing: GameTheme.Layout.largePadding) {
                        // The Grid
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            Text("The Grid")
                                .sectionHeaderStyle()
                            
                            Text("You have an 8×8 grid where you'll place block shapes. Fill complete rows or columns to clear them and earn points.")
                                .sectionTextStyle(color: GameTheme.Colors.secondaryText)
                                .lineSpacing(6)
                        }
                        
                        // Drag & Drop
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            Text("Drag & Drop")
                                .sectionHeaderStyle()
                            
                            Text("Drag block shapes from the bottom area onto the grid. Blocks must fit completely within the grid boundaries.")
                                .sectionTextStyle(color: GameTheme.Colors.secondaryText)
                                .lineSpacing(6)
                        }
                        
                        // Clear Lines
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            Text("Clear Lines")
                                .sectionHeaderStyle()
                            
                            Text("Complete horizontal rows or vertical columns disappear, earning you 100 points per line. Clear multiple lines at once for combo bonuses!")
                                .sectionTextStyle(color: GameTheme.Colors.secondaryText)
                                .lineSpacing(6)
                        }
                        
                        // Game Over
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            Text("Game Over")
                                .sectionHeaderStyle()
                            
                            Text("The game ends when none of your current blocks can be placed on the grid. Plan ahead to keep playing longer!")
                                .sectionTextStyle(color: GameTheme.Colors.secondaryText)
                                .lineSpacing(6)
                        }
                        
                        // Pro Tips
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            Text("Pro Tips")
                                .sectionHeaderStyle()
                            
                            VStack(alignment: .leading, spacing: GameTheme.Layout.smallSpacing) {
                                TipRow(text: "Try to keep the grid as empty as possible")
                                TipRow(text: "Look for opportunities to clear multiple lines")
                                TipRow(text: "Don't rush - take time to find the best placement")
                                TipRow(text: "Focus on corners and edges when the grid gets full")
                                TipRow(text: "Plan ahead by considering all three available blocks")
                            }
                        }
                        
                    
                        // Scoring Section - Table Style
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            
                            VStack(spacing: 0) {
                                // Table Header
                                ScoringTableHeaderView()
                                
                                ScoringTableRowView(
                                    points: "10",
                                    description: "Placing blocks on the grid",
                                    color: GameTheme.Colors.blockBlue,
                                    isFirst: false
                                )
                                
                                ScoringTableRowView(
                                    points: "100",
                                    description: "Clearing complete lines",
                                    color: GameTheme.Colors.blockGreen,
                                    isFirst: false
                                )
                                
                                ScoringTableRowView(
                                    points: "+50",
                                    description: "Combo bonus for each additional line",
                                    color: GameTheme.Colors.blockOrange,
                                    isFirst: false
                                )
                            }
                            .background(
                                RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                                    .fill(GameTheme.Colors.cardBackground)
                            )
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
                                    description: "Smaller blocks appear more often",
                                    isFirst: false
                                )
                                
                                DifficultyTableRowView(
                                    mode: .moderate,
                                    description: "Balanced block distribution",
                                    isFirst: false
                                )
                                
                                DifficultyTableRowView(
                                    mode: .hard,
                                    description: "Larger, complex blocks are more common",
                                    isFirst: false
                                )
                            }
                            .background(
                                RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                                    .fill(GameTheme.Colors.cardBackground)
                            )
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
                                    description: "Standard blocks with various shapes and sizes (1-9 cells). Place them to fill the grid and clear lines.",
                                    isFirst: false
                                )
                                
                                ShapesTableRowView(
                                    shapeType: .horizontalClear,
                                    description: "Special red block that clears an entire horizontal row when placed. Worth 100 points.",
                                    isFirst: false
                                )
                                
                                ShapesTableRowView(
                                    shapeType: .verticalClear,
                                    description: "Special blue block that clears an entire vertical column when placed. Worth 100 points.",
                                    isFirst: false
                                )
                                
                                ShapesTableRowView(
                                    shapeType: .areaClear,
                                    description: "Special purple block that clears a 3×3 area around placement. Worth 200 points - the most powerful!",
                                    isFirst: false
                                )
                            }
                            .background(
                                RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                                    .fill(GameTheme.Colors.cardBackground)
                            )
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
