import SwiftUI

extension BlockColor {
    var color: Color {
        switch self {
        case .blue: return GameTheme.Colors.blockBlue
        case .green: return GameTheme.Colors.blockGreen
        case .red: return GameTheme.Colors.blockRed
        case .yellow: return GameTheme.Colors.blockYellow
        case .purple: return GameTheme.Colors.blockPurple
        case .orange: return GameTheme.Colors.blockOrange
        case .pink: return GameTheme.Colors.blockPink
        }
    }
}

struct SimpleAppTitleView: View {
    var body: some View {
        Text("🍂 Leaves of Blocks")
            .font(GameTheme.Typography.title)
            .foregroundColor(GameTheme.Colors.primaryText)
            .padding(.vertical, GameTheme.Layout.smallPadding)
    }
}

struct SimpleScoreView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: GameTheme.Layout.smallSpacing) {
            HStack {
                // Current Score
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(gameState.score)")
                        .font(GameTheme.Typography.largeScore)
                        .foregroundColor(GameTheme.Colors.primaryText)
                    Text("Score")
                        .font(GameTheme.Typography.captionFont)
                        .foregroundColor(GameTheme.Colors.secondaryText)
                }
                
                Spacer()
                
                // Lines Cleared Counter
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(gameState.linesCleared)")
                        .font(GameTheme.Typography.largeScore)
                        .foregroundColor(GameTheme.Colors.accent)
                    Text("Lines")
                        .font(GameTheme.Typography.captionFont)
                        .foregroundColor(GameTheme.Colors.secondaryText)
                }
            }
        }
        .padding(.horizontal, GameTheme.Layout.extraLargePadding)
        .padding(.vertical, GameTheme.Layout.mediumPadding)
    }
}

// MARK: - Background Components

