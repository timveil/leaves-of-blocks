import SwiftUI

// MARK: - Difficulty Selection Component

struct DifficultySelectionView: View {
    @Binding var selectedDifficulty: DifficultyMode
    let onStartGame: (DifficultyMode) -> Void
    
    var body: some View {
        VStack(spacing: GameTheme.Layout.extraLargeSpacing) {
            Text("Select Difficulty")
                .font(GameTheme.Typography.titleFont)
                .foregroundColor(GameTheme.Colors.primaryText)
                .tracking(0.5)
            
            // Horizontal difficulty buttons
            HStack(spacing: GameTheme.Layout.mediumSpacing) {
                ForEach(DifficultyMode.allCases, id: \.self) { difficulty in
                    CompactDifficultyButton(
                        difficulty: difficulty,
                        isSelected: selectedDifficulty == difficulty,
                        onTap: {
                            selectedDifficulty = difficulty
                        }
                    )
                }
            }
            .padding(.horizontal, GameTheme.Layout.smallPadding)
            
            Button(action: {
                onStartGame(selectedDifficulty)
            }) {
                HStack {
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .bold))
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                    
                    Text("Start Game")
                        .font(GameTheme.Typography.titleFont)
                        .tracking(0.5)
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                }
                .foregroundColor(GameTheme.Colors.buttonText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, GameTheme.Layout.largePadding)
                .background(
                    ZStack {
                        // Deep shadow layers for 3D effect
                        Capsule()
                            .fill(Color.black.opacity(0.15))
                            .offset(x: 0, y: 6)
                        
                        Capsule()
                            .fill(Color.black.opacity(0.08))
                            .offset(x: 0, y: 3)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        GameTheme.Colors.buttonGradient[0],
                                        GameTheme.Colors.buttonGradient[1],
                                        GameTheme.Colors.buttonGradient[1].opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.3),
                                                Color.clear,
                                                Color.black.opacity(0.2)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: GameTheme.Colors.buttonGradient[0].opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                )
            }
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 0.3), value: selectedDifficulty)
        }
        .padding(.horizontal, GameTheme.Layout.mediumPadding)
    }
}

struct CompactDifficultyButton: View {
    let difficulty: DifficultyMode
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: GameTheme.Layout.smallSpacing) {
                Image(systemName: difficulty.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(difficulty.color)
                
                Text(difficulty.rawValue)
                    .font(.system(size: 12, weight: .semibold, design: .default))
                    .foregroundColor(GameTheme.Colors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .fixedSize()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, GameTheme.Layout.largePadding)
            .padding(.horizontal, GameTheme.Layout.smallPadding)
            .background(
                RoundedRectangle(cornerRadius: GameTheme.Layout.buttonCornerRadius)
                    .fill(isSelected ? difficulty.color.opacity(0.2) : GameTheme.Colors.containerBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: GameTheme.Layout.buttonCornerRadius)
                            .stroke(
                                isSelected ? difficulty.color.opacity(0.6) : GameTheme.Colors.containerBorder,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct DifficultyButton: View {
    let difficulty: DifficultyMode
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: GameTheme.Layout.mediumSpacing) {
                Image(systemName: difficulty.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(difficulty.color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(difficulty.rawValue)
                        .font(GameTheme.Typography.headlineFont)
                        .foregroundColor(GameTheme.Colors.primaryText)
                    
                    Text(difficulty.description)
                        .font(GameTheme.Typography.captionFont)
                        .foregroundColor(GameTheme.Colors.secondaryText)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(GameTheme.Colors.accent)
                }
            }
            .padding(GameTheme.Layout.mediumPadding)
            .background(
                RoundedRectangle(cornerRadius: GameTheme.Layout.buttonCornerRadius)
                    .fill(isSelected ? difficulty.color.opacity(0.1) : GameTheme.Colors.containerBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: GameTheme.Layout.buttonCornerRadius)
                            .stroke(
                                isSelected ? difficulty.color.opacity(0.5) : GameTheme.Colors.containerBorder,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Game Home View

struct GameHomeView: View {
    @ObservedObject var gameState: GameState
    let onStartGame: (DifficultyMode) -> Void
    let onShowHistory: () -> Void
    
    @State private var selectedDifficulty: DifficultyMode = .moderate
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                GameBackgroundView()
                
                VStack(spacing: 0) {
                    // Main content area
                    VStack(spacing: GameTheme.Layout.extraLargeSpacing) {
                        Spacer(minLength: 60)
                        
                        // High Score Display - Now tappable for history
                        Button(action: onShowHistory) {
                            VStack(spacing: GameTheme.Layout.mediumSpacing) {
                                Text("Best Score")
                                    .font(GameTheme.Typography.titleFont)
                                    .foregroundColor(GameTheme.Colors.accent)
                                
                                Text("\(gameState.highScoreManager.highScore)")
                                    .font(GameTheme.Typography.largeScore)
                                    .foregroundColor(GameTheme.Colors.primaryText)
                                    
                                // Last played info if available
                                if gameState.score > 0 {
                                    Text("Last Score: \(gameState.score)")
                                        .font(GameTheme.Typography.captionFont)
                                        .foregroundColor(GameTheme.Colors.secondaryText)
                                }
                                
                                Text("Tap for History")
                                    .font(GameTheme.Typography.captionFont)
                                    .foregroundColor(GameTheme.Colors.accent.opacity(0.7))
                            }
                            .padding(.horizontal, GameTheme.Layout.extraLargePadding)
                            .padding(.vertical, GameTheme.Layout.extraLargePadding)
                            .background(
                                RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                                    .fill(GameTheme.Colors.cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                                            .stroke(GameTheme.Colors.accent.opacity(0.3), lineWidth: 2)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer(minLength: 20)
                        
                        // Difficulty Selection
                        DifficultySelectionView(
                            selectedDifficulty: $selectedDifficulty,
                            onStartGame: onStartGame
                        )
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, GameTheme.Layout.extraLargePadding)
                    .padding(.top, GameTheme.Layout.extraLargePadding)
                    
                    // Grass always at bottom
                    BlockGrassView()
                        .ignoresSafeArea(.all, edges: .bottom)
                }
                
            }
        }
        .statusBarHidden()
    }
}