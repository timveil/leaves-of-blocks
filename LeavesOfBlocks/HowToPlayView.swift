import SwiftUI

struct HowToPlayView: View {
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            GameBackgroundView()
            
            ScrollView {
                VStack(spacing: GameTheme.Layout.extraLargeSpacing) {
                    // Header
                    VStack(spacing: GameTheme.Layout.mediumSpacing) {
                        Text("How to Play")
                            .font(GameTheme.Typography.title)
                            .foregroundColor(GameTheme.Colors.primaryText)
                        
                        Text("Master the art of block placement!")
                            .font(GameTheme.Typography.bodyFont)
                            .foregroundColor(GameTheme.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, GameTheme.Layout.extraLargePadding)
                    
                    // Game Rules
                    InstructionCard(
                        icon: "square.grid.3x3",
                        title: "The Grid",
                        content: "You have an 8×8 grid where you'll place block shapes. Fill complete rows or columns to clear them and earn points."
                    )
                    
                    InstructionCard(
                        icon: "hand.draw",
                        title: "Drag & Drop",
                        content: "Drag block shapes from the bottom area onto the grid. Blocks must fit completely within the grid boundaries."
                    )
                    
                    InstructionCard(
                        icon: "line.horizontal.3",
                        title: "Clear Lines",
                        content: "Complete horizontal rows or vertical columns disappear, earning you 100 points per line. Clear multiple lines at once for combo bonuses!"
                    )
                    
                    // Scoring Card with Bold Points
                    HStack(alignment: .top, spacing: GameTheme.Layout.largePadding) {
                        // Icon
                        Image(systemName: "trophy")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(GameTheme.Colors.accent)
                            .frame(width: 32, height: 32)
                        
                        // Content
                        VStack(alignment: .leading, spacing: GameTheme.Layout.smallSpacing) {
                            Text("Scoring")
                                .font(GameTheme.Typography.titleFont)
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
                        
                        Spacer()
                    }
                    .padding(GameTheme.Layout.extraLargePadding)
                    .background(
                        RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                            .fill(GameTheme.Colors.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                                    .stroke(GameTheme.Colors.gridBorder.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .shadow(
                        color: GameTheme.Colors.cardShadow,
                        radius: 4,
                        x: 0,
                        y: 2
                    )
                    
                    InstructionCard(
                        icon: "gamecontroller",
                        title: "Game Over",
                        content: "The game ends when none of your current blocks can be placed on the grid. Plan ahead to keep playing longer!"
                    )
                    
                    InstructionCard(
                        icon: "slider.horizontal.3",
                        title: "Difficulty Modes",
                        content: "• Easy: Smaller blocks appear more often\n• Moderate: Balanced block distribution\n• Hard: Larger, complex blocks are more common"
                    )
                    
                    // Tips Section
                    VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                        Text("💡 Pro Tips")
                            .font(GameTheme.Typography.titleFont)
                            .foregroundColor(GameTheme.Colors.accent)
                        
                        VStack(alignment: .leading, spacing: GameTheme.Layout.smallSpacing) {
                            TipRow(text: "Try to keep the grid as empty as possible")
                            TipRow(text: "Look for opportunities to clear multiple lines")
                            TipRow(text: "Don't rush - take time to find the best placement")
                            TipRow(text: "Focus on corners and edges when the grid gets full")
                            TipRow(text: "Plan ahead by considering all three available blocks")
                        }
                    }
                    .padding(GameTheme.Layout.extraLargePadding)
                    .background(
                        RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                            .fill(GameTheme.Colors.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                                    .stroke(GameTheme.Colors.accent.opacity(0.3), lineWidth: 2)
                            )
                    )
                    
                    // Ready to Play Button
                    Button(action: onDismiss) {
                        HStack {
                            Image(systemName: "play.fill")
                                .font(.system(size: 18, weight: .bold))
                            Text("Ready to Play!")
                                .font(GameTheme.Typography.bodyFont)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(GameTheme.Colors.buttonText)
                        .padding(.horizontal, GameTheme.Layout.extraLargePadding)
                        .padding(.vertical, GameTheme.Layout.largePadding)
                        .background(
                            LinearGradient(
                                colors: GameTheme.Colors.buttonGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(GameTheme.Layout.buttonCornerRadius)
                        .shadow(
                            color: GameTheme.Colors.cardShadow,
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    }
                    .padding(.bottom, GameTheme.Layout.extraLargePadding)
                }
                .padding(.horizontal, GameTheme.Layout.extraLargePadding)
            }
            
            // Close button overlay - top right
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(GameTheme.Colors.primaryText)
                            .background(
                                Circle()
                                    .fill(GameTheme.Colors.primaryBackground.opacity(0.7))
                                    .frame(width: 44, height: 44)
                            )
                    }
                    .padding(.trailing, GameTheme.Layout.largePadding)
                    .padding(.top, GameTheme.Layout.mediumPadding)
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(.container, edges: [])
    }
}

struct InstructionCard: View {
    let icon: String
    let title: String
    let content: String
    
    var body: some View {
        HStack(alignment: .top, spacing: GameTheme.Layout.largePadding) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(GameTheme.Colors.accent)
                .frame(width: 32, height: 32)
            
            // Content
            VStack(alignment: .leading, spacing: GameTheme.Layout.smallSpacing) {
                Text(title)
                    .font(GameTheme.Typography.titleFont)
                    .foregroundColor(GameTheme.Colors.primaryText)
                
                Text(content)
                    .font(GameTheme.Typography.bodyFont)
                    .foregroundColor(GameTheme.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(GameTheme.Layout.extraLargePadding)
        .background(
            RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                .fill(GameTheme.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                        .stroke(GameTheme.Colors.gridBorder.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(
            color: GameTheme.Colors.cardShadow,
            radius: 4,
            x: 0,
            y: 2
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
    HowToPlayView(onDismiss: {})
}