struct GameBackgroundView: View {
    var body: some View {
        ZStack {
            // Autumn forest background
            LinearGradient(
                colors: GameTheme.Colors.backgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle leaf pattern overlay
            Rectangle()
                .fill(
                    RadialGradient(
                        colors: [
                            GameTheme.Colors.overlayPrimary,
                            Color.clear,
                            GameTheme.Colors.overlaySecondary
                        ],
                        center: .topTrailing,
                        startRadius: 50,
                        endRadius: 400
                    )
                )
                .ignoresSafeArea()
        }
    }
}

// MARK: - Grid Components

struct GameGridView: View {
    @ObservedObject var gameState: GameState
    let cellSize: CGFloat
    let draggedBlock: BlockShape?
    let previewPosition: GridPosition?
    let onGridFrameChange: (CGRect) -> Void
    
    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 3) {
                ForEach(0..<GameState.gridSize, id: \.self) { row in
                    HStack(spacing: 3) {
                        ForEach(0..<GameState.gridSize, id: \.self) { col in
                            GridCellView(
                                cell: gameState.grid[row][col],
                                size: cellSize,
                                isPreview: isPreviewCell(row: row, col: col),
                                previewColor: draggedBlock?.color.color ?? .clear,
                                isLineComplete: isLineCompleteCell(row: row, col: col)
                            )
                        }
                    }
                }
            }
            .padding(GameTheme.Layout.mediumPadding)
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
                                lineWidth: GameTheme.Layout.strokeWidth
                            )
                    )
                    .shadow(color: GameTheme.Colors.cardShadow, radius: GameTheme.Layout.shadowRadius, x: 0, y: GameTheme.Layout.shadowOffset)
            )
            .background(
                GeometryReader { geo in
                    Color.clear.onAppear {
                        onGridFrameChange(geo.frame(in: .global))
                    }
                }
            )
            Spacer()
        }
    }
    
    private func isPreviewCell(row: Int, col: Int) -> Bool {
        guard let previewPos = previewPosition,
              let draggedBlock = draggedBlock else { return false }
        
        // Only show preview if the block can be placed at this position
        guard gameState.canPlaceBlock(draggedBlock, at: previewPos) else { return false }
        
        // Check if this grid cell matches any block position
        for blockPos in draggedBlock.positions {
            let finalRow = previewPos.row + blockPos.row
            let finalCol = previewPos.col + blockPos.col
            if finalRow == row && finalCol == col {
                return true
            }
        }
        return false
    }
    
    private func isLineCompleteCell(row: Int, col: Int) -> Bool {
        guard let previewPos = previewPosition,
              let draggedBlock = draggedBlock,
              gameState.canPlaceBlock(draggedBlock, at: previewPos) else { return false }
        
        // Get the lines that would be completed with this placement
        let completedLines = getCompletedLinesForPreview()
        
        // Check if this cell is in any completed row or column
        return completedLines.rows.contains(row) || completedLines.cols.contains(col)
    }
    
    private func getCompletedLinesForPreview() -> (rows: Set<Int>, cols: Set<Int>) {
        guard let previewPos = previewPosition,
              let draggedBlock = draggedBlock,
              gameState.canPlaceBlock(draggedBlock, at: previewPos) else { 
            return (rows: Set<Int>(), cols: Set<Int>()) 
        }
        
        // Create a temporary grid state to check line completion
        var tempGrid = gameState.grid
        
        // Place the block temporarily
        for blockPos in draggedBlock.positions {
            let finalRow = previewPos.row + blockPos.row
            let finalCol = previewPos.col + blockPos.col
            if finalRow >= 0 && finalRow < GameState.gridSize && 
               finalCol >= 0 && finalCol < GameState.gridSize {
                tempGrid[finalRow][finalCol].isFilled = true
            }
        }
        
        var completedRows: Set<Int> = []
        var completedCols: Set<Int> = []
        
        // Check all rows for completion
        for row in 0..<GameState.gridSize {
            if tempGrid[row].allSatisfy({ $0.isFilled }) {
                completedRows.insert(row)
            }
        }
        
        // Check all columns for completion
        for col in 0..<GameState.gridSize {
            if (0..<GameState.gridSize).allSatisfy({ tempGrid[$0][col].isFilled }) {
                completedCols.insert(col)
            }
        }
        
        return (rows: completedRows, cols: completedCols)
    }
}

// MARK: - Current Blocks Components

struct CurrentBlocksView: View {
    @ObservedObject var gameState: GameState
    let cellSize: CGFloat
    let draggedBlock: BlockShape?
    let isDragging: Bool
    let draggedBlockIndex: Int?
    let isHoveringOverOrigin: Bool
    let onDragStart: (BlockShape, Int, CGPoint) -> Void  // Added index parameter
    let onDragMove: (CGPoint) -> Void
    let onDragEnd: () -> Void
    
    // Fixed dimensions to prevent layout shifts
    private let containerHeight: CGFloat = 90 // Reduced height for more compact layout
    private var gridWidth: CGFloat {
        // Match the game grid width: (8 cells * 40px) + (7 spacings * 4px) + (2 * 12px padding)
        return (8 * cellSize) + (7 * 4) + (2 * 12)
    }
    private var slotWidth: CGFloat {
        // Divide available width by 3 blocks, accounting for spacing
        return (gridWidth - (2 * GameTheme.Layout.largePadding) - (2 * GameTheme.Layout.mediumSpacing)) / 3
    }
    
