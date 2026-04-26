import SwiftUI

struct AboutView: View {

    // MARK: - Constants

    private enum URLs {
        static let linkedin = URL(string: "https://www.linkedin.com/in/timveil?utm_source=leaves_of_blocks_app&utm_medium=ios_app&utm_campaign=about_screen")!
        static let website = URL(string: "https://www.leavesofblocks.com/?utm_source=leaves_of_blocks_app&utm_medium=ios_app&utm_campaign=about_screen")!
    }

    // MARK: - Environment

    @Environment(\.openURL) private var openURL

    var body: some View {
        BaseScreenView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: GameTheme.Layout.largePadding) {
                    // Header
                    VStack(spacing: GameTheme.Layout.smallSpacing) {
                        Image("WhitmanPortrait")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 97)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: GameTheme.Colors.cardShadow, radius: 6, x: 0, y: 3)
                            .padding(.top, GameTheme.Layout.mediumPadding)

                        Text("about_the_game".localized)
                            .pageTitleStyle()

                        Text("version_format".localized(with: Bundle.main.appVersion))
                            .font(GameTheme.Typography.caption)
                            .foregroundColor(GameTheme.Colors.tertiaryText)
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

                    creatorDescriptionView
                }
                
                // Technical Details
                VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                    Text("technical_details".localized)
                        .sectionHeaderStyle()

                    Text("technical_description".localized)
                        .sectionTextStyle(color: GameTheme.Colors.secondaryText)
                        .lineSpacing(6)
                }

                // Website
                VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                    Text("website".localized)
                        .sectionHeaderStyle()

                    Link("company_website".localized, destination: URLs.website)
                        .font(GameTheme.Typography.body)
                        .foregroundColor(GameTheme.Colors.primaryAccent)
                        .underline()
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

    // MARK: - Private Views

    /// Creator description with linked name using tappable text
    private var creatorDescriptionView: some View {
        (
            Text("developed_by_prefix".localized)
                .font(GameTheme.Typography.body)
                .foregroundColor(GameTheme.Colors.secondaryText)
            +
            Text(.init("[\("creator_name".localized)](\(URLs.linkedin))"))
                .font(GameTheme.Typography.body)
                .foregroundColor(GameTheme.Colors.primaryAccent)
                .underline()
            +
            Text("creator_description_suffix".localized)
                .font(GameTheme.Typography.body)
                .foregroundColor(GameTheme.Colors.secondaryText)
        )
        .lineSpacing(6)
        .tint(GameTheme.Colors.primaryAccent)
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
