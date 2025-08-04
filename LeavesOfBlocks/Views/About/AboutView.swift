import SwiftUI

struct AboutView: View {
    
    // Get app version from bundle extension
    private var appVersion: String {
        return "Version \(Bundle.main.versionAndBuild)"
    }
    
    var body: some View {
        BaseScreenView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: GameTheme.Layout.largePadding) {
                    // Header
                    VStack(spacing: GameTheme.Layout.mediumSpacing) {
                        Text("about_the_game".localized)
                            .pageTitleStyle()
                            .padding(.top, GameTheme.Layout.mediumPadding)
                    }
                    
                    // Content sections
                    VStack(alignment: .leading, spacing: GameTheme.Layout.largePadding) {
                
                // Whitman Quote - Move to top
                QuoteView(
                    quoteLines: [
                        "answer".localized,
                        "whitman_quote_1".localized,
                        "whitman_quote_2".localized
                    ],
                    author: "whitman_author".localized,
                    title: "whitman_title".localized,
                    year: "whitman_year".localized
                )
                
                // Inspiration
                VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                    Text("inspiration".localized)
                        .sectionHeaderStyle()
                    
                    Text("inspiration_quote".localized)
                        .sectionTextStyle(color: GameTheme.Colors.secondaryText)
                        .lineSpacing(6)
                }
                
                // Dedication - New section
                VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                    Text("dedication".localized)
                        .sectionHeaderStyle()
                    
                    Text("dedication_text".localized)
                        .sectionTextStyle(color: GameTheme.Colors.secondaryText)
                        .lineSpacing(6)
                }
                
                // Creator Info
                VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                    Text("creator".localized)
                        .sectionHeaderStyle()
                    
                    Text("creator_description".localized)
                        .sectionTextStyle(color: GameTheme.Colors.secondaryText)
                        .lineSpacing(6)
                }
                
                // Technical Details
                VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                    Text("technical_details".localized)
                        .sectionHeaderStyle()
                    
                    Text("technical_description".localized)
                        .sectionTextStyle(color: GameTheme.Colors.secondaryText)
                        .lineSpacing(6)
                }
                    }
                    
                    Spacer(minLength: GameTheme.Layout.extraLargePadding)
                }
                .padding(.horizontal, GameTheme.Layout.largePadding)
                .padding(.bottom, 80)
                }
                .frame(height: geometry.size.height - 100) // Leave space for grass
            }
        }
    }
}

private struct AboutSectionView: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
            Text(title)
                .sectionTextStyle()
            
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