    var body: some View {
        HStack(spacing: GameTheme.Layout.mediumSpacing) {
            ForEach(Array(gameState.currentBlocks.enumerated()), id: \.offset) { index, block in
                // Fixed-size slot for each block
                ZStack {
                    // Background for the slot - highlight if hovering over origin
                    RoundedRectangle(cornerRadius: GameTheme.Layout.buttonCornerRadius)
                        .fill(
                            (isHoveringOverOrigin && draggedBlockIndex == index) ?
                            GameTheme.Colors.accent.opacity(0.3) :
                            GameTheme.Colors.blockContainerBackground
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: GameTheme.Layout.buttonCornerRadius)
                                .stroke(
                                    (isHoveringOverOrigin && draggedBlockIndex == index) ?
                                    GameTheme.Colors.accent :
                                    GameTheme.Colors.blockContainerBorder,
                                    lineWidth: (isHoveringOverOrigin && draggedBlockIndex == index) ? 2 : 1
                                )
                        )
                        .shadow(
                            color: (isHoveringOverOrigin && draggedBlockIndex == index) ?
                                GameTheme.Colors.accent.opacity(0.4) :
                                GameTheme.Colors.blockContainerShadow,
                            radius: (isHoveringOverOrigin && draggedBlockIndex == index) ? 8 : 6,
                            x: 2,
                            y: 3
                        )
                        .scaleEffect((isHoveringOverOrigin && draggedBlockIndex == index) ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isHoveringOverOrigin && draggedBlockIndex == index)
                    
                    // Scaled block centered in slot - size stays consistent
                    DraggableBlockView(
                        block: block,
                        cellSize: scaledCellSize(for: block),
                        onDragStart: { location, startLocation in
                            onDragStart(block, index, location)  // Pass index
                        },
                        onDragMove: onDragMove,
                        onDragEnd: onDragEnd
                    )
                }
                .frame(width: slotWidth, height: containerHeight)
            }
        }
        .frame(width: gridWidth, height: containerHeight + (2 * GameTheme.Layout.smallPadding))
        .padding(.horizontal, GameTheme.Layout.largePadding)
        .padding(.vertical, GameTheme.Layout.smallPadding)
        .background(
            RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                .fill(GameTheme.Colors.containerBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                        .stroke(GameTheme.Colors.containerBorder, lineWidth: 1)
                )
                .shadow(color: GameTheme.Colors.containerShadow, radius: 8, x: 0, y: 4)
        )
    }
    
    // Calculate optimal cell size for each block to fit in its slot
    private func scaledCellSize(for block: BlockShape) -> CGFloat {
        let minRow = block.positions.map(\.row).min() ?? 0
        let maxRow = block.positions.map(\.row).max() ?? 0
        let minCol = block.positions.map(\.col).min() ?? 0
        let maxCol = block.positions.map(\.col).max() ?? 0
        
        let blockWidth = CGFloat(maxCol - minCol + 1)
        let blockHeight = CGFloat(maxRow - minRow + 1)
        
        // Calculate scale to fit within slot, leaving some padding
        let availableWidth = slotWidth * 0.8 // 80% of slot width for padding
        let availableHeight = containerHeight * 0.8 // 80% of slot height for padding
        
        let scaleForWidth = availableWidth / (blockWidth * cellSize)
        let scaleForHeight = availableHeight / (blockHeight * cellSize)
        
        // Use the smaller scale to ensure block fits in both dimensions
        let scale = min(scaleForWidth, scaleForHeight, 1.0) // Don't scale up, only down
        
        return cellSize * scale
    }
}

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
        historicalSession?.gameTime ?? gameState.gameTime
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

// MARK: - Game Toolbar Component

struct GameToolbarView: View {
    let onReset: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            
            // Reset Button
            Button(action: onReset) {
                HStack(spacing: GameTheme.Layout.smallSpacing) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18, weight: .bold))
                    Text("New Game")
                        .font(GameTheme.Typography.bodyFont)
                        .fontWeight(.semibold)
                }
                .foregroundColor(GameTheme.Colors.buttonText)
                .padding(.horizontal, GameTheme.Layout.largePadding)
                .padding(.vertical, GameTheme.Layout.mediumPadding)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    GameTheme.Colors.error,
                                    GameTheme.Colors.error.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: GameTheme.Colors.error.opacity(0.3), radius: 4, x: 0, y: 2)
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, GameTheme.Layout.largePadding)
        .padding(.vertical, GameTheme.Layout.smallPadding)
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

// MARK: - Main Game Board

