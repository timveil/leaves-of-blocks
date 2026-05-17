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
            ScrollView {
                VStack(alignment: .leading, spacing: GameTheme.Layout.mediumPadding) {
                    VStack(alignment: .leading, spacing: 4) {
                        StrokedTitle(text: "about_the_game".localized)
                            .accessibilityIdentifier("about_screen")

                        Text("version_format".localized(with: Bundle.main.appVersion))
                            .font(GameTheme.Typography.caption)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.6), radius: 1, x: 0, y: 0)
                            .padding(.leading, 2)
                    }
                    .padding(.bottom, GameTheme.Layout.smallSpacing)

                    WhitmanQuoteCard(
                        quoteLines: [
                            "answer".localized,
                            "whitman_quote_1".localized,
                            "whitman_quote_2".localized
                        ],
                        title: "whitman_title".localized,
                        year: "whitman_year".localized
                    )

                    // Main content card
                    VStack(alignment: .leading, spacing: GameTheme.Layout.largePadding) {
                        // Inspiration
                        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                            Text("inspiration".localized)
                                .sectionHeaderStyle()

                            Text("inspiration_quote".localized)
                                .sectionTextStyle(color: GameTheme.Colors.secondaryText)
                                .lineSpacing(6)
                        }

                        // Dedication
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
                    .padding(GameTheme.Layout.largePadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentCard()
                }
                .padding(.horizontal, GameTheme.Layout.largePadding)
                .padding(.vertical, GameTheme.Layout.mediumPadding)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
            .scrollFadeMask()
        }
    }

    // MARK: - Private Views

    /// Creator description with linked name using tappable text.
    private var creatorDescriptionView: some View {
        var attributed = AttributedString("developed_by_prefix".localized)

        var name = AttributedString("creator_name".localized)
        name.link = URLs.linkedin
        name.underlineStyle = .single
        name.foregroundColor = GameTheme.Colors.primaryAccent
        attributed.append(name)

        attributed.append(AttributedString("creator_description_suffix".localized))

        return Text(attributed)
            .font(GameTheme.Typography.body)
            .foregroundColor(GameTheme.Colors.secondaryText)
            .lineSpacing(6)
            .tint(GameTheme.Colors.primaryAccent)
    }
}


#Preview {
    AboutView()
}
