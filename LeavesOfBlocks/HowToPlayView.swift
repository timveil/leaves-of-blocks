import SwiftUI

struct HowToPlayView: View {
    
    var body: some View {
        ZStack {
            GameBackgroundView()
            
            // Grass at bottom (lowest z-index)
            VStack {
                Spacer()
                BlockGrassView()
                    .ignoresSafeArea(.all, edges: .bottom)
            }
            .zIndex(0)
            
            // Content layer
            ScrollView {
                VStack(spacing: GameTheme.Layout.largePadding) {
                    // Header
                    VStack(spacing: GameTheme.Layout.mediumSpacing) {
                        Text("How to Play")
                            .font(GameTheme.Typography.title)
                            .foregroundColor(GameTheme.Colors.primaryText)
                            .padding(.top, GameTheme.Layout.mediumPadding)
                        
                        Text("Master the art of block placement!")
                            .font(GameTheme.Typography.captionFont)
                            .foregroundColor(GameTheme.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Content sections
                    VStack(alignment: .leading, spacing: GameTheme.Layout.largePadding) {
                        // The Grid
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            Text("The Grid")
                                .font(GameTheme.Typography.titleFont)
                                .foregroundColor(GameTheme.Colors.primaryText)
                            
                            Text("You have an 8×8 grid where you'll place block shapes. Fill complete rows or columns to clear them and earn points.")
                                .font(GameTheme.Typography.headlineFont)
                                .foregroundColor(GameTheme.Colors.secondaryText)
                                .lineSpacing(6)
                        }
                        
                        // Drag & Drop
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            Text("Drag & Drop")
                                .font(GameTheme.Typography.titleFont)
                                .foregroundColor(GameTheme.Colors.primaryText)
                            
                            Text("Drag block shapes from the bottom area onto the grid. Blocks must fit completely within the grid boundaries.")
                                .font(GameTheme.Typography.headlineFont)
                                .foregroundColor(GameTheme.Colors.secondaryText)
                                .lineSpacing(6)
                        }
                        
                        // Clear Lines
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            Text("Clear Lines")
                                .font(GameTheme.Typography.titleFont)
                                .foregroundColor(GameTheme.Colors.primaryText)
                            
                            Text("Complete horizontal rows or vertical columns disappear, earning you 100 points per line. Clear multiple lines at once for combo bonuses!")
                                .font(GameTheme.Typography.headlineFont)
                                .foregroundColor(GameTheme.Colors.secondaryText)
                                .lineSpacing(6)
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
                        
                        // Game Over
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            Text("Game Over")
                                .font(GameTheme.Typography.titleFont)
                                .foregroundColor(GameTheme.Colors.primaryText)
                            
                            Text("The game ends when none of your current blocks can be placed on the grid. Plan ahead to keep playing longer!")
                                .font(GameTheme.Typography.headlineFont)
                                .foregroundColor(GameTheme.Colors.secondaryText)
                                .lineSpacing(6)
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
                    }
                    
                    Spacer(minLength: GameTheme.Layout.extraLargePadding)
                }
                .padding(.horizontal, GameTheme.Layout.largePadding)
            }
            .zIndex(1)
            
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct InstructionSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
            Text(title)
                .font(GameTheme.Typography.headlineFont)
                .foregroundColor(GameTheme.Colors.primaryText)
            
            Text(content)
                .font(GameTheme.Typography.bodyFont)
                .foregroundColor(GameTheme.Colors.secondaryText)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GameTheme.Layout.largePadding)
        .background(
            RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                .fill(GameTheme.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: GameTheme.Colors.cardBorderGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(
                    color: GameTheme.Colors.cardShadow,
                    radius: GameTheme.Layout.shadowRadius,
                    x: 0,
                    y: GameTheme.Layout.shadowOffset
                )
        )
    }
}


struct TipRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: GameTheme.Layout.mediumSpacing) {
            Text("•")
                .font(GameTheme.Typography.headlineFont)
                .foregroundColor(GameTheme.Colors.accent)
            
