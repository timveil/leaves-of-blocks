import SwiftUI

// MARK: - Instruction Components

struct InstructionSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
            Text(title)
                .font(GameTheme.Typography.secondaryHeader)
                .foregroundColor(GameTheme.Colors.primaryText)
            
            Text(content)
                .font(GameTheme.Typography.standardBody)
                .foregroundColor(GameTheme.Colors.secondaryText)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GameTheme.Layout.largePadding)
        .gameGradientCardStyle()
    }
}

struct TipRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: GameTheme.Layout.mediumSpacing) {
            Text("•")
                .font(GameTheme.Typography.primaryBody)
                .foregroundColor(GameTheme.Colors.accent)
            
            Text(text)
                .font(GameTheme.Typography.primaryBody)
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
                .font(GameTheme.Typography.secondaryHeader)
                .fontWeight(.bold)
                .foregroundColor(color)
                .frame(width: 100, alignment: .center)
            
            // Description column
            Text(description)
                .font(GameTheme.Typography.standardBody)
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
                .font(GameTheme.Typography.primaryBody)
                .fontWeight(.bold)
                .foregroundColor(GameTheme.Colors.primaryText)
                .frame(width: 100, alignment: .leading)
            
            // Description header
            Text("Description")
                .font(GameTheme.Typography.primaryBody)
                .fontWeight(.bold)
                .foregroundColor(GameTheme.Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, GameTheme.Layout.largePadding)
        .padding(.vertical, GameTheme.Layout.mediumPadding)
        .gameTableHeaderStyle()
    }
}

struct DifficultyTableHeaderView: View {
    var body: some View {
        HStack(spacing: GameTheme.Layout.largePadding) {
            // Mode header
            Text("Mode")
                .font(GameTheme.Typography.primaryBody)
                .fontWeight(.bold)
                .foregroundColor(GameTheme.Colors.primaryText)
                .frame(width: 100, alignment: .leading)
            
            // Description header
            Text("Description")
                .font(GameTheme.Typography.primaryBody)
                .fontWeight(.bold)
                .foregroundColor(GameTheme.Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, GameTheme.Layout.largePadding)
        .padding(.vertical, GameTheme.Layout.mediumPadding)
        .gameTableHeaderStyle()
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
                    .font(GameTheme.Typography.compactBody)
                    .fontWeight(.medium)
                    .foregroundColor(GameTheme.Colors.primaryText)
            }
            .frame(width: 100, alignment: .center)
            
            // Description column
            Text(description)
                .font(GameTheme.Typography.standardBody)
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
