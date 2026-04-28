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
                VStack(spacing: 0) {
                    // Header with gold background
                    VStack(spacing: 4) {
                        Text("about_the_game".localized)
                            .font(GameTheme.Typography.title)
                            .foregroundColor(GameTheme.Colors.buttonText)

                        Text("version_format".localized(with: Bundle.main.appVersion))
                            .font(GameTheme.Typography.caption)
                            .foregroundColor(GameTheme.Colors.buttonText.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, GameTheme.Layout.largePadding)
                    .padding(.vertical, GameTheme.Layout.mediumPadding)
                    .background(GameTheme.Colors.accent)
                    .overlay(
                        Rectangle()
                            .frame(height: GameTheme.Layout.dividerHeight)
                            .foregroundColor(.black),
                        alignment: .bottom
                    )

                    // Content sections
                    VStack(alignment: .leading, spacing: GameTheme.Layout.largePadding) {
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
                    .background(Color.white)
                }
                .folkArtCard()
                .padding(.horizontal, GameTheme.Layout.largePadding)
                .padding(.vertical, GameTheme.Layout.mediumPadding)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
            .mask(
                VStack(spacing: 0) {
                    Color.black
                    LinearGradient(
                        colors: [.black, .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 160)
                }
            )
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


#Preview {
    AboutView()
}