            Text(text)
                .font(GameTheme.Typography.headlineFont)
                .foregroundColor(GameTheme.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

struct ScoringTableRowView: View {
    let points: String
    let description: String
    let color: Color
    let isFirst: Bool
    
    var body: some View {
        HStack(spacing: GameTheme.Layout.largePadding) {
            // Points column
            Text(points)
                .font(GameTheme.Typography.headlineFont)
                .fontWeight(.bold)
                .foregroundColor(color)
                .frame(width: 100, alignment: .leading)
            
            // Description column
            Text(description)
                .font(GameTheme.Typography.bodyFont)
                .foregroundColor(GameTheme.Colors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, GameTheme.Layout.largePadding)
        .padding(.vertical, GameTheme.Layout.mediumPadding)
        .background(color.opacity(0.05))
        .overlay(
            Rectangle()
                .frame(height: isFirst ? 0 : 1)
                .foregroundColor(GameTheme.Colors.gridBorder.opacity(0.2)),
            alignment: .top
        )
    }
}

struct ScoringTableHeaderView: View {
    var body: some View {
        HStack(spacing: GameTheme.Layout.largePadding) {
            // Points header
            Text("Points")
                .font(GameTheme.Typography.headlineFont)
                .fontWeight(.bold)
                .foregroundColor(GameTheme.Colors.primaryText)
                .frame(width: 100, alignment: .leading)
            
            // Description header
            Text("Description")
                .font(GameTheme.Typography.headlineFont)
                .fontWeight(.bold)
                .foregroundColor(GameTheme.Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, GameTheme.Layout.largePadding)
        .padding(.vertical, GameTheme.Layout.mediumPadding)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: GameTheme.Layout.cardCornerRadius,
                topTrailingRadius: GameTheme.Layout.cardCornerRadius
            )
            .fill(GameTheme.Colors.accent.opacity(0.15))
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(GameTheme.Colors.gridBorder.opacity(0.3)),
            alignment: .bottom
        )
    }
}

struct DifficultyTableHeaderView: View {
    var body: some View {
        HStack(spacing: GameTheme.Layout.largePadding) {
            // Mode header
            Text("Mode")
                .font(GameTheme.Typography.headlineFont)
                .fontWeight(.bold)
                .foregroundColor(GameTheme.Colors.primaryText)
                .frame(width: 100, alignment: .leading)
            
            // Description header
            Text("Description")
                .font(GameTheme.Typography.headlineFont)
                .fontWeight(.bold)
                .foregroundColor(GameTheme.Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, GameTheme.Layout.largePadding)
        .padding(.vertical, GameTheme.Layout.mediumPadding)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: GameTheme.Layout.cardCornerRadius,
                topTrailingRadius: GameTheme.Layout.cardCornerRadius
            )
            .fill(GameTheme.Colors.accent.opacity(0.15))
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(GameTheme.Colors.gridBorder.opacity(0.3)),
            alignment: .bottom
        )
    }
}

struct DifficultyTableRowView: View {
    let mode: DifficultyMode
    let description: String
    let isFirst: Bool
    
    var body: some View {
        HStack(spacing: GameTheme.Layout.largePadding) {
            // Mode icon and name column (home screen style)
            VStack(spacing: GameTheme.Layout.smallSpacing) {
                Image(systemName: mode.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(mode.color)
                    .frame(height: 30)
                
                Text(mode.rawValue.capitalized)
                    .font(GameTheme.Typography.captionFont)
                    .fontWeight(.medium)
                    .foregroundColor(GameTheme.Colors.primaryText)
            }
            .frame(width: 100, alignment: .center)
            
            // Description column
            Text(description)
                .font(GameTheme.Typography.bodyFont)
                .foregroundColor(GameTheme.Colors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, GameTheme.Layout.largePadding)
        .padding(.vertical, GameTheme.Layout.largePadding)
        .background(mode.color.opacity(0.05))
        .overlay(
            Rectangle()
                .frame(height: isFirst ? 0 : 1)
                .foregroundColor(GameTheme.Colors.gridBorder.opacity(0.2)),
            alignment: .top
        )
    }
}

#Preview {
    HowToPlayView()
}
