//
//  ToolbarView.swift
//  LeavesOfBlocks
//
//  Created by Tim Veil on 7/29/25.
//

import SwiftUI

struct ToolbarView: View {
    private static let iconFont = Font.system(size: 20, weight: .semibold)
    
    let currentScreen: AppScreen
    let onGoHome: () -> Void
    let onShowAbout: () -> Void
    let onShowHowToPlay: () -> Void
    let onNewGame: () -> Void
    
    var body: some View {
        HStack {
            // Home icon (always visible, but disabled on home screen)
            Button(action: currentScreen == .home ? {} : onGoHome) {
                Image(systemName: "house.fill")
                    .font(Self.iconFont)
                    .foregroundColor(currentScreen == .home ? GameTheme.Colors.blockBlue.opacity(0.4) : GameTheme.Colors.blockBlue)
            }
            .disabled(currentScreen == .home)
            
            Spacer()
            
            // Right side icons with proper spacing
            HStack(spacing: GameTheme.Layout.largePadding) {
                // New Game button (always visible)
                Button(action: onNewGame) {
                    Image(systemName: "play.fill")
                        .font(Self.iconFont)
                        .foregroundColor(GameTheme.Colors.accent)
                }
                
                // Info icon (About) - using gear for better visual balance
                Button(action: onShowAbout) {
                    Image(systemName: "gear")
                        .font(Self.iconFont)
                        .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                }
                
                // Help icon (How to Play)
                Button(action: onShowHowToPlay) {
                    Image(systemName: "questionmark")
                        .font(Self.iconFont)
                        .foregroundColor(GameTheme.Colors.blockGreen)
                }
            }
        }
        .padding(.horizontal, GameTheme.Layout.largePadding)
        .padding(.vertical, GameTheme.Layout.mediumPadding)
        .background(
            LinearGradient(
                colors: [GameTheme.Colors.cardBackground, GameTheme.Colors.cardBackground.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(GameTheme.Colors.gridBorder.opacity(0.3)),
            alignment: .bottom
        )
    }
}
