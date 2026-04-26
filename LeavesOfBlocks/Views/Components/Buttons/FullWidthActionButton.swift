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
    let accessibilityId: String?
    let onTap: () -> Void
    
    init(title: String, icon: String, style: ActionButtonStyle, accessibilityId: String? = nil, onTap: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.accessibilityId = accessibilityId
        self.onTap = onTap
    }
    
    enum ActionButtonStyle {
        case primary
        case secondary
        case danger
        case success
        
        var backgroundColor: Color {
            switch self {
            case .primary: return GameTheme.Colors.primaryAccent
            case .secondary: return GameTheme.Colors.containerBackground
            case .danger: return GameTheme.Colors.error
            case .success: return GameTheme.Colors.success
            }
        }
        
        var textColor: Color {
            switch self {
            case .primary: return GameTheme.Colors.buttonText
            case .danger: return GameTheme.Colors.buttonText
            case .secondary: return GameTheme.Colors.primaryText
            case .success: return GameTheme.Colors.buttonText
            }
        }
        
        var borderColor: Color? {
            switch self {
            case .secondary: return GameTheme.Colors.gridBorder
            case .primary, .danger, .success: return nil
            }
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: GameTheme.Layout.smallSpacing) {
                Image(systemName: icon)
                    .font(GameTheme.Typography.body)
                
                Text(title)
                    .font(GameTheme.Typography.body)
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
        .accessibilityIdentifier(accessibilityId ?? "")
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