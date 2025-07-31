//
//  SettingsView.swift
//  LeavesOfBlocks
//
//  Created by Tim Veil on 7/31/25.
//

import SwiftUI

/// Settings screen for app configuration and data management.
///
/// Provides options for managing user data including game history, high scores,
/// and application preferences. Follows the app's design patterns with confirmation
/// dialogs for destructive actions.
struct SettingsView: View {
    @ObservedObject var gameState: GameState
    @State private var showingResetOptions = false
    @State private var showingClearHistoryConfirmation = false
    @State private var showingResetAllConfirmation = false
    @State private var resetCompletedMessage: String?
    @State private var showingResetCompleted = false
    
    private let gameService = GameService()
    
    var body: some View {
        BaseScreenView {
            VStack(spacing: GameTheme.Layout.extraLargePadding) {
                // Header
                VStack(spacing: GameTheme.Layout.smallPadding) {
                    Text("settings".localized)
                        .pageTitleStyle()
                        .padding(.top, GameTheme.Layout.mediumPadding)
                    
                    Text("settings_description".localized)
                        .gameBodyStyle()
                        .multilineTextAlignment(.center)
                }
                
                // Action Buttons
                VStack(spacing: GameTheme.Layout.mediumPadding) {
                    // Clear Game History Button
                    FullWidthActionButton(
                        title: "clear_game_history".localized,
                        icon: "clock.arrow.circlepath",
                        style: .secondary
                    ) {
                        showingClearHistoryConfirmation = true
                    }
                    
                    // Reset All Data Button
                    FullWidthActionButton(
                        title: "reset_all_data".localized,
                        icon: "trash.circle",
                        style: .danger
                    ) {
                        showingResetAllConfirmation = true
                    }
                }
                .padding(.horizontal, GameTheme.Layout.extraLargePadding)
                
                Spacer()
            }
        }
        .confirmationDialog("clear_game_history".localized, isPresented: $showingClearHistoryConfirmation, titleVisibility: .visible) {
            Button("clear_all_game_history".localized, role: .destructive) {
                clearGameHistory()
            }
            Button("cancel".localized, role: .cancel) { }
        } message: {
            Text("clear_history_warning".localized)
        }
        .confirmationDialog("reset_all_data".localized, isPresented: $showingResetAllConfirmation, titleVisibility: .visible) {
            Button("reset_everything".localized, role: .destructive) {
                resetAllData()
            }
            Button("cancel".localized, role: .cancel) { }
        } message: {
            Text("reset_data_warning".localized)
        }
        .alert("reset_complete".localized, isPresented: $showingResetCompleted) {
            Button("ok".localized) { }
        } message: {
            if let message = resetCompletedMessage {
                Text(message)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func clearGameHistory() {
        gameService.clearGameHistory()
        resetCompletedMessage = "history_cleared_message".localized
        showingResetCompleted = true
    }
    
    private func resetAllData() {
        gameService.resetAllData()
        gameState.resetGame() // Reset current game state
        resetCompletedMessage = "all_data_reset_message".localized
        showingResetCompleted = true
    }
}

#Preview {
    SettingsView(gameState: GameState())
}
