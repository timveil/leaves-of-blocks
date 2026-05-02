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
    var gameCenterService: GameCenterService = .shared
    @State private var showingResetOptions = false
    @State private var showingClearHistoryConfirmation = false
    @State private var showingResetAllConfirmation = false
    @State private var resetCompletedMessage: String?
    @State private var showingResetCompleted = false
    @State private var gameCenterEnabled: Bool = GameCenterPreference.isEnabled

    var body: some View {
        BaseScreenView {
            ScrollView {
                VStack(alignment: .leading, spacing: GameTheme.Layout.mediumPadding) {
                    StrokedTitle(text: "settings".localized)
                        .padding(.bottom, GameTheme.Layout.smallSpacing)

                    WhitmanQuoteCard(
                        quote: "settings_quote".localized,
                        title: "settings_title".localized,
                        year: "settings_year".localized
                    )

                    VStack(alignment: .leading, spacing: GameTheme.Layout.mediumPadding) {
                        Toggle(isOn: $gameCenterEnabled) {
                            Text("game_center_enable".localized)
                                .font(GameTheme.Typography.body)
                                .foregroundColor(GameTheme.Colors.primaryText)
                        }
                        .tint(GameTheme.Colors.primaryAccent)
                        .accessibilityIdentifier("game_center_toggle")

                        Text("game_center_enable_description".localized)
                            .font(GameTheme.Typography.caption)
                            .foregroundColor(GameTheme.Colors.secondaryText)
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if gameCenterService.isAuthenticated {
                            FullWidthActionButton(
                                title: "view_game_center".localized,
                                style: .secondary,
                                accessibilityId: "view_game_center_button"
                            ) {
                                gameCenterService.presentDashboard()
                            }
                        }
                    }
                    .padding(GameTheme.Layout.largePadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(GameTheme.Colors.cardBackground)
                    .folkArtCard()

                    VStack(spacing: GameTheme.Layout.mediumPadding) {
                        FullWidthActionButton(
                            title: "clear_game_history".localized,
                            style: .warning
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
                    .padding(.top, GameTheme.Layout.smallSpacing)
                }
                .padding(.horizontal, GameTheme.Layout.largePadding)
                .padding(.vertical, GameTheme.Layout.mediumPadding)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
        }
        .onChange(of: gameCenterEnabled) { _, newValue in
            GameCenterPreference.isEnabled = newValue
            if newValue {
                gameCenterService.authenticateIfEnabled()
            } else {
                gameCenterService.userDisabledPreference()
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