struct GameBoardView: View {
    @ObservedObject var gameState: GameState
    @State private var draggedBlock: BlockShape?
    @State private var draggedBlockIndex: Int?  // Track which slot the block came from
    @State private var previewPosition: GridPosition?
    @State private var dragLocation: CGPoint = .zero
    @State private var isDragging: Bool = false
    @State private var gridFrame: CGRect = .zero
    @State private var blockSlotsFrame: CGRect = .zero  // Track the holding area frame
    @State private var isHoveringOverOrigin: Bool = false  // Track if hovering over original slot
    
    // Constants for consistent positioning
    private let dragOffsetY: CGFloat = 80 // Distance above finger
    
    let cellSize: CGFloat = 40
    let onViewSummary: () -> Void
    
    var body: some View {
        ZStack {
            GameBackgroundView()
            
            
            VStack(spacing: GameTheme.Layout.smallSpacing) {
                // Score Section
                SimpleScoreView(gameState: gameState)
                
                // Game Grid
                GameGridView(
                    gameState: gameState,
                    cellSize: cellSize,
                    draggedBlock: draggedBlock,
                    previewPosition: previewPosition,
                    onGridFrameChange: { frame in
                        gridFrame = frame
                    }
                )
                
                Spacer()
                
                // Current Blocks
                CurrentBlocksView(
                    gameState: gameState,
                    cellSize: cellSize,
                    draggedBlock: draggedBlock,
                    isDragging: isDragging,
                    draggedBlockIndex: draggedBlockIndex,
                    isHoveringOverOrigin: isHoveringOverOrigin,
                    onDragStart: { block, index, location in
                        draggedBlock = block
                        draggedBlockIndex = index  // Remember which slot it came from
                        isDragging = true
                        dragLocation = location
                    },
                    onDragMove: { location in
                        dragLocation = location
                        
                        // Check if hovering over the original slot
                        if let index = draggedBlockIndex {
                            isHoveringOverOrigin = isBlockOverOriginalSlot(location: location, slotIndex: index)
                        }
                        
                        // Calculate preview position based on the dragged block's position
                        if let block = draggedBlock {
                            let blockCenterLocation = CGPoint(
                                x: location.x,
                                y: location.y - dragOffsetY
                            )
                            
                            // Calculate the block's dimensions relative to its anchor point (0,0)
                            let minRow = block.positions.map(\.row).min() ?? 0
                            let minCol = block.positions.map(\.col).min() ?? 0
                            
                            let blockWidth = CGFloat((block.positions.map(\.col).max() ?? 0) - minCol + 1) * cellSize
                            let blockHeight = CGFloat((block.positions.map(\.row).max() ?? 0) - minRow + 1) * cellSize
                            
                            // Calculate where the block's anchor point (0,0) would be placed
                            let anchorLocation = CGPoint(
                                x: blockCenterLocation.x - blockWidth/2 + CGFloat(minCol) * cellSize,
                                y: blockCenterLocation.y - blockHeight/2 + CGFloat(minRow) * cellSize
                            )
                            
                            // Only update preview position if not hovering over origin
                            if !isHoveringOverOrigin {
                                updatePreviewPosition(for: anchorLocation)
                            } else {
                                previewPosition = nil  // Clear preview when hovering over origin
                            }
                        }
                    },
                    onDragEnd: {
                        // Check if we're dropping back to the original slot
                        if isHoveringOverOrigin {
                            // Just cancel the drag - block stays in its original position
                            draggedBlock = nil
                            draggedBlockIndex = nil
                            previewPosition = nil
                            isDragging = false
                            isHoveringOverOrigin = false
                        } else if let block = draggedBlock,
                                  let previewPos = previewPosition,
                                  gameState.canPlaceBlock(block, at: previewPos) {
                            // Try to place the block on the grid
                            gameState.placeBlock(block, at: previewPos)
                            draggedBlock = nil
                            draggedBlockIndex = nil
                            previewPosition = nil
                            isDragging = false
                            isHoveringOverOrigin = false
                        } else {
                            // Invalid placement - cancel the drag
                            draggedBlock = nil
                            draggedBlockIndex = nil
                            previewPosition = nil
                            isDragging = false
                            isHoveringOverOrigin = false
                        }
                    }
                )
                .background(
                    GeometryReader { geo in
                        Color.clear.onAppear {
                            blockSlotsFrame = geo.frame(in: .global)
                        }
                    }
                )
                
                // Game Toolbar below the shape holding area
                GameToolbarView(
                    onReset: {
                        withAnimation(GameTheme.Animations.springAnimation) {
                            gameState.resetGame()
                        }
                    }
                )
                
                // Static grass foundation - always visible
                BlockGrassView()
                    .ignoresSafeArea(.all, edges: .bottom)
            }
            .zIndex(10) // Game elements above grass
            .padding(.horizontal, GameTheme.Layout.largePadding)
            
            // Game Over Overlay - highest priority, appears above everything
            if gameState.isGameOver {
                ZStack {
                    // Semi-transparent background to dim the game
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    
                    GameOverOverlayView(
                        gameState: gameState,
                        onViewSummary: onViewSummary
                    )
                }
                .zIndex(2000) // Higher than dragged blocks
            }
        
        // Dragged block following finger - positioned above finger for better visibility
        if let draggedBlock = draggedBlock, isDragging {
            BlockView(block: draggedBlock, cellSize: cellSize)
                .position(
                    x: dragLocation.x,
                    y: dragLocation.y - dragOffsetY  // Position block above finger
                )
                .allowsHitTesting(false)
                .zIndex(1000)
                .scaleEffect(1.1) // Slightly larger during drag for better visibility
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        }
        .statusBarHidden() // Hide status bar for immersive gaming experience
    }
    
    // MARK: - Helper Methods
    
    private func isBlockOverOriginalSlot(location: CGPoint, slotIndex: Int) -> Bool {
        // Check if the current drag location is within the bounds of the original slot
        guard slotIndex >= 0 && slotIndex < 3 else { return false }
        
        // Calculate slot dimensions based on the CurrentBlocksView layout
        let containerHeight: CGFloat = 90
        let gridWidth = (8 * cellSize) + (7 * 4) + (2 * 12)
        let slotWidth = (gridWidth - (2 * GameTheme.Layout.largePadding) - (2 * GameTheme.Layout.mediumSpacing)) / 3
        
        // Calculate the x position of the slot
        let slotX = blockSlotsFrame.minX + GameTheme.Layout.largePadding + CGFloat(slotIndex) * (slotWidth + GameTheme.Layout.mediumSpacing)
        let slotY = blockSlotsFrame.minY
        
        // Check if the drag location (adjusted for finger offset) is within the slot bounds
        let adjustedLocation = CGPoint(x: location.x, y: location.y - dragOffsetY)
        
        return adjustedLocation.x >= slotX &&
               adjustedLocation.x <= slotX + slotWidth &&
               adjustedLocation.y >= slotY &&
               adjustedLocation.y <= slotY + containerHeight
    }
    
    private func getGridPosition(from location: CGPoint, in size: CGSize) -> GridPosition {
        // Account for the grid's internal padding (mediumPadding = 16)
        let adjustedX = location.x - 16  // GameTheme.Layout.mediumPadding
        let adjustedY = location.y - 16  // GameTheme.Layout.mediumPadding
        
        // Each cell is cellSize + 3 points spacing (except the last one)
        let cellSpacing: CGFloat = 3
        let cellWithSpacing = cellSize + cellSpacing
        
        let col = Int(adjustedX / cellWithSpacing)
        let row = Int(adjustedY / cellWithSpacing)
        
        // Don't clamp to grid bounds - allow negative/out-of-bounds positions for proper edge detection
        return GridPosition(row: row, col: col)
    }
    
    private func updatePreviewPosition(for globalLocation: CGPoint) {
        guard let draggedBlock = draggedBlock else {
            previewPosition = nil
            return
        }
        
        // Convert global coordinates to grid-relative coordinates
        let relativeLocation = CGPoint(
            x: globalLocation.x - gridFrame.minX,
            y: globalLocation.y - gridFrame.minY
        )
        
        // Find the best fit position for the block
        if let bestFit = findBestFitPosition(for: draggedBlock, near: relativeLocation) {
            previewPosition = bestFit
        } else {
            previewPosition = nil
        }
    }
    
    private func findBestFitPosition(for block: BlockShape, near targetLocation: CGPoint) -> GridPosition? {
        var bestPosition: GridPosition?
        var bestDistanceSquared: CGFloat = CGFloat.greatestFiniteMagnitude
        let maxSnapDistanceSquared: CGFloat = 300 * 300 // Maximum snap distance squared for performance
        
        // Check all possible positions on the grid
        for row in 0..<GameState.gridSize {
            for col in 0..<GameState.gridSize {
                let position = GridPosition(row: row, col: col)
                
                // Check if block can be placed at this position
                if gameState.canPlaceBlock(block, at: position) {
                    // Calculate the center point of the block if placed at this position
                    let blockCenter = getBlockCenterInGrid(for: block, at: position)
                    
                    // Calculate squared distance from target location (faster than sqrt)
                    let distanceSquared = pow(blockCenter.x - targetLocation.x, 2) + pow(blockCenter.y - targetLocation.y, 2)
                    
                    // Update best position if this is closer
                    if distanceSquared < bestDistanceSquared {
                        bestDistanceSquared = distanceSquared
                        bestPosition = position
                    }
                }
            }
        }
        
        // Only return a position if we found one within a reasonable distance
        // This prevents snapping when the user drags very far from the grid
        if bestDistanceSquared <= maxSnapDistanceSquared {
            return bestPosition
        }
        
        return nil
    }
    
    private func getBlockCenterInGrid(for block: BlockShape, at position: GridPosition) -> CGPoint {
        // Calculate the bounding box of the block
        let minRow = block.positions.map(\.row).min() ?? 0
        let maxRow = block.positions.map(\.row).max() ?? 0
        let minCol = block.positions.map(\.col).min() ?? 0
        let maxCol = block.positions.map(\.col).max() ?? 0
        
        // Calculate the center of the block in grid coordinates
        let blockCenterRow = CGFloat(position.row) + CGFloat(maxRow + minRow) / 2.0
        let blockCenterCol = CGFloat(position.col) + CGFloat(maxCol + minCol) / 2.0
        
        // Convert to pixel coordinates within the grid
        let cellSpacing: CGFloat = 3
        let cellWithSpacing = cellSize + cellSpacing
        let gridPadding: CGFloat = 16  // GameTheme.Layout.mediumPadding
        
        let centerX = blockCenterCol * cellWithSpacing + cellSize / 2.0 + gridPadding
        let centerY = blockCenterRow * cellWithSpacing + cellSize / 2.0 + gridPadding
        
        return CGPoint(x: centerX, y: centerY)
    }
    
}

struct GridCellView: View {
    let cell: GridCell
    let size: CGFloat
    let isPreview: Bool
    let previewColor: Color
    let isLineComplete: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                cell.isFilled ? 
                    LinearGradient(colors: [cell.color.color, cell.color.color.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                (isLineComplete ? 
                    LinearGradient(colors: [Color(red: 1.0, green: 0.8, blue: 0.0), Color(red: 1.0, green: 0.6, blue: 0.0)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                (isPreview ? 
                    LinearGradient(colors: [previewColor.opacity(0.8), previewColor.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing) : 
                    LinearGradient(colors: [Color(red: 0.25, green: 0.2, blue: 0.15).opacity(0.3), Color(red: 0.2, green: 0.15, blue: 0.1).opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                ))
            )
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        cell.isFilled ? Color(red: 0.95, green: 0.9, blue: 0.8).opacity(0.4) :
                        (isLineComplete ? Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.9) :
                        (isPreview ? previewColor.opacity(0.8) : Color(red: 0.4, green: 0.25, blue: 0.1).opacity(0.2))),
                        lineWidth: cell.isFilled ? 2 : (isLineComplete ? 3 : (isPreview ? 2 : 1))
                    )
            )
            .overlay(
                // Add special effects for line clearing only (avoid preview pulse during drag)
                Group {
                    if isLineComplete {
                        // Static golden glow for line clearing (no pulsing to avoid conflicts)
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 1.0, green: 0.9, blue: 0.2), lineWidth: 3)
                            .opacity(0.8)
                            .scaleEffect(1.02)
                    }
                }
            )
            .shadow(
                color: cell.isFilled ? cell.color.color.opacity(0.4) :
                      (isLineComplete ? Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.8) :
                      (isPreview ? previewColor.opacity(0.6) : .clear)),
                radius: cell.isFilled ? 5 : (isLineComplete ? 8 : (isPreview ? 6 : 0)),
                x: 0, y: cell.isFilled ? 2 : 1
            )
            .scaleEffect(cell.isFilled ? 1.0 : (isLineComplete ? 0.98 : (isPreview ? 0.95 : 0.88)))
            .animation(.easeInOut(duration: 0.2), value: cell.isFilled)
            .animation(.easeOut(duration: 0.15), value: isLineComplete)
    }
}

