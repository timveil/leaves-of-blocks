import SwiftUI

struct AboutView: View {
    
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
            
            // Grass at bottom (lowest z-index)
            VStack {
                Spacer()
                BlockGrassView()
                    .ignoresSafeArea(.all, edges: .bottom)
            }
            .zIndex(0)
            
            // Content layer
            ScrollView {
                VStack(spacing: GameTheme.Layout.largePadding) {
                    // Header
                    VStack(spacing: GameTheme.Layout.mediumSpacing) {
                        Text("Leaves of Blocks")
                            .font(GameTheme.Typography.title)
                            .foregroundColor(GameTheme.Colors.primaryText)
                            .padding(.top, GameTheme.Layout.mediumPadding)
                        
                        Text(appVersion)
                            .font(GameTheme.Typography.captionFont)
                            .foregroundColor(GameTheme.Colors.secondaryText)
                    }
                    
                    // Content sections
                    VStack(alignment: .leading, spacing: GameTheme.Layout.largePadding) {
                        // About the Game
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            Text("About the Game")
                                .font(GameTheme.Typography.titleFont)
                                .foregroundColor(GameTheme.Colors.primaryText)
                            
                            Text("Leaves of Blocks is a relaxing puzzle game that combines the joy of autumn with strategic block placement. Clear lines by filling rows and columns completely, and watch as your score grows with each successful move.\n\nFeatures beautiful block shapes, smooth animations, and progressively challenging gameplay across three difficulty modes.")
                                .font(GameTheme.Typography.headlineFont)
                                .foregroundColor(GameTheme.Colors.secondaryText)
                                .lineSpacing(6)
                        }
                        
                        // Inspiration - Custom styled section
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            Text("Inspiration")
                                .font(GameTheme.Typography.titleFont)
                                .foregroundColor(GameTheme.Colors.primaryText)
                            
                            VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                                Text("For Emma, Annie and Grace.  May this game serve as a momentary distraction from life’s struggles, big and small.")
                                    .font(GameTheme.Typography.headlineFont)
                                    .foregroundColor(GameTheme.Colors.secondaryText)
                                    .lineSpacing(6)
                                    .padding(.bottom, GameTheme.Layout.mediumSpacing)
                                
                                // Elegant quote styling
                                VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                                    // Quote text
                                    VStack(alignment: .leading, spacing: GameTheme.Layout.smallSpacing) {
                                        Text("Answer.")
                                            .font(.system(size: 18, weight: .medium, design: .serif))
                                            .foregroundColor(GameTheme.Colors.primaryText)
                                            .italic()
                                        
                                        Text("That you are here—that life exists and identity,")
                                            .font(.system(size: 18, weight: .regular, design: .serif))
                                            .foregroundColor(GameTheme.Colors.primaryText)
                                            .italic()
                                            .lineSpacing(4)
                                        
                                        Text("That the powerful play goes on, and you may contribute a verse..")
                                            .font(.system(size: 18, weight: .regular, design: .serif))
                                            .foregroundColor(GameTheme.Colors.primaryText)
                                            .italic()
                                            .lineSpacing(4)
                                    }
                                    
                                    // Attribution
                                    HStack {
                                        Spacer()
                                        Text("— Walt Whitman")
                                            .font(.system(size: 14, weight: .medium, design: .serif))
                                            .foregroundColor(GameTheme.Colors.secondaryText)
                                    }
                                    .padding(.top, GameTheme.Layout.smallSpacing)
                                }
                                .padding(GameTheme.Layout.mediumPadding)
                                .background(
                                    RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    GameTheme.Colors.cardBackground,
                                                    GameTheme.Colors.cardBackground.opacity(0.8)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [
                                                            GameTheme.Colors.accent.opacity(0.3),
                                                            GameTheme.Colors.accent.opacity(0.1)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 1
                                                )
                                        )
                                        .shadow(
                                            color: GameTheme.Colors.cardShadow.opacity(0.1),
                                            radius: 8,
                                            x: 0,
                                            y: 4
                                        )
                                )
                            }
                        }
                        
                        // Creator Info
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            Text("Creator")
                                .font(GameTheme.Typography.titleFont)
                                .foregroundColor(GameTheme.Colors.primaryText)
                            
                            Text("Developed with passion by Tim Veil, a software engineer and dad who believes in creating beautiful, accessible games that bring moments of joy to everyday life.\n\nBuilt entirely with SwiftUI, this game represents a commitment to crafting polished experiences that feel natural on iOS devices.")
                                .font(GameTheme.Typography.headlineFont)
                                .foregroundColor(GameTheme.Colors.secondaryText)
                                .lineSpacing(6)
                        }
                        
                        // Technical Details
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            Text("Technical Details")
                                .font(GameTheme.Typography.titleFont)
                                .foregroundColor(GameTheme.Colors.primaryText)
                            
                            Text("Built with pure SwiftUI and Swift for a native iOS experience. This game supports both iPhone and iPad devices running iOS 18.5 or later.\n\nEnjoy ad-free gameplay with no in-app purchases. Play offline anytime, and your high scores are automatically saved for friendly competition with yourself.")
                                .font(GameTheme.Typography.headlineFont)
                                .foregroundColor(GameTheme.Colors.secondaryText)
                                .lineSpacing(6)
                        }
                    }
                    
                    Spacer(minLength: GameTheme.Layout.extraLargePadding)
                }
                .padding(.horizontal, GameTheme.Layout.largePadding)
            }
            .zIndex(1)
            
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
    AboutView()
}
