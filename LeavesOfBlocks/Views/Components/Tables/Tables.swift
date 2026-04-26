import SwiftUI

// MARK: - Generic Game Table Components

/// A unified table component for displaying structured data
struct GameTable<Data: Identifiable, Content: View>: View {
    let title: String
    let data: [Data]
    let headers: [String]
    let content: (Data) -> Content
    
    init(
        title: String,
        data: [Data],
        headers: [String],
        @ViewBuilder content: @escaping (Data) -> Content
    ) {
        self.title = title
        self.data = data
        self.headers = headers
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Table title
            if !title.isEmpty {
                Text(title)
                    .font(GameTheme.Typography.title)
                    .foregroundColor(GameTheme.Colors.primaryText)
                    .padding(.bottom, GameTheme.Layout.mediumSpacing)
            }
            
            // Headers
            HStack {
                ForEach(headers, id: \.self) { header in
                    Text(header)
                        .font(GameTheme.Typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(GameTheme.Colors.primaryText)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, GameTheme.Layout.largePadding)
            .padding(.vertical, GameTheme.Layout.mediumPadding)
            .gameTableHeaderStyle()
            
            // Rows
            VStack(spacing: 0) {
                ForEach(data) { item in
                    content(item)
                        .padding(.horizontal, GameTheme.Layout.largePadding)
                        .padding(.vertical, GameTheme.Layout.mediumPadding)
                        .background(GameTheme.Colors.cardBackground)
                        .overlay(
                            Rectangle()
                                .fill(GameTheme.Colors.gridBorder.opacity(0.1))
                                .frame(height: 1),
                            alignment: .bottom
                        )
                }
            }
            .background(
                RoundedRectangle(
                    cornerRadius: GameTheme.Layout.cardCornerRadius,
                    style: .continuous
                )
                .fill(GameTheme.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(
                        cornerRadius: GameTheme.Layout.cardCornerRadius,
                        style: .continuous
                    )
                    .stroke(GameTheme.Colors.accent.opacity(0.3), lineWidth: 1)
                )
            )
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: GameTheme.Layout.cardCornerRadius,
                    bottomTrailingRadius: GameTheme.Layout.cardCornerRadius,
                    topTrailingRadius: 0
                )
            )
        }
    }
}

/// A specialized scoring table component
struct ScoringTable: View {
    let scoringRules: [ScoringRule]
    
    struct ScoringRule: Identifiable {
        let id = UUID()
        let action: String
        let points: String
        let description: String
    }
    
