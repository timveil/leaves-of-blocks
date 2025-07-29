import SwiftUI

struct AboutView: View {
    
    // Get app version from bundle extension
    private var appVersion: String {
        return "Version \(Bundle.main.versionAndBuild)"
    }
    
    var body: some View {
        BaseScreenView {
            ScrollView {
                VStack(spacing: GameTheme.Layout.largePadding) {
                    // Header
                    VStack(spacing: GameTheme.Layout.mediumSpacing) {
                        Text("Leaves of Blocks")
                            .gameTitleStyle()
                            .padding(.top, GameTheme.Layout.mediumPadding)
                        
                        Text(appVersion)
                            .gameCaptionStyle()
                    }
                    
                    // Content sections
                    VStack(alignment: .leading, spacing: GameTheme.Layout.largePadding) {
                // About the Game
                VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                    Text("About the Game")
                        .gameTitleStyle()
                    
                    Text("Leaves of Blocks is a relaxing puzzle game that combines the joy of autumn with strategic block placement. Clear lines by filling rows and columns completely, and watch as your score grows with each successful move.\n\nFeatures beautiful block shapes, smooth animations, and progressively challenging gameplay across three difficulty modes.")
                        .gameHeadlineStyle(color: GameTheme.Colors.secondaryText)
                        .lineSpacing(6)
                }
                
                // Inspiration - Custom styled section
                VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                    Text("Inspiration")
                        .gameTitleStyle()
                    
                    VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                        Text("For Emma, Annie and Grace.  May this game serve as a momentary distraction from life's struggles, big and small.")
                            .gameHeadlineStyle(color: GameTheme.Colors.secondaryText)
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
                        .gameGradientCardStyle(
                            gradient: LinearGradient(
                                colors: [
                                    GameTheme.Colors.accent.opacity(0.3),
                                    GameTheme.Colors.accent.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            borderWidth: 1
                        )
                    }
                }
                
                // Creator Info
                VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                    Text("Creator")
                        .gameTitleStyle()
                    
                    Text("Developed with passion by Tim Veil, a software engineer and dad who believes in creating beautiful, accessible games that bring moments of joy to everyday life.\n\nBuilt entirely with SwiftUI, this game represents a commitment to crafting polished experiences that feel natural on iOS devices.")
                        .gameHeadlineStyle(color: GameTheme.Colors.secondaryText)
                        .lineSpacing(6)
                }
                
                // Technical Details
                VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                    Text("Technical Details")
                        .gameTitleStyle()
                    
                    Text("Built with pure SwiftUI and Swift for a native iOS experience. This game supports both iPhone and iPad devices running iOS 18.5 or later.\n\nEnjoy ad-free gameplay with no in-app purchases. Play offline anytime, and your high scores are automatically saved for friendly competition with yourself.")
                        .gameHeadlineStyle(color: GameTheme.Colors.secondaryText)
                        .lineSpacing(6)
                }
                    }
                    
                    Spacer(minLength: GameTheme.Layout.extraLargePadding)
                }
                .padding(.horizontal, GameTheme.Layout.largePadding)
                .padding(.bottom, 80)
            }
        }
    }
}

struct AboutSectionView: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
            Text(title)
                .gameHeadlineStyle()
            
            Text(content)
                .gameBodyStyle(color: GameTheme.Colors.secondaryText)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GameTheme.Layout.largePadding)
        .gameGradientCardStyle()
    }
}

#Preview {
    AboutView()
}
