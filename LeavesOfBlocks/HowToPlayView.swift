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
                            .foregroundStyle(GameTheme.Gradients.text)
                            .padding(.top, GameTheme.Layout.mediumPadding)
                        
                        Text("Master the art of block placement!")
                            .font(GameTheme.Typography.captionFont)
                            .foregroundColor(GameTheme.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Content sections
                    VStack(spacing: GameTheme.Layout.sectionSpacing) {
                        // Game Rules
                        InstructionSection(
                            title: "The Grid",
                            content: "You have an 8×8 grid where you'll place block shapes. Fill complete rows or columns to clear them and earn points."
                        )
                        
                        InstructionSection(
                            title: "Drag & Drop",
                            content: "Drag block shapes from the bottom area onto the grid. Blocks must fit completely within the grid boundaries."
                        )
                        
                        InstructionSection(
                            title: "Clear Lines",
                            content: "Complete horizontal rows or vertical columns disappear, earning you 100 points per line. Clear multiple lines at once for combo bonuses!"
                        )
                    
                    // Scoring Section
                    VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                        Text("Scoring")
                            .font(GameTheme.Typography.headlineFont)
                            .foregroundColor(GameTheme.Colors.primaryText)
                        
                        VStack(alignment: .leading, spacing: GameTheme.Layout.smallSpacing) {
                            HStack(alignment: .top, spacing: 4) {
                                Text("•")
                                    .font(GameTheme.Typography.bodyFont)
                                    .foregroundColor(GameTheme.Colors.secondaryText)
                                Text("Placing blocks: ")
                                    .font(GameTheme.Typography.bodyFont)
                                    .foregroundColor(GameTheme.Colors.secondaryText) +
                                Text("10 points")
                                    .font(GameTheme.Typography.bodyFont)
                                    .fontWeight(.bold)
                                    .foregroundColor(GameTheme.Colors.accent) +
                                Text(" per cell")
                                    .font(GameTheme.Typography.bodyFont)
                                    .foregroundColor(GameTheme.Colors.secondaryText)
                            }
                            
                            HStack(alignment: .top, spacing: 4) {
                                Text("•")
                                    .font(GameTheme.Typography.bodyFont)
                                    .foregroundColor(GameTheme.Colors.secondaryText)
                                Text("Clearing lines: ")
                                    .font(GameTheme.Typography.bodyFont)
                                    .foregroundColor(GameTheme.Colors.secondaryText) +
                                Text("100 points")
                                    .font(GameTheme.Typography.bodyFont)
                                    .fontWeight(.bold)
                                    .foregroundColor(GameTheme.Colors.accent) +
                                Text(" per line")
                                    .font(GameTheme.Typography.bodyFont)
                                    .foregroundColor(GameTheme.Colors.secondaryText)
                            }
                            
                            HStack(alignment: .top, spacing: 4) {
                                Text("•")
                                    .font(GameTheme.Typography.bodyFont)
                                    .foregroundColor(GameTheme.Colors.secondaryText)
                                Text("Combo bonus: ")
                                    .font(GameTheme.Typography.bodyFont)
                                    .foregroundColor(GameTheme.Colors.secondaryText) +
                                Text("+50 points")
                                    .font(GameTheme.Typography.bodyFont)
                                    .fontWeight(.bold)
                                    .foregroundColor(GameTheme.Colors.accent) +
                                Text(" for each additional line cleared simultaneously")
                                    .font(GameTheme.Typography.bodyFont)
                                    .foregroundColor(GameTheme.Colors.secondaryText)
                            }
                        }
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
                    
                        InstructionSection(
                            title: "Game Over",
                            content: "The game ends when none of your current blocks can be placed on the grid. Plan ahead to keep playing longer!"
                        )
                        
                        InstructionSection(
                            title: "Difficulty Modes",
                            content: "• Easy: Smaller blocks appear more often\n• Moderate: Balanced block distribution\n• Hard: Larger, complex blocks are more common"
                        )
                        
                        // Tips Section
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                        Text("Pro Tips")
                            .font(GameTheme.Typography.headlineFont)
                            .foregroundColor(GameTheme.Colors.primaryText)
                        
                        VStack(alignment: .leading, spacing: GameTheme.Layout.smallSpacing) {
                            TipRow(text: "Try to keep the grid as empty as possible")
                            TipRow(text: "Look for opportunities to clear multiple lines")
                            TipRow(text: "Don't rush - take time to find the best placement")
                            TipRow(text: "Focus on corners and edges when the grid gets full")
                            TipRow(text: "Plan ahead by considering all three available blocks")
                        }
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
                .font(GameTheme.Typography.bodyFont)
                .foregroundColor(GameTheme.Colors.accent)
            
            Text(text)
                .font(GameTheme.Typography.bodyFont)
                .foregroundColor(GameTheme.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

#Preview {
    HowToPlayView()
}