//
//  FullWidthActionButton.swift
//  LeavesOfBlocks
//
//  Created by Tim Veil on 7/31/25.
//

import SwiftUI

/// A full-width action button component that expands to fill available width
struct FullWidthActionButton: View {
    let title: String
    let icon: String
    let style: ActionButtonStyle
    let onTap: () -> Void
    
    enum ActionButtonStyle {
        case primary
        case secondary
        case danger
        
        var backgroundColor: Color {
            switch self {
            case .primary: return GameTheme.Colors.accent
            case .secondary: return GameTheme.Colors.containerBackground
            case .danger: return GameTheme.Colors.error
            }
        }
        
        var textColor: Color {
            switch self {
            case .primary: return GameTheme.Colors.buttonText
            case .danger: return .white
            case .secondary: return GameTheme.Colors.primaryText
            }
        }
        
        var borderColor: Color? {
            switch self {
            case .secondary: return GameTheme.Colors.gridBorder
            case .primary, .danger: return nil
            }
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: GameTheme.Layout.smallSpacing) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(title)
                    .font(GameTheme.Typography.bodyFont)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(style.textColor)
            .padding(.horizontal, GameTheme.Layout.largePadding)
            .padding(.vertical, GameTheme.Layout.mediumPadding)
            .background(
                RoundedRectangle(cornerRadius: GameTheme.Layout.buttonCornerRadius)
                    .fill(style.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: GameTheme.Layout.buttonCornerRadius)
                            .stroke(
                                style.borderColor ?? Color.clear,
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: style.backgroundColor.opacity(0.3),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 16) {
        FullWidthActionButton(
            title: "Primary Button",
            icon: "star.fill",
            style: .primary
        ) {
            print("Primary tapped")
        }
        
        FullWidthActionButton(
            title: "Secondary Button",
            icon: "heart.fill",
            style: .secondary
        ) {
            print("Secondary tapped")
        }
        
        FullWidthActionButton(
            title: "Danger Button",
            icon: "trash.fill",
            style: .danger
        ) {
            print("Danger tapped")
        }
    }
    .padding()
    .background(GameTheme.Colors.primaryBackground)
}