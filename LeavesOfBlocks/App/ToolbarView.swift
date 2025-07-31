//
//  ToolbarView.swift
//  LeavesOfBlocks
//
//  Created by Tim Veil on 7/29/25.
//

import SwiftUI

struct ToolbarView: View {
    private static let iconFont = GameTheme.Typography.primaryHeader
    
    let currentScreen: AppScreen
    let onGoHome: () -> Void
    let onShowAbout: () -> Void
    let onShowHowToPlay: () -> Void
    let onShowSettings: () -> Void
    let onNewGame: () -> Void
    
    var body: some View {
        HStack {
            // Home icon (always visible, but disabled on home screen)
            Button(action: currentScreen == .home ? {} : onGoHome) {
                Image(systemName: "house.circle.fill")
                    .font(Self.iconFont)
                    .foregroundColor(currentScreen == .home ? GameTheme.Colors.blockGreen.opacity(0.4) : GameTheme.Colors.blockGreen)
            }
            .disabled(currentScreen == .home)
            
            Spacer()
            
            // Right side icons with proper spacing
            HStack(spacing: GameTheme.Layout.largePadding) {
                // New Game button (always visible)
                Button(action: onNewGame) {
                    Image(systemName: "play.circle.fill")
                        .font(Self.iconFont)
                        .foregroundColor(GameTheme.Colors.blockGreen)
                }
                
                // Help icon (How to Play)
                Button(action: onShowHowToPlay) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(Self.iconFont)
                        .foregroundColor(GameTheme.Colors.blockGreen)
                }
                
                // Info icon (About)
                Button(action: onShowAbout) {
                    Image(systemName: "info.circle.fill")
                        .font(Self.iconFont)
                        .foregroundColor(GameTheme.Colors.blockGreen)
                }
                
                // Settings icon
                Button(action: onShowSettings) {
                    Image(systemName: "gearshape.circle.fill")
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

#Preview {
    VStack {
        ToolbarView(
            currentScreen: .home,
            onGoHome: { print("Go Home") },
            onShowAbout: { print("Show About") },
            onShowHowToPlay: { print("Show How to Play") },
            onShowSettings: { print("Show Settings") },
            onNewGame: { print("New Game") }
        )
        
        Spacer()
    }
    .background(GameTheme.Colors.primaryBackground)
}
