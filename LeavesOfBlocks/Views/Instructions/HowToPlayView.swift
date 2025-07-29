import SwiftUI

struct HowToPlayView: View {
    
    var body: some View {
        BaseScreenView {
            ScrollView {
                VStack(spacing: GameTheme.Layout.largePadding) {
                    // Header
                    VStack(spacing: GameTheme.Layout.mediumSpacing) {
                        Text("How to Play")
                            .gameTitleStyle()
                            .padding(.top, GameTheme.Layout.mediumPadding)
                        
                        Text("Master the art of block placement!")
                            .gameCaptionStyle()
                            .multilineTextAlignment(.center)
                    }
                    
                    // Content sections
                    VStack(alignment: .leading, spacing: GameTheme.Layout.largePadding) {
                        // The Grid
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            Text("The Grid")
                                .gameTitleStyle()
                            
                            Text("You have an 8×8 grid where you'll place block shapes. Fill complete rows or columns to clear them and earn points.")
                                .gameHeadlineStyle(color: GameTheme.Colors.secondaryText)
                                .lineSpacing(6)
                        }
                        
                        // Drag & Drop
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            Text("Drag & Drop")
                                .gameTitleStyle()
                            
                            Text("Drag block shapes from the bottom area onto the grid. Blocks must fit completely within the grid boundaries.")
                                .gameHeadlineStyle(color: GameTheme.Colors.secondaryText)
                                .lineSpacing(6)
                        }
                        
                        // Clear Lines
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            Text("Clear Lines")
                                .gameTitleStyle()
                            
                            Text("Complete horizontal rows or vertical columns disappear, earning you 100 points per line. Clear multiple lines at once for combo bonuses!")
                                .gameHeadlineStyle(color: GameTheme.Colors.secondaryText)
                                .lineSpacing(6)
                        }
                        
                        // Game Over
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            Text("Game Over")
                                .gameTitleStyle()
                            
                            Text("The game ends when none of your current blocks can be placed on the grid. Plan ahead to keep playing longer!")
                                .gameHeadlineStyle(color: GameTheme.Colors.secondaryText)
                                .lineSpacing(6)
                        }
                        
                        // Pro Tips
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            Text("Pro Tips")
                                .font(GameTheme.Typography.titleFont)
                                .foregroundColor(GameTheme.Colors.primaryText)
                            
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
                            Text("Scoring")
                                .font(GameTheme.Typography.titleFont)
                                .foregroundColor(GameTheme.Colors.primaryText)
                            
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
                            Text("Difficulty Modes")
                                .font(GameTheme.Typography.titleFont)
                                .foregroundColor(GameTheme.Colors.primaryText)
                            
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
                        
                    }
                    
                    Spacer(minLength: GameTheme.Layout.extraLargePadding)
                }
                .padding(.horizontal, GameTheme.Layout.largePadding)
                .padding(.bottom, 80)
            }
        }
    }
}

#Preview {
    HowToPlayView()
}
