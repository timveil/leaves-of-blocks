import SwiftUI

// MARK: - Whitman Quote Card

/// Reusable widget for displaying a Whitman quote. Pairs the portrait with
/// the quote text and the source poem / year. Designed to sit *outside* the
/// white content card so quotes get their own distinct treatment.
///
/// The author isn't repeated in the attribution — the portrait makes the
/// authorship obvious — so callers only supply the work title and year.
struct WhitmanQuoteCard: View {
    let quoteLines: [String]
    let title: String?
    let year: String?

    /// Single-line convenience initializer.
    init(quote: String, title: String? = nil, year: String? = nil) {
        self.quoteLines = [quote]
        self.title = title
        self.year = year
    }

    /// Multi-line convenience initializer.
    init(quoteLines: [String], title: String? = nil, year: String? = nil) {
        self.quoteLines = quoteLines
        self.title = title
        self.year = year
    }

    var body: some View {
        HStack(alignment: .center, spacing: GameTheme.Layout.mediumPadding) {
            Image("WhitmanPortrait")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: GameTheme.Layout.whitmanPortraitSize, height: GameTheme.Layout.whitmanPortraitSize)

            HStack(alignment: .top, spacing: 0) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(GameTheme.Colors.accent)
                    .frame(width: 3)

                VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                    VStack(alignment: .leading, spacing: GameTheme.Layout.smallSpacing) {
                        ForEach(quoteLines, id: \.self) { line in
                            Text(line)
                                .font(GameTheme.Typography.body)
                                .foregroundColor(GameTheme.Colors.primaryText)
                                .lineSpacing(4)
                        }
                    }

                    if title != nil || year != nil {
                        HStack {
                            Spacer()
                            HStack(spacing: 4) {
                                if let title = title {
                                    // Typographic quotes are baked in — fine for English (the
                                    // only shipping locale). Locales that use guillemets («»)
                                    // would need a Localizable.xcstrings format key here.
                                    Text("\u{201C}\(title)\u{201D}")
                                        .font(GameTheme.Typography.caption)
                                        .foregroundColor(GameTheme.Colors.secondaryText)
                                }

                                if let year = year {
                                    Text("(\(year))")
                                        .font(GameTheme.Typography.caption)
                                        .foregroundColor(GameTheme.Colors.secondaryText)
                                }
                            }
                        }
                    }
                }
                .padding(.leading, GameTheme.Layout.mediumPadding)
            }
        }
        .padding(GameTheme.Layout.mediumPadding)
        .contentCard()
    }
}

#Preview("Multi-line") {
    ZStack {
        GameTheme.Gradients.background
            .ignoresSafeArea()

        WhitmanQuoteCard(
            quoteLines: [
                "answer".localized,
                "whitman_quote_1".localized,
                "whitman_quote_2".localized
            ],
            title: "whitman_title".localized,
            year: "whitman_year".localized
        )
        .padding()
    }
}

#Preview("Single-line") {
    ZStack {
        GameTheme.Gradients.background
            .ignoresSafeArea()

        WhitmanQuoteCard(
            quote: "settings_quote".localized,
            title: "settings_title".localized,
            year: "settings_year".localized
        )
        .padding()
    }
}