struct BlockView: View {
    let block: BlockShape
    let cellSize: CGFloat
    
    var body: some View {
        ZStack {
            // Calculate the bounding box of the block
            let minRow = block.positions.map(\.row).min() ?? 0
            let maxRow = block.positions.map(\.row).max() ?? 0
            let minCol = block.positions.map(\.col).min() ?? 0
            let maxCol = block.positions.map(\.col).max() ?? 0
            
            let width = CGFloat(maxCol - minCol + 1) * cellSize
            let height = CGFloat(maxRow - minRow + 1) * cellSize
            
            // Background for the block area
            Rectangle()
                .fill(Color.clear)
                .frame(width: width, height: height)
            
            // Individual leaf-like cells of the block
            ForEach(Array(block.positions.enumerated()), id: \.offset) { index, position in
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [block.color.color, block.color.color.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: cellSize - 2, height: cellSize - 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 0.95, green: 0.9, blue: 0.8).opacity(0.5), lineWidth: 1.5)
                    )
                    .shadow(color: block.color.color.opacity(0.5), radius: 5, x: 0, y: 3)
                    .offset(
                        x: CGFloat(position.col - minCol) * cellSize - width/2 + cellSize/2,
                        y: CGFloat(position.row - minRow) * cellSize - height/2 + cellSize/2
                    )
            }
        }
    }
}

