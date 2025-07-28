import SwiftUI

struct AboutView: View {
    let onDismiss: () -> Void
    
    // Get app version from bundle
    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "Version \(version) (\(build))"
        }
        return "Version 1.0"
    }
    
    var body: some View {
        ZStack {
            // Background
            GameBackgroundView()
            
            ScrollView {
                VStack(spacing: GameTheme.Layout.largePadding) {
                    // Header
                    VStack(spacing: GameTheme.Layout.mediumSpacing) {
                        Text("Leaves of Blocks")
                            .font(GameTheme.Typography.title)
                            .foregroundStyle(GameTheme.Gradients.text)
                            .padding(.top, GameTheme.Layout.largePadding)
                        
                        Text(appVersion)
                            .font(GameTheme.Typography.captionFont)
                            .foregroundColor(GameTheme.Colors.secondaryText)
                    }
                    
                    // Content sections
                    VStack(spacing: GameTheme.Layout.sectionSpacing) {
                        // About the Game
                        AboutSectionView(
                            title: "About the Game",
                            content: """
                            Leaves of Blocks is a relaxing puzzle game that combines the joy of autumn with strategic block placement. Clear lines by filling rows and columns completely, and watch as your score grows with each successful move.
                            
                            Features beautiful block shapes, smooth animations, and progressively challenging gameplay across three difficulty modes.
                            """
                        )
                        
                        // Inspiration - Custom styled section
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            Text("Inspiration")
                                .font(GameTheme.Typography.headlineFont)
                                .foregroundColor(GameTheme.Colors.primaryText)
                            
                            VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                                Text("For Emma, Annie and Grace.")
                                    .font(GameTheme.Typography.bodyFont)
                                    .foregroundColor(GameTheme.Colors.secondaryText)
                                    .lineSpacing(4)
                                    .padding(.bottom, GameTheme.Layout.mediumSpacing)
                                
                                // Styled quote
                                VStack(alignment: .leading, spacing: GameTheme.Layout.smallSpacing) {
                                    HStack(alignment: .top) {
                                        Text("")
                                            .font(.system(size: 32, weight: .light))
                                            .foregroundColor(GameTheme.Colors.accent.opacity(0.6))
                                            .offset(y: -8)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Answer.")
                                                .font(GameTheme.Typography.bodyFont)
                                                .foregroundColor(GameTheme.Colors.accent)
                                                .italic()
                                            
                                            Text("That you are here—that life exists and identity,")
                                                .font(GameTheme.Typography.bodyFont)
                                                .foregroundColor(GameTheme.Colors.accent)
                                                .italic()
                                            
                                            Text("That the powerful play goes on, and you may contribute a verse..")
                                                .font(GameTheme.Typography.bodyFont)
                                                .foregroundColor(GameTheme.Colors.accent)
                                                .italic()
                                        }
                                        
                                        Spacer()
                                    }
                                    
                                    HStack {
                                        Spacer()
                                        Text("— Walt Whitman")
                                            .font(GameTheme.Typography.captionFont)
                                            .foregroundColor(GameTheme.Colors.secondaryText)
                                            .italic()
                                    }
                                    .padding(.top, GameTheme.Layout.smallSpacing)
                                }
                                .padding(GameTheme.Layout.mediumPadding)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(GameTheme.Colors.accent.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(GameTheme.Colors.accent.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(GameTheme.Layout.largePadding)
                        .background(
                            RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                                .fill(GameTheme.Colors.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                                        .stroke(
                                            LinearGradient(
                                                colors: GameTheme.Colors.cardBorderGradient,
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                                .shadow(
                                    color: GameTheme.Colors.cardShadow,
                                    radius: GameTheme.Layout.shadowRadius,
                                    x: 0,
                                    y: GameTheme.Layout.shadowOffset
                                )
                        )
                        
                        // Creator Info
                        AboutSectionView(
                            title: "Creator",
                            content: "Developed with passion by Tim Veil, a software engineer and dad who believes in creating beautiful, accessible games that bring moments of joy to everyday life.\n\nBuilt entirely with SwiftUI, this game represents a commitment to crafting polished experiences that feel natural on iOS devices."
                        )
                        
                        // Technical Details
                        AboutSectionView(
                            title: "Technical Details",
                            content: "Built with pure SwiftUI and Swift for a native iOS experience. This game supports both iPhone and iPad devices running iOS 18.5 or later.\n\nEnjoy ad-free gameplay with no in-app purchases. Play offline anytime, and your high scores are automatically saved for friendly competition with yourself."
                        )
                    }
                    
                    Spacer(minLength: GameTheme.Layout.extraLargePadding)
                }
                .padding(.horizontal, GameTheme.Layout.largePadding)
            }
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(GameTheme.Colors.primaryText)
                            .background(
                                Circle()
                                    .fill(GameTheme.Colors.primaryBackground.opacity(0.8))
                                    .frame(width: 44, height: 44)
                            )
                    }
                    .padding(.trailing, GameTheme.Layout.largePadding)
                    .padding(.top, GameTheme.Layout.mediumPadding)
                }
                
                Spacer()
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct AboutSectionView: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
            Text(title)
                .font(GameTheme.Typography.headlineFont)
                .foregroundColor(GameTheme.Colors.primaryText)
            
            Text(content)
                .font(GameTheme.Typography.bodyFont)
                .foregroundColor(GameTheme.Colors.secondaryText)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GameTheme.Layout.largePadding)
        .background(
            RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                .fill(GameTheme.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: GameTheme.Colors.cardBorderGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(
                    color: GameTheme.Colors.cardShadow,
                    radius: GameTheme.Layout.shadowRadius,
                    x: 0,
                    y: GameTheme.Layout.shadowOffset
                )
        )
    }
}

#Preview {
    AboutView(onDismiss: {})
}
