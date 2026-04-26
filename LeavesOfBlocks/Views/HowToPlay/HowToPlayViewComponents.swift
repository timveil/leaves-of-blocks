import SwiftUI

// MARK: - Instruction Components

struct InstructionSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
            Text(title)
                .font(GameTheme.Typography.headline)
                .foregroundColor(GameTheme.Colors.primaryText)
            
            Text(content)
                .font(GameTheme.Typography.body)
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
                .font(GameTheme.Typography.body)
                .foregroundColor(GameTheme.Colors.accent)
            
            Text(text)
                .font(GameTheme.Typography.body)
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
    let isLast: Bool
    
    var body: some View {
        HStack(spacing: GameTheme.Layout.largePadding) {
            // Points column
            Text(points)
                .font(GameTheme.Typography.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
                .frame(width: 100, alignment: .center)
            
            // Description column
            Text(description)
                .font(GameTheme.Typography.body)
                .foregroundColor(GameTheme.Colors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, GameTheme.Layout.largePadding)
        .padding(.vertical, GameTheme.Layout.mediumPadding)
        .modifier(
            ConditionalTableRowStyleModifier(
                isLast: isLast,
                backgroundColor: color.opacity(0.05)
            )
        )
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
            Text("points".localized)
                .font(GameTheme.Typography.body)
                .fontWeight(.bold)
                .foregroundColor(GameTheme.Colors.primaryText)
                .frame(width: 100, alignment: .leading)
            
            // Description header
            Text("description".localized)
                .font(GameTheme.Typography.body)
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
            Text("mode".localized)
                .font(GameTheme.Typography.body)
                .fontWeight(.bold)
                .foregroundColor(GameTheme.Colors.primaryText)
                .frame(width: 100, alignment: .leading)
            
            // Description header
            Text("description".localized)
                .font(GameTheme.Typography.body)
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
    let isLast: Bool
    
    var body: some View {
        HStack(spacing: GameTheme.Layout.largePadding) {
            // Mode icon and name column (home screen style)
            VStack(spacing: GameTheme.Layout.smallSpacing) {
                Image(systemName: mode.icon)
                    .font(GameTheme.Typography.headline)
                    .foregroundColor(mode.color)
                    .frame(height: 30)
                
                Text(mode.rawValue.capitalized)
                    .font(GameTheme.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(GameTheme.Colors.primaryText)
            }
            .frame(width: 100, alignment: .center)
            
            // Description column
            Text(description)
                .font(GameTheme.Typography.body)
                .foregroundColor(GameTheme.Colors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, GameTheme.Layout.largePadding)
        .padding(.vertical, GameTheme.Layout.largePadding)
        .modifier(
            ConditionalTableRowStyleModifier(
                isLast: isLast,
                backgroundColor: mode.color.opacity(0.05)
            )
        )
        .overlay(
            Rectangle()
                .frame(height: isFirst ? 0 : 1)
                .foregroundColor(GameTheme.Colors.gridBorder.opacity(0.2)),
            alignment: .top
        )
    }
}

// MARK: - Shapes Table Components

struct ShapesTableHeaderView: View {
    var body: some View {
        HStack(spacing: GameTheme.Layout.largePadding) {
            // Shape header
            Text("shape".localized)
                .font(GameTheme.Typography.body)
                .fontWeight(.bold)
                .foregroundColor(GameTheme.Colors.primaryText)
                .frame(width: 100, alignment: .leading)
            
            // Description header
            Text("description".localized)
                .font(GameTheme.Typography.body)
                .fontWeight(.bold)
                .foregroundColor(GameTheme.Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, GameTheme.Layout.largePadding)
        .padding(.vertical, GameTheme.Layout.mediumPadding)
        .gameTableHeaderStyle()
    }
}

struct ShapesTableRowView: View {
    let shapeType: ShapeType
    let description: String
    let isFirst: Bool
    let isLast: Bool
    
    var body: some View {
        HStack(spacing: GameTheme.Layout.largePadding) {
            // Shape visual column
            VStack(spacing: GameTheme.Layout.smallSpacing) {
                shapeType.visualRepresentation
                    .frame(height: 40)
                
                Text(shapeType.displayName)
                    .font(GameTheme.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(GameTheme.Colors.primaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 100, alignment: .center)
            
            // Description column
            Text(description)
                .font(GameTheme.Typography.body)
                .foregroundColor(GameTheme.Colors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, GameTheme.Layout.largePadding)
        .padding(.vertical, GameTheme.Layout.largePadding)
        .modifier(
            ConditionalTableRowStyleModifier(
                isLast: isLast,
                backgroundColor: shapeType.backgroundColor
            )
        )
        .overlay(
            Rectangle()
                .frame(height: isFirst ? 0 : 1)
                .foregroundColor(GameTheme.Colors.gridBorder.opacity(0.2)),
            alignment: .top
        )
    }
}

// MARK: - Shape Type Definition

enum ShapeType {
    case normalBlocks
    case horizontalClear
    case verticalClear
    case areaClear
    
    var displayName: String {
        switch self {
        case .normalBlocks:
            return "shape_normal_blocks".localized
        case .horizontalClear:
            return "shape_row_clear".localized
        case .verticalClear:
            return "shape_column_clear".localized
        case .areaClear:
            return "shape_area_clear".localized
        }
    }
    
    var visualRepresentation: some View {
        switch self {
        case .normalBlocks:
            return AnyView(
                // Show a mini grid pattern representing various normal blocks
                HStack(spacing: 2) {
                    VStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(GameTheme.Colors.blockBlue.opacity(0.8))
                            .frame(width: 8, height: 8)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(GameTheme.Colors.blockGreen.opacity(0.8))
                            .frame(width: 8, height: 8)
                    }
                    VStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(GameTheme.Colors.blockRed.opacity(0.8))
                            .frame(width: 8, height: 8)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(GameTheme.Colors.blockYellow.opacity(0.8))
                            .frame(width: 8, height: 8)
                    }
                    RoundedRectangle(cornerRadius: 2)
                        .fill(GameTheme.Colors.blockPurple.opacity(0.8))
                        .frame(width: 8, height: 16)
                }
            )
        case .horizontalClear:
            return AnyView(
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            GameTheme.Gradients.blockVisual(from: GameTheme.Colors.blockRed, to: GameTheme.Colors.blockRed.opacity(0.7))
                        )
                        .frame(width: 30, height: 30)
                        .shadow(color: GameTheme.Colors.blockRed.opacity(0.4), radius: 3)
                    
                    Image(systemName: "arrow.left.and.right")
                        .foregroundColor(GameTheme.Colors.buttonText)
                        .font(GameTheme.Typography.body)
                }
            )
        case .verticalClear:
            return AnyView(
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            GameTheme.Gradients.blockVisual(from: GameTheme.Colors.blockBlue, to: GameTheme.Colors.blockBlue.opacity(0.7))
                        )
                        .frame(width: 30, height: 30)
                        .shadow(color: GameTheme.Colors.blockBlue.opacity(0.4), radius: 3)

                    Image(systemName: "arrow.up.and.down")
                        .foregroundColor(GameTheme.Colors.buttonText)
                        .font(GameTheme.Typography.body)
                }
            )
        case .areaClear:
            return AnyView(
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            GameTheme.Gradients.blockVisual(from: GameTheme.Colors.blockPurple, to: GameTheme.Colors.blockPurple.opacity(0.7))
                        )
                        .frame(width: 30, height: 30)
                        .shadow(color: GameTheme.Colors.blockPurple.opacity(0.4), radius: 3)

                    Image(systemName: "square.3.layers.3d")
                        .foregroundColor(GameTheme.Colors.buttonText)
                        .font(GameTheme.Typography.body)
                }
            )
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .normalBlocks:
            return GameTheme.Colors.secondaryText.opacity(0.05)
        case .horizontalClear:
            return GameTheme.Colors.blockRed.opacity(0.05)
        case .verticalClear:
            return GameTheme.Colors.blockBlue.opacity(0.05)
        case .areaClear:
            return GameTheme.Colors.blockPurple.opacity(0.05)
        }
    }
}

// MARK: - Table Row Style Modifier

struct ConditionalTableRowStyleModifier: ViewModifier {
    let isLast: Bool
    let backgroundColor: Color
    
    func body(content: Content) -> some View {
        if isLast {
            content
                .gameTableFooterStyle(backgroundColor: backgroundColor)
        } else {
            content
                .gameTableRowStyle(backgroundColor: backgroundColor)
        }
    }
}
