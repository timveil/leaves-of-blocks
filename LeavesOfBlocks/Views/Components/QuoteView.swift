//
//  QuoteView.swift
//  LeavesOfBlocks
//
//  Created by Tim Veil on 8/3/25.
//

import SwiftUI

/// A reusable component for displaying quotes with attribution in a styled container.
///
/// This view provides a consistent appearance for quotes throughout the app,
/// featuring a green background, proper text styling, and right-aligned attribution.
struct QuoteView: View {
    let quoteLines: [String]
    let author: String
    let title: String?
    let year: String?
    var backgroundColor: Color = GameTheme.Colors.blockGreen
    
    /// Creates a quote view with a single line of text and separate attribution fields
    init(quote: String, author: String, title: String? = nil, year: String? = nil, backgroundColor: Color = GameTheme.Colors.blockGreen) {
        self.quoteLines = [quote]
        self.author = author
        self.title = title
        self.year = year
        self.backgroundColor = backgroundColor
    }
    
    /// Creates a quote view with multiple lines of text and separate attribution fields
    init(quoteLines: [String], author: String, title: String? = nil, year: String? = nil, backgroundColor: Color = GameTheme.Colors.blockGreen) {
        self.quoteLines = quoteLines
        self.author = author
        self.title = title
        self.year = year
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(GameTheme.Colors.accent)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
                VStack(alignment: .leading, spacing: GameTheme.Layout.smallSpacing) {
                    ForEach(quoteLines, id: \.self) { line in
                        Text(line)
                            .font(GameTheme.Typography.body.italic())
                            .foregroundColor(GameTheme.Colors.secondaryText)
                            .lineSpacing(4)
                    }
                }

                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("— \(author)")
                            .font(GameTheme.Typography.caption)
                            .foregroundColor(GameTheme.Colors.primaryText)

                        if title != nil || year != nil {
                            HStack(spacing: 4) {
                                if let title = title {
                                    Text("\"\(title)\"")
                                        .font(GameTheme.Typography.caption)
                                        .foregroundColor(GameTheme.Colors.tertiaryText)
                                }

                                if let year = year {
                                    Text("(\(year))")
                                        .font(GameTheme.Typography.caption)
                                        .foregroundColor(GameTheme.Colors.tertiaryText)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.leading, GameTheme.Layout.mediumPadding)
        }
    }
}

#Preview("Single Line Quote") {
    QuoteView(
        quote: "settings_quote".localized,
        author: "settings_author".localized,
        title: "settings_title".localized,
        year: "settings_year".localized
    )
    .padding()
}

#Preview("Multi-Line Quote") {
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
    .padding()
}

#Preview("All Attribution Components") {
    QuoteView(
        quote: "how_to_play_quote".localized,
        author: "how_to_play_author".localized,
        title: "how_to_play_title".localized,
        year: "how_to_play_year".localized
    )
    .padding()
}

#Preview("Author Only") {
    QuoteView(
        quote: "settings_quote".localized,
        author: "settings_author".localized
    )
    .padding()
}

#Preview("Compact Width Layout") {
    VStack(spacing: GameTheme.Layout.mediumSpacing) {
        QuoteView(
            quote: "settings_quote".localized,
            author: "settings_author".localized,
            title: "settings_title".localized,
            year: "settings_year".localized
        )
        
        QuoteView(
            quote: "settings_quote".localized,
            author: "settings_author".localized
        )
    }
    .padding()
    .frame(width: 280) // Simulate narrow device width
}
