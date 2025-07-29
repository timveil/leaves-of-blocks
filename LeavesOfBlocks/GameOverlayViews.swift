import SwiftUI

// MARK: - Game Over Overlay

struct GameOverOverlayView: View {
    @ObservedObject var gameState: GameState
    let onViewSummary: () -> Void
    @State private var buttonPressed = false
    @State private var trophyScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: GameTheme.Layout.largePadding) {
            // Header section with new high score celebration
            VStack(spacing: GameTheme.Layout.mediumSpacing) {
                if gameState.isNewHighScore {
                    VStack(spacing: GameTheme.Layout.smallSpacing) {
                        Text("🏆")
                            .font(.system(size: 40))
                            .scaleEffect(trophyScale)
                            .shadow(color: GameTheme.Colors.accent.opacity(0.6), radius: 8, x: 0, y: 4)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                                    trophyScale = 1.2
                                }
                            }
                            .onDisappear {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    trophyScale = 1.0
                                }
                            }
                        
                        Text("NEW HIGH SCORE!")
                            .font(GameTheme.Typography.titleFont)
                            .foregroundColor(GameTheme.Colors.accent)
                            .tracking(1.5)
                            .multilineTextAlignment(.center)
                            .shadow(color: GameTheme.Colors.accent.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .padding(.vertical, GameTheme.Layout.mediumPadding)
                    .frame(maxWidth: .infinity)
                    .background(
                        ZStack {
                            // 3D depth background layers
                            RoundedRectangle(cornerRadius: GameTheme.Layout.buttonCornerRadius)
                                .fill(GameTheme.Colors.accent.opacity(0.15))
                                .offset(x: 2, y: 2)
                            
                            RoundedRectangle(cornerRadius: GameTheme.Layout.buttonCornerRadius)
                                .fill(GameTheme.Colors.accent.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: GameTheme.Layout.buttonCornerRadius)
                                        .stroke(
                                            LinearGradient(
                                                colors: [GameTheme.Colors.accent.opacity(0.4), GameTheme.Colors.accent.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                        }
                    )
                }
                
                Text("Game Over")
                    .font(GameTheme.Typography.title)
                    .foregroundColor(GameTheme.Colors.primaryText)
                    .tracking(1)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
            
            // Score section with enhanced 3D effect
            VStack(spacing: GameTheme.Layout.mediumSpacing) {
                Text("Final Score")
                    .font(GameTheme.Typography.headlineFont)
                    .foregroundColor(GameTheme.Colors.secondaryText)
                    .tracking(1)
                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                
                Text("\(gameState.score)")
                    .font(GameTheme.Typography.largeScore)
                    .foregroundColor(GameTheme.Colors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .shadow(color: GameTheme.Colors.accent.opacity(0.4), radius: 6, x: 0, y: 3)
            }
            .padding(.vertical, GameTheme.Layout.largePadding)
            .padding(.horizontal, GameTheme.Layout.largePadding)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    // Multiple shadow layers for deep 3D effect
                    RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                        .fill(Color.black.opacity(0.1))
                        .offset(x: 4, y: 6)
                    
                    RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                        .fill(Color.black.opacity(0.05))
                        .offset(x: 2, y: 3)
                    
                    RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    GameTheme.Colors.cardBackground.opacity(0.9),
                                    GameTheme.Colors.cardBackground.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.2),
                                            Color.clear,
                                            Color.black.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                }
            )
            
            // Enhanced 3D button
            Button(action: onViewSummary) {
                HStack(spacing: GameTheme.Layout.smallSpacing) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 16, weight: .bold))
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                    
                    Text("View Summary")
                        .font(GameTheme.Typography.headlineFont)
                        .lineLimit(1)
                        .fixedSize()
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                }
                .foregroundColor(GameTheme.Colors.buttonText)
                .padding(.horizontal, GameTheme.Layout.largePadding)
                .padding(.vertical, GameTheme.Layout.mediumPadding)
                .background(
                    ZStack {
                        // Deep shadow layers for 3D effect
                        Capsule()
                            .fill(Color.black.opacity(0.2))
                            .offset(x: 0, y: 6)
                        
                        Capsule()
                            .fill(Color.black.opacity(0.1))
                            .offset(x: 0, y: 3)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        GameTheme.Colors.accent,
                                        GameTheme.Colors.accent.opacity(0.8),
                                        GameTheme.Colors.accent.opacity(0.6)
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
                            .shadow(color: GameTheme.Colors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                )
            }
            .scaleEffect(buttonPressed ? 0.95 : 1.0)
            .offset(y: buttonPressed ? 3 : 0)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    buttonPressed = pressing
                }
            }, perform: {})
        }
        .padding(.horizontal, GameTheme.Layout.largePadding)
        .padding(.vertical, GameTheme.Layout.extraLargePadding)
        .frame(maxWidth: 280) // Narrower width for iPhone visibility
        .background(
            ZStack {
                // Multiple shadow layers for deep dialog 3D effect
                RoundedRectangle(cornerRadius: GameTheme.Layout.overlayCornerRadius)
                    .fill(Color.black.opacity(0.15))
                    .offset(x: 0, y: 8)
                
                RoundedRectangle(cornerRadius: GameTheme.Layout.overlayCornerRadius)
                    .fill(Color.black.opacity(0.08))
                    .offset(x: 0, y: 4)
                
                RoundedRectangle(cornerRadius: GameTheme.Layout.overlayCornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                GameTheme.Colors.overlayBackground,
                                GameTheme.Colors.overlayBackground.opacity(0.95)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: GameTheme.Layout.overlayCornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        GameTheme.Colors.overlayBorderGradient[0],
                                        GameTheme.Colors.overlayBorderGradient[1],
                                        Color.black.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: GameTheme.Layout.strokeWidth
                            )
                    )
            }
        )
        .padding(.horizontal, 40) // Ensure borders are visible on iPhone
        .scaleEffect(1.0)
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Game Summary View

