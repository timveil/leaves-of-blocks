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

// MARK: - Shared Table Header

/// Gold band at the top of each How-To-Play table card. The three sites
/// (scoring / difficulty / shapes) used to be three identical structs
/// differing only in the localized title key — one parameterized component
/// covers all of them.
struct GameTableHeaderView: View {
    let titleKey: String

    var body: some View {
        Text(titleKey.localized)
            .font(GameTheme.Typography.title)
            .foregroundColor(GameTheme.Colors.primaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, GameTheme.Layout.mediumPadding)
            .gameTableHeaderStyle()
    }
}

// MARK: - Shared Table Row

/// Generic row used by every How-To-Play table card: an icon-y top
/// element provided by the caller, then a localized description below,
/// wrapped in the shared white-background + top-divider envelope. The
/// per-variant wrappers below (Scoring/Difficulty/Shapes) only carry
/// their parameter shape; the layout itself lives here.
struct GameTableRowView<Header: View>: View {
    let description: String
    @ViewBuilder let header: () -> Header

    var body: some View {
        VStack(spacing: GameTheme.Layout.tightSpacing) {
            header()

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

// MARK: - Scoring Table

struct ScoringTableRowView: View {
    let points: String
    let description: String
    let color: Color

    var body: some View {
        GameTableRowView(description: description) {
            Text(points)
                .font(GameTheme.Typography.display)
                .foregroundColor(color)
        }
    }
}

// MARK: - Difficulty Table

struct DifficultyTableRowView: View {
    let mode: DifficultyMode
    let description: String

    var body: some View {
        GameTableRowView(description: description) {
            AcornCountView(count: mode.acornCount)
        }
    }
}

// MARK: - Shapes Table

struct ShapesTableRowView: View {
    let shapeType: ShapeType
    let description: String

    var body: some View {
        GameTableRowView(description: description) {
            shapeType.visualRepresentation
                .frame(height: 44)
        }
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
                RoundedRectangle(cornerRadius: GameTheme.Layout.cellCornerRadius)
                    .fill(GameTheme.Colors.blockBlue)
                    .frame(width: 20, height: 20)
                RoundedRectangle(cornerRadius: GameTheme.Layout.cellCornerRadius)
                    .fill(GameTheme.Colors.blockGreen)
                    .frame(width: 20, height: 20)
                RoundedRectangle(cornerRadius: GameTheme.Layout.cellCornerRadius)
                    .fill(GameTheme.Colors.blockYellow)
                    .frame(width: 20, height: 20)
            }
        case .horizontalClear:
            ZStack {
                RoundedRectangle(cornerRadius: GameTheme.Layout.specialBlockCornerRadius)
                    .fill(GameTheme.Colors.blockRed)
                    .frame(width: 44, height: 44)
                Image(systemName: "arrow.left.and.right")
                    .foregroundColor(GameTheme.Colors.buttonText)
                    .font(.system(size: 22, weight: .bold))
            }
        case .verticalClear:
            ZStack {
                RoundedRectangle(cornerRadius: GameTheme.Layout.specialBlockCornerRadius)
                    .fill(GameTheme.Colors.blockBlue)
                    .frame(width: 44, height: 44)
                Image(systemName: "arrow.up.and.down")
                    .foregroundColor(GameTheme.Colors.buttonText)
                    .font(.system(size: 22, weight: .bold))
            }
        case .areaClear:
            ZStack {
                RoundedRectangle(cornerRadius: GameTheme.Layout.specialBlockCornerRadius)
                    .fill(GameTheme.Colors.blockPurple)
                    .frame(width: 44, height: 44)
                Image(systemName: "square.3.layers.3d")
                    .foregroundColor(GameTheme.Colors.buttonText)
                    .font(.system(size: 22, weight: .bold))
            }
        }
    }
}

// MARK: - Previews

#Preview("Scoring Table Row") {
    VStack(spacing: 0) {
        GameTableHeaderView(titleKey: "scoring_header")
        ScoringTableRowView(points: "+10", description: "scoring_block_placement".localized, color: GameTheme.Colors.accent)
        ScoringTableRowView(points: "+100", description: "scoring_line_clear".localized, color: GameTheme.Colors.success)
    }
    .clipShape(RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius))
    .overlay(RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius).stroke(Color.black, lineWidth: GameTheme.Layout.cardBorderWidth))
    .padding()
}

#Preview("Difficulty Table Row") {
    VStack(spacing: 0) {
        GameTableHeaderView(titleKey: "difficulty_header")
        DifficultyTableRowView(mode: .easy, description: "difficulty_easy_desc".localized)
        DifficultyTableRowView(mode: .moderate, description: "difficulty_moderate_desc".localized)
    }
    .clipShape(RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius))
    .overlay(RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius).stroke(Color.black, lineWidth: GameTheme.Layout.cardBorderWidth))
    .padding()
}

#Preview("Shapes Table Row") {
    VStack(spacing: 0) {
        GameTableHeaderView(titleKey: "shapes_header")
        ShapesTableRowView(shapeType: .normalBlocks, description: "shape_normal_desc".localized)
        ShapesTableRowView(shapeType: .horizontalClear, description: "shape_row_clear_desc".localized)
    }
    .clipShape(RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius))
    .overlay(RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius).stroke(Color.black, lineWidth: GameTheme.Layout.cardBorderWidth))
    .padding()
}