struct DraggableBlockView: View {
    let block: BlockShape
    let cellSize: CGFloat
    let onDragStart: (CGPoint, CGPoint) -> Void  // current location, start location
    let onDragMove: (CGPoint) -> Void
    let onDragEnd: () -> Void
    
    @State private var isDragging: Bool = false
    @State private var lastUpdateTime: Date = Date()
    
    var body: some View {
        ZStack {
            // Original block stays in place with reduced opacity when dragging
            BlockView(block: block, cellSize: cellSize)
                .opacity(isDragging ? 0.3 : 1.0)
                .animation(.easeInOut(duration: 0.25), value: isDragging)
        }
        .frame(width: getBlockWidth(), height: getBlockHeight())
        .contentShape(Rectangle()) // Ensure entire frame is tappable
        .gesture(
            DragGesture(minimumDistance: 5, coordinateSpace: .global)
                .onChanged { value in
                    let now = Date()
                    if !isDragging {
                        isDragging = true
                        lastUpdateTime = now
                        let blockCenter = CGPoint(
                            x: getBlockWidth() / 2,
                            y: getBlockHeight() / 2
                        )
                        onDragStart(value.location, blockCenter)
                    } else if now.timeIntervalSince(lastUpdateTime) >= 0.016 { // ~60fps limit
                        lastUpdateTime = now
                        onDragMove(value.location)
                    }
                }
                .onEnded { _ in
                    isDragging = false
                    onDragEnd()
                }
        )
    }
    
    private func getBlockWidth() -> CGFloat {
        let minCol = block.positions.map(\.col).min() ?? 0
        let maxCol = block.positions.map(\.col).max() ?? 0
        return CGFloat(maxCol - minCol + 1) * cellSize
    }
    
    private func getBlockHeight() -> CGFloat {
        let minRow = block.positions.map(\.row).min() ?? 0
        let maxRow = block.positions.map(\.row).max() ?? 0
        return CGFloat(maxRow - minRow + 1) * cellSize
    }
}

extension BlockShape: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}


struct BlockGrassView: View {
    let grassColors: [Color] = [
        Color(red: 0.15, green: 0.6, blue: 0.05),   // Dark green
        Color(red: 0.25, green: 0.7, blue: 0.15),   // Medium green
        Color(red: 0.2, green: 0.65, blue: 0.1),    // Forest green
        Color(red: 0.3, green: 0.75, blue: 0.2),    // Light green
        Color(red: 0.18, green: 0.62, blue: 0.08),  // Deep green
        Color(red: 0.22, green: 0.68, blue: 0.12),  // Pine green
        Color(red: 0.28, green: 0.73, blue: 0.18),  // Spring green
    ]
    
    private let blockSize: CGFloat = 12
    private let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Create columns of varying heights that fill available space
                HStack(spacing: 1) {
                    ForEach(0..<Int(screenWidth / (blockSize + 1)), id: \.self) { col in
                        VStack(spacing: 1) {
                            Spacer()
                            // Each column has a random height between 2-5 blocks
                            let columnHeight = getColumnHeight(for: col)
                            ForEach(0..<columnHeight, id: \.self) { blockIndex in
                                StaticGrassBlockView(
                                    color: grassColors[seededRandom(col: col, blockIndex: blockIndex) % grassColors.count],
                                    size: blockSize
                                )
                            }
                        }
                    }
                }
                .frame(height: max(80, geometry.size.height - 20)) // Use available height minus ground base
                
