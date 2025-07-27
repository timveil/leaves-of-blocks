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
                        // App Icon or Logo representation
                        VStack(spacing: GameTheme.Layout.smallSpacing) {
                            HStack(spacing: 8) {
                                // Represent the app icon with blocks
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(GameTheme.Colors.blockOrange)
                                    .frame(width: 40, height: 40)
                                
                                VStack(spacing: 4) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(red: 0.3, green: 0.7, blue: 0.6))
                                        .frame(width: 40, height: 40)
                                    
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(GameTheme.Colors.blockYellow)
                                        .frame(width: 40, height: 40)
                                }
                                
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(GameTheme.Colors.blockGreen)
                                        .frame(width: 40, height: 40)
                                    
                                    // Simple leaf representation
                                    VStack(spacing: -4) {
                                        HStack(spacing: -2) {
                                            Ellipse()
                                                .fill(GameTheme.Colors.grassSecondary)
                                                .frame(width: 10, height: 16)
                                                .rotationEffect(.degrees(-15))
                                            
                                            Ellipse()
                                                .fill(GameTheme.Colors.grassPrimary)
                                                .frame(width: 12, height: 18)
                                                .rotationEffect(.degrees(10))
                                        }
                                        
                                        Ellipse()
                                            .fill(GameTheme.Colors.grassTertiary)
                                            .frame(width: 8, height: 14)
                                    }
                                }
                            }
                        }
                        .padding(.top, GameTheme.Layout.largePadding)
                        
                        Text("Leaves of Blocks")
                            .font(GameTheme.Typography.title)
                            .foregroundStyle(GameTheme.Gradients.text)
                        
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
                        
                        // Inspiration
                        AboutSectionView(
                            title: "Inspiration",
                            content: """
                            For Emma, Annie and Grace.
                            
                            \"Answer.
                            That you are here—that life exists and identity,
                            That the powerful play goes on, and you may contribute a verse..\"
                            """
                        )
                        
                        // Creator Info
                        AboutSectionView(
                            title: "Creator",
                            content: """
                            Developed with passion by Timothy Veil, a software engineer who believes in creating beautiful, accessible games that bring moments of joy to everyday life.
                            
                            Built entirely with SwiftUI, this game represents a commitment to crafting polished experiences that feel natural on iOS devices.
                            """
                        )
                        
                        // Technical Details
                        AboutSectionView(
                            title: "Technical Details",
                            content: """
                            Built with pure SwiftUI and Swift for a native iOS experience. This game supports both iPhone and iPad devices running iOS 18.5 or later.
                            
                            Enjoy ad-free gameplay with no in-app purchases. Play offline anytime, and your high scores are automatically saved for friendly competition with yourself.
                            """
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
