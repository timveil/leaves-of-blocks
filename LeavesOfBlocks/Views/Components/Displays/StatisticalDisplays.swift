import SwiftUI

// MARK: - Unified Statistical Display Components

/// A unified stat chip component for displaying key-value pairs
struct GameStatChip: View {
    let title: String
    let value: String
    let icon: String?
    let color: Color
    let style: StatChipStyle
    
    enum StatChipStyle {
        case compact
        case standard
        case featured
        
        var fontSize: Font {
            switch self {
            case .compact: return GameTheme.Typography.fontXSmall
            case .standard: return GameTheme.Typography.fontSmall
            case .featured: return GameTheme.Typography.fontMediumSmall
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .compact: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .standard: return EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
            case .featured: return EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
            }
        }
    }
    
    init(
        title: String,
        value: String,
        icon: String? = nil,
        color: Color = GameTheme.Colors.accent,
        style: StatChipStyle = .standard
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.style = style
    }
    
    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: style == .compact ? 12 : 14, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                if style != .compact {
                    Text(title)
                        .font(GameTheme.Typography.fontXSmall)
                        .foregroundColor(GameTheme.Colors.secondaryText)
                }
                
                Text(value)
                    .font(style.fontSize)
                    .fontWeight(style == .featured ? .bold : .medium)
                    .foregroundColor(GameTheme.Colors.primaryText)
            }
        }
        .padding(style.padding)
        .gameBadgeStyle(
            backgroundColor: color.opacity(0.15),
            borderColor: color.opacity(0.3),
            borderWidth: 1
        )
    }
}

/// A unified statistic card component for larger displays
struct GameStatisticCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    let trend: StatTrend?
    
    enum StatTrend {
        case up(String)
        case down(String)
        case neutral(String)
        
        var color: Color {
            switch self {
            case .up: return GameTheme.Colors.success
            case .down: return GameTheme.Colors.error
            case .neutral: return GameTheme.Colors.secondaryText
            }
        }
        
        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .neutral: return "minus"
            }
        }
        
        var text: String {
            switch self {
            case .up(let text), .down(let text), .neutral(let text):
                return text
            }
        }
    }
    
    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        color: Color = GameTheme.Colors.accent,
        trend: StatTrend? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.trend = trend
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
            // Header with icon and title
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                
                Text(title)
                    .font(GameTheme.Typography.fontMediumSmall)
                    .foregroundColor(GameTheme.Colors.primaryText)
                
                Spacer()
            }
            
            // Main value
            Text(value)
                .font(GameTheme.Typography.fontXXLarge)
                .fontWeight(.bold)
                .foregroundColor(GameTheme.Colors.primaryText)
            
            // Subtitle and trend
            HStack {
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(GameTheme.Typography.fontXSmall)
                        .foregroundColor(GameTheme.Colors.secondaryText)
                }
                
                Spacer()
                
                if let trend = trend {
                    HStack(spacing: 4) {
                        Image(systemName: trend.icon)
                            .font(.system(size: 12, weight: .semibold))
                        
                        Text(trend.text)
                            .font(GameTheme.Typography.fontXSmall)
                    }
                    .foregroundColor(trend.color)
                }
            }
        }
        .padding(GameTheme.Layout.largePadding)
        .gameCardStyle(
            borderColor: color.opacity(0.3),
            borderWidth: 1
        )
    }
}

/// A unified progress indicator component
struct GameProgressIndicator: View {
    let title: String
    let current: Int
    let maximum: Int
    let color: Color
    let showPercentage: Bool
    
    private var progress: Double {
        guard maximum > 0 else { return 0 }
        return Double(current) / Double(maximum)
    }
    
    private var percentage: Int {
        Int(progress * 100)
    }
    
    init(
        title: String,
        current: Int,
        maximum: Int,
        color: Color = GameTheme.Colors.accent,
        showPercentage: Bool = true
    ) {
        self.title = title
        self.current = current
        self.maximum = maximum
        self.color = color
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(GameTheme.Typography.fontSmall)
                    .foregroundColor(GameTheme.Colors.primaryText)
                
                Spacer()
                
                if showPercentage {
                    Text("\(percentage)%")
                        .font(GameTheme.Typography.fontXSmall)
                        .foregroundColor(GameTheme.Colors.secondaryText)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(GameTheme.Colors.gridBorder.opacity(0.2))
                        .frame(height: 8)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 8)
            
            // Current/Max display
            HStack {
                Text("\(current)")
                    .font(GameTheme.Typography.fontXSmall)
                    .foregroundColor(color)
                    .fontWeight(.semibold)
                
                Text("/ \(maximum)")
                    .font(GameTheme.Typography.fontXSmall)
                    .foregroundColor(GameTheme.Colors.secondaryText)
            }
        }
    }
}

/// A unified comparison display for before/after stats
struct StatComparison: View {
    let title: String
    let previousValue: String
    let currentValue: String
    let icon: String
    let improvementColor: Color
    
    private var isImprovement: Bool {
        // Simple numeric comparison - can be enhanced based on needs
        if let prev = Int(previousValue), let curr = Int(currentValue) {
            return curr > prev
        }
        return false
    }
    
    init(
        title: String,
        previousValue: String,
        currentValue: String,
        icon: String,
        improvementColor: Color = GameTheme.Colors.success
    ) {
        self.title = title
        self.previousValue = previousValue
        self.currentValue = currentValue
        self.icon = icon
        self.improvementColor = improvementColor
    }
    
    var body: some View {
        HStack(spacing: GameTheme.Layout.mediumSpacing) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(GameTheme.Colors.accent)
                .frame(width: 24)
            
            // Title
            Text(title)
                .font(GameTheme.Typography.fontSmall)
                .foregroundColor(GameTheme.Colors.primaryText)
            
            Spacer()
            
            // Values comparison
            HStack(spacing: 8) {
                // Previous value
                Text(previousValue)
                    .font(GameTheme.Typography.fontXSmall)
                    .foregroundColor(GameTheme.Colors.secondaryText)
                    .strikethrough()
                
                // Arrow
                Image(systemName: isImprovement ? "arrow.right" : "arrow.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isImprovement ? improvementColor : GameTheme.Colors.secondaryText)
                
                // Current value
                Text(currentValue)
                    .font(GameTheme.Typography.fontSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(isImprovement ? improvementColor : GameTheme.Colors.primaryText)
            }
        }
        .padding(.horizontal, GameTheme.Layout.mediumPadding)
        .padding(.vertical, GameTheme.Layout.smallPadding)
    }
}