struct GameSummaryView: View {
    @ObservedObject var gameState: GameState
    let historicalSession: GameSession?
    @State private var highScoreScale: CGFloat = 1.0
    
    // Computed properties to use either current game or historical session
    private var score: Int {
        historicalSession?.score ?? gameState.score
    }
    
    private var blocksPlaced: Int {
        historicalSession?.blocksPlaced ?? gameState.blocksPlaced
    }
    
    private var linesCleared: Int {
        historicalSession?.linesCleared ?? gameState.linesCleared
    }
    
    private var gameTime: TimeInterval {
        historicalSession?.gameTime ?? gameState.currentGameTime
    }
    
    private var difficulty: DifficultyMode {
        historicalSession?.difficulty ?? gameState.currentDifficulty
    }
    
    private var isNewHighScore: Bool {
        if historicalSession != nil {
            return false // Historical sessions don't show new high score
        }
        return gameState.isNewHighScore
    }
    
    private var longestCombo: Int {
        // For historical sessions, we don't have combo data, so use 0
        historicalSession != nil ? 0 : gameState.longestCombo
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                GameBackgroundView()
                
                VStack(spacing: 0) {
                    // Header section
                    VStack(spacing: GameTheme.Layout.largeSpacing) {
                        if isNewHighScore {
                            Text("🏆 NEW HIGH SCORE! 🏆")
                                .font(GameTheme.Typography.titleFont)
                                .foregroundColor(GameTheme.Colors.accent)
                                .tracking(1.5)
                                .scaleEffect(highScoreScale)
                                .onAppear {
                                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                        highScoreScale = 1.1
                                    }
                                }
                                .onDisappear {
                                    highScoreScale = 1.0
                                }
                        }
                        
                        VStack(spacing: GameTheme.Layout.mediumSpacing) {
                            Text(historicalSession != nil ? "Past Game Summary" : "Game Summary")
                                .font(GameTheme.Typography.title)
                                .foregroundColor(GameTheme.Colors.primaryText)
                                .tracking(1)
                            
                            VStack(spacing: GameTheme.Layout.mediumSpacing) {
                                // Show date for historical sessions
                                if let session = historicalSession {
                                    Text(session.formattedDate)
                                        .font(GameTheme.Typography.captionFont)
                                        .foregroundColor(GameTheme.Colors.secondaryText)
                                }
                            }
                        }
                    }
                    .padding(.top, GameTheme.Layout.mediumPadding)
                    
                    Spacer(minLength: GameTheme.Layout.extraLargeSpacing)
                    
                    // Final Score - centered and prominent
                    VStack(spacing: GameTheme.Layout.smallSpacing) {
                        Text("Final Score")
                            .font(GameTheme.Typography.headlineFont)
                            .foregroundColor(GameTheme.Colors.accent)
                            .tracking(1)
                        
                        Text("\(score)")
                            .font(GameTheme.Typography.largeScore)
                            .foregroundColor(GameTheme.Colors.primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    
                    Spacer(minLength: GameTheme.Layout.extraLargeSpacing)
                    
                    // Statistics Cards - 2x3 grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: GameTheme.Layout.mediumSpacing) {
                        
                        StatisticCard(
                            title: "Time Played",
                            value: formatTime(gameTime),
                            icon: "clock.fill",
                            color: GameTheme.Colors.blockBlue
                        )
                        
                        StatisticCard(
                            title: "Blocks Placed",
                            value: "\(blocksPlaced)",
                            icon: "square.grid.3x3.fill",
                            color: GameTheme.Colors.blockGreen
                        )
                        
                        StatisticCard(
                            title: "Lines Cleared",
                            value: "\(linesCleared)",
                            icon: "line.horizontal.3",
                            color: GameTheme.Colors.blockRed
                        )
                        
                        StatisticCard(
                            title: "Longest Combo",
                            value: "\(longestCombo)",
                            icon: "flame.fill",
                            color: GameTheme.Colors.blockOrange
                        )
                        
                        StatisticCard(
                            title: "Difficulty",
                            value: difficulty.rawValue.capitalized,
                            icon: "target",
                            color: difficulty.color
                        )
                        
                        StatisticCard(
                            title: "Best Ever",
                            value: "\(gameState.highScoreManager.highScore)",
                            icon: "crown.fill",
                            color: GameTheme.Colors.accent
                        )
                    }
                    .padding(.horizontal, GameTheme.Layout.largePadding)
                    
                    
                    Spacer(minLength: GameTheme.Layout.extraLargeSpacing)
                    
                    
                    Spacer(minLength: GameTheme.Layout.extraLargeSpacing)
                    
                    // Grass always at bottom
                    BlockGrassView()
                        .ignoresSafeArea(.all, edges: .bottom)
                }
            }
        }
        .statusBarHidden()
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Statistic Card Component

struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: GameTheme.Layout.smallSpacing) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(GameTheme.Typography.titleFont)
                .foregroundColor(GameTheme.Colors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(title)
                .font(GameTheme.Typography.captionFont)
                .foregroundColor(GameTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(GameTheme.Layout.mediumPadding)
        .frame(maxWidth: .infinity, minHeight: 100, maxHeight: 100)
        .background(
            RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                .fill(GameTheme.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                        .stroke(color.opacity(0.3), lineWidth: 1.5)
                )
        )
        .shadow(color: GameTheme.Colors.cardShadow, radius: 6, x: 0, y: 3)
    }
}