import SwiftUI

// MARK: - Instruction Components

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

// MARK: - Scoring Table

struct ScoringTableHeaderView: View {
    var body: some View {
        Text("scoring_header".localized)
            .font(GameTheme.Typography.headline)
            .foregroundColor(GameTheme.Colors.buttonText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, GameTheme.Layout.mediumPadding)
            .gameTableHeaderStyle()
    }
}

struct ScoringTableRowView: View {
    let points: String
    let description: String
    let color: Color
    var isLast: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            Text(points)
                .font(GameTheme.Typography.display)
                .foregroundColor(color)

            Text(description)
                .font(GameTheme.Typography.body)
                .foregroundColor(GameTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, GameTheme.Layout.largePadding)
        .padding(.vertical, GameTheme.Layout.mediumPadding)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(GameTheme.Colors.gridBorder.opacity(0.2)),
            alignment: .top
        )
    }
}

// MARK: - Difficulty Table

struct DifficultyTableHeaderView: View {
    var body: some View {
        Text("difficulty_header".localized)
            .font(GameTheme.Typography.headline)
            .foregroundColor(GameTheme.Colors.buttonText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, GameTheme.Layout.mediumPadding)
            .gameTableHeaderStyle()
    }
}

struct DifficultyTableRowView: View {
    let mode: DifficultyMode
    let description: String
    var isLast: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                ForEach(0..<mode.acornCount, id: \.self) { _ in
                    Image("AcornIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 44)
                }
            }

            Text(description)
                .font(GameTheme.Typography.body)
                .foregroundColor(GameTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, GameTheme.Layout.largePadding)
        .padding(.vertical, GameTheme.Layout.mediumPadding)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(GameTheme.Colors.gridBorder.opacity(0.2)),
            alignment: .top
        )
    }
}

// MARK: - Shapes Table

struct ShapesTableHeaderView: View {
    var body: some View {
        Text("shapes_header".localized)
            .font(GameTheme.Typography.headline)
            .foregroundColor(GameTheme.Colors.buttonText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, GameTheme.Layout.mediumPadding)
            .gameTableHeaderStyle()
    }
}

struct ShapesTableRowView: View {
    let shapeType: ShapeType
    let description: String
    var isLast: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            shapeType.visualRepresentation
                .frame(height: 44)

            Text(description)
                .font(GameTheme.Typography.body)
                .foregroundColor(GameTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, GameTheme.Layout.largePadding)
        .padding(.vertical, GameTheme.Layout.mediumPadding)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
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
        case .normalBlocks:   return "shape_normal_blocks".localized
        case .horizontalClear: return "shape_row_clear".localized
        case .verticalClear:   return "shape_column_clear".localized
        case .areaClear:       return "shape_area_clear".localized
        }
    }

    @ViewBuilder
    var visualRepresentation: some View {
        switch self {
        case .normalBlocks:
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(GameTheme.Colors.blockBlue)
                    .frame(width: 20, height: 20)
                RoundedRectangle(cornerRadius: 4)
                    .fill(GameTheme.Colors.blockGreen)
                    .frame(width: 20, height: 20)
                RoundedRectangle(cornerRadius: 4)
                    .fill(GameTheme.Colors.blockYellow)
                    .frame(width: 20, height: 20)
            }
        case .horizontalClear:
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(GameTheme.Colors.blockRed)
                    .frame(width: 44, height: 44)
                Image(systemName: "arrow.left.and.right")
                    .foregroundColor(GameTheme.Colors.buttonText)
                    .font(.system(size: 22, weight: .bold))
            }
        case .verticalClear:
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(GameTheme.Colors.blockBlue)
                    .frame(width: 44, height: 44)
                Image(systemName: "arrow.up.and.down")
                    .foregroundColor(GameTheme.Colors.buttonText)
                    .font(.system(size: 22, weight: .bold))
            }
        case .areaClear:
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(GameTheme.Colors.blockPurple)
                    .frame(width: 44, height: 44)
                Image(systemName: "square.3.layers.3d")
                    .foregroundColor(GameTheme.Colors.buttonText)
                    .font(.system(size: 22, weight: .bold))
            }
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
