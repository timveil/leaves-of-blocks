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
    var gameState: GameState
    @State private var showingResetOptions = false
    @State private var showingClearHistoryConfirmation = false
    @State private var showingResetAllConfirmation = false
    @State private var resetCompletedMessage: String?
    @State private var showingResetCompleted = false

    var body: some View {
        BaseScreenView {
            ScrollView {
                GoldHeaderCard(title: "settings".localized) {
                    VStack(spacing: GameTheme.Layout.largePadding) {
                        QuoteView(
                            quote: "settings_quote".localized,
                            author: "settings_author".localized,
                            title: "settings_title".localized,
                            year: "settings_year".localized
                        )

                        Spacer()
                            .frame(height: GameTheme.Layout.mediumPadding)

                        VStack(spacing: GameTheme.Layout.mediumPadding) {
                            FullWidthActionButton(
                                title: "clear_game_history".localized,
                                style: .secondary
                            ) {
                                showingClearHistoryConfirmation = true
                            }

                            FullWidthActionButton(
                                title: "reset_all_data".localized,
                                style: .danger
                            ) {
                                showingResetAllConfirmation = true
                            }
                        }
                    }
                }
                .padding(.horizontal, GameTheme.Layout.largePadding)
                .padding(.vertical, GameTheme.Layout.mediumPadding)
            }
            .scrollIndicators(.hidden)
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
        gameState.clearGameHistory()
        resetCompletedMessage = "history_cleared_message".localized
        showingResetCompleted = true
    }

    private func resetAllData() {
        gameState.resetAllData()
        resetCompletedMessage = "all_data_reset_message".localized
        showingResetCompleted = true
    }
}

#Preview {
    SettingsView(gameState: GameState())
}
