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
                    Text("Settings")
                        .pageTitleStyle()
                        .padding(.top, GameTheme.Layout.mediumPadding)
                    
                    Text("Manage your game data and preferences")
                        .gameBodyStyle()
                        .multilineTextAlignment(.center)
                }
                
                // Action Buttons
                VStack(spacing: GameTheme.Layout.mediumPadding) {
                    // Clear Game History Button
                    FullWidthActionButton(
                        title: "Clear Game History",
                        icon: "clock.arrow.circlepath",
                        style: .secondary
                    ) {
                        showingClearHistoryConfirmation = true
                    }
                    
                    // Reset All Data Button
                    FullWidthActionButton(
                        title: "Reset All Data",
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
        .confirmationDialog("Clear Game History", isPresented: $showingClearHistoryConfirmation, titleVisibility: .visible) {
            Button("Clear All Game History", role: .destructive) {
                clearGameHistory()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all your saved games and statistics. This action cannot be undone.")
        }
        .confirmationDialog("Reset All Data", isPresented: $showingResetAllConfirmation, titleVisibility: .visible) {
            Button("Reset Everything", role: .destructive) {
                resetAllData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete ALL game data including history, high scores, and preferences. This action cannot be undone.")
        }
        .alert("Reset Complete", isPresented: $showingResetCompleted) {
            Button("OK") { }
        } message: {
            if let message = resetCompletedMessage {
                Text(message)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func clearGameHistory() {
        gameService.clearGameHistory()
        resetCompletedMessage = "Game history has been cleared successfully."
        showingResetCompleted = true
    }
    
    private func resetAllData() {
        gameService.resetAllData()
        gameState.resetGame() // Reset current game state
        resetCompletedMessage = "All data has been reset successfully."
        showingResetCompleted = true
    }
}

#Preview {
    SettingsView(gameState: GameState())
}
