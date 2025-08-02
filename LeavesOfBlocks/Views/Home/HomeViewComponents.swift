import SwiftUI

// MARK: - Difficulty Selection Component

struct DifficultySelectionView: View {
    @Binding var selectedDifficulty: DifficultyMode
    let onStartGame: (DifficultyMode) -> Void
    
    var body: some View {
        VStack(spacing: GameTheme.Layout.extraLargeSpacing) {
            Text("select_difficulty".localized)
                .font(GameTheme.Typography.fontLarge)
                .foregroundColor(GameTheme.Colors.primaryText)
                .tracking(0.5)
            
            // Horizontal difficulty buttons
            HStack(spacing: GameTheme.Layout.largeSpacing) {
                ForEach(DifficultyMode.allCases, id: \.self) { difficulty in
                    VStack(spacing: GameTheme.Layout.smallSpacing) {
                        Button(action: {
                            selectedDifficulty = difficulty
                        }) {
                            VStack(spacing: GameTheme.Layout.smallSpacing) {
                                Image(systemName: difficulty.icon)
                                    .font(GameTheme.Typography.fontLargeSemibold)
                                    .foregroundColor(selectedDifficulty == difficulty ? difficulty.color : GameTheme.Colors.secondaryText)
                                    .frame(width: 60, height: 60)
                            }
                            .frame(width: 80, height: 80)
                            .gameButtonCardStyle(
                                isSelected: selectedDifficulty == difficulty,
                                selectedColor: difficulty.color
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityIdentifier("\(difficulty.rawValue.lowercased())_button")
                        
                        Text(difficulty.rawValue)
                            .font(GameTheme.Typography.fontXSmall)
                            .fontWeight(.medium)
                            .foregroundColor(selectedDifficulty == difficulty ? difficulty.color : GameTheme.Colors.secondaryText)
                    }
                }
            }
            
            Spacer().frame(maxHeight: 15)
            
            // Start game button using full width action button component
            FullWidthActionButton(
                title: "start_game".localized,
                icon: "play.circle.fill",
                style: .success,
                accessibilityId: "start_game_button",
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