                // Ground base that extends to bottom
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.12, green: 0.45, blue: 0.04),
                                Color(red: 0.1, green: 0.4, blue: 0.03)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 20)
                    .shadow(color: Color(red: 0.05, green: 0.2, blue: 0.02).opacity(0.5), radius: 4, x: 0, y: -2)
            }
        }
    }
    
    // Get deterministic column height
    private func getColumnHeight(for col: Int) -> Int {
        let seed = col * 7919
        let random = ((seed * 9301 + 49297) % 233280) / 50000
        return min(5, max(2, random + 2)) // Heights between 2-5 blocks
    }
    
    // Deterministic random for consistent block colors
    private func seededRandom(col: Int, blockIndex: Int) -> Int {
        let seed = col * 1000 + blockIndex * 100
        return ((seed * 9301 + 49297) % 233280) / 1000
    }
}

struct StaticGrassBlockView: View {
    let color: Color
    let size: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(color.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.4), radius: 3, x: 0, y: 2)
    }
}

// MARK: - Animation Helper Views

struct LineCompletePulseView: View {
    @State private var isAnimating: Bool = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(Color(red: 1.0, green: 0.9, blue: 0.2), lineWidth: 4)
            .opacity(isAnimating ? 0.8 : 0.4)
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6)) {
                    isAnimating = true
                }
            }
    }
}

struct PreviewPulseView: View {
    let previewColor: Color
    @State private var isAnimating: Bool = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(previewColor, lineWidth: 3)
            .opacity(isAnimating ? 0.6 : 0.3)
            .scaleEffect(isAnimating ? 1.02 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.4)) {
                    isAnimating = true
                }
            }
    }
}