    var body: some View {
        GameTable(
            title: "Scoring System",
            data: scoringRules,
            headers: ["Action", "Points", "Description"]
        ) { rule in
            HStack {
                // Action
                Text(rule.action)
                    .font(GameTheme.Typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(GameTheme.Colors.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Points
                Text(rule.points)
                    .font(GameTheme.Typography.body)
                    .fontWeight(.bold)
                    .foregroundColor(GameTheme.Colors.accent)
                    .frame(maxWidth: .infinity)
                
                // Description
                Text(rule.description)
                    .font(GameTheme.Typography.caption)
                    .foregroundColor(GameTheme.Colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

/// A specialized difficulty comparison table
struct DifficultyTable: View {
    let difficultyLevels: [DifficultyLevel]
    
    struct DifficultyLevel: Identifiable {
        let id = UUID()
        let difficulty: DifficultyMode
        let description: String
        let blockFrequency: String
    }
    
    var body: some View {
        GameTable(
            title: "Difficulty Levels",
            data: difficultyLevels,
            headers: ["Level", "Description", "Block Frequency"]
        ) { level in
            HStack {
                // Difficulty badge
                HStack(spacing: 6) {
                    Image(systemName: level.difficulty.icon)
                        .font(GameTheme.Typography.body)
                        .foregroundColor(level.difficulty.color)
                    
                    Text(level.difficulty.displayName)
                        .font(GameTheme.Typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(GameTheme.Colors.primaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Description
                Text(level.description)
                    .font(GameTheme.Typography.caption)
                    .foregroundColor(GameTheme.Colors.secondaryText)
                    .frame(maxWidth: .infinity)
                
                // Block frequency
                Text(level.blockFrequency)
                    .font(GameTheme.Typography.caption)
                    .foregroundColor(GameTheme.Colors.accent)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

/// A flexible key-value table component
struct KeyValueTable: View {
    let title: String
    let items: [KeyValueItem]
    
    struct KeyValueItem: Identifiable {
        let id = UUID()
        let key: String
        let value: String
        let icon: String?
        let color: Color?
        
        init(key: String, value: String, icon: String? = nil, color: Color? = nil) {
            self.key = key
            self.value = value
            self.icon = icon
            self.color = color
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Title
            if !title.isEmpty {
                Text(title)
                    .font(GameTheme.Typography.title)
                    .foregroundColor(GameTheme.Colors.primaryText)
                    .padding(.bottom, GameTheme.Layout.mediumSpacing)
            }
            
            // Items
            VStack(spacing: 0) {
                ForEach(items) { item in
                    HStack {
                        // Key with optional icon
                        HStack(spacing: 8) {
                            if let icon = item.icon {
                                Image(systemName: icon)
                                    .font(GameTheme.Typography.body)
                                    .foregroundColor(item.color ?? GameTheme.Colors.accent)
                                    .frame(width: 20)
                            }
                            
                            Text(item.key)
                                .font(GameTheme.Typography.body)
                                .foregroundColor(GameTheme.Colors.primaryText)
                        }
                        
                        Spacer()
                        
                        // Value
                        Text(item.value)
                            .font(GameTheme.Typography.body)
                            .fontWeight(.medium)
                            .foregroundColor(item.color ?? GameTheme.Colors.accent)
                    }
                    .padding(.horizontal, GameTheme.Layout.largePadding)
                    .padding(.vertical, GameTheme.Layout.mediumPadding)
                    .background(GameTheme.Colors.cardBackground)
                    .overlay(
                        Rectangle()
                            .fill(GameTheme.Colors.gridBorder.opacity(0.1))
                            .frame(height: 1),
                        alignment: .bottom
                    )
                }
            }
            .gameCardStyle()
        }
    }
}

/// A summary statistics table component
struct SummaryStatsTable: View {
    let gameSession: GameSession?
    let currentStats: GameStats
    
    struct GameStats {
        let score: Int
        let blocksPlaced: Int
        let linesCleared: Int
        let gameTime: TimeInterval
        let difficulty: DifficultyMode
        let longestCombo: Int
    }
    
    private var statsItems: [KeyValueTable.KeyValueItem] {
        [
            KeyValueTable.KeyValueItem(
                key: "Final Score",
                value: "\(gameSession?.score ?? currentStats.score)",
                icon: "star.fill",
                color: GameTheme.Colors.accent
            ),
            KeyValueTable.KeyValueItem(
                key: "Blocks Placed",
                value: "\(gameSession?.blocksPlaced ?? currentStats.blocksPlaced)",
                icon: "cube.fill",
                color: GameTheme.Colors.blockYellow
            ),
            KeyValueTable.KeyValueItem(
                key: "Lines Cleared",
                value: "\(gameSession?.linesCleared ?? currentStats.linesCleared)",
                icon: "square.grid.3x3.fill",
                color: GameTheme.Colors.success
            ),
            KeyValueTable.KeyValueItem(
                key: "Game Time",
                value: formatTime(gameSession?.gameTime ?? currentStats.gameTime),
                icon: "clock.fill",
                color: GameTheme.Colors.secondaryText
            ),
            KeyValueTable.KeyValueItem(
                key: "Difficulty",
                value: (gameSession?.difficulty ?? currentStats.difficulty).rawValue,
                icon: (gameSession?.difficulty ?? currentStats.difficulty).icon,
                color: (gameSession?.difficulty ?? currentStats.difficulty).color
            ),
            KeyValueTable.KeyValueItem(
                key: "Longest Combo",
                value: "\(currentStats.longestCombo)",
                icon: "flame.fill",
                color: GameTheme.Colors.error
            )
        ]
    }
    
    init(gameSession: GameSession? = nil, currentStats: GameStats) {
        self.gameSession = gameSession
        self.currentStats = currentStats
    }
    
    var body: some View {
        KeyValueTable(
            title: gameSession != nil ? "Session Summary" : "Current Game",
            items: statsItems
        )
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

