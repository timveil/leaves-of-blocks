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
                    GameDifficultyButton(
                        difficulty: difficulty,
                        isSelected: selectedDifficulty == difficulty,
                        isCompact: true,
                        onTap: {
                            selectedDifficulty = difficulty
                        }
                    )
                }
            }
            .padding(.horizontal, GameTheme.Layout.smallPadding)
            
            // Start game button using our new component
            StartGameButton(
                difficulty: selectedDifficulty,
                onTap: {
                    onStartGame(selectedDifficulty)
                }
            )
        }
        .padding(.horizontal, GameTheme.Layout.mediumPadding)
    }
}

// Note: CompactDifficultyButton and DifficultyButton have been replaced
// by the unified GameDifficultyButton component in Views/Components/Buttons/GameButtons.swift