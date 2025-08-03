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
    let attribution: String
    var backgroundColor: Color = GameTheme.Colors.blockGreen
    
    /// Creates a quote view with a single line of text
    init(quote: String, attribution: String, backgroundColor: Color = GameTheme.Colors.blockGreen) {
        self.quoteLines = [quote]
        self.attribution = attribution
        self.backgroundColor = backgroundColor
    }
    
    /// Creates a quote view with multiple lines of text
    init(quoteLines: [String], attribution: String, backgroundColor: Color = GameTheme.Colors.blockGreen) {
        self.quoteLines = quoteLines
        self.attribution = attribution
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.Layout.mediumSpacing) {
            // Quote text
            VStack(alignment: .leading, spacing: GameTheme.Layout.smallSpacing) {
                ForEach(quoteLines, id: \.self) { line in
                    Text(line)
                        .font(GameTheme.Typography.body)
                        .foregroundColor(GameTheme.Colors.primaryText)
                        .lineSpacing(4)
                }
            }
            
            // Attribution
            HStack {
                Spacer()
                Text(attribution)
                    .font(GameTheme.Typography.body)
                    .foregroundColor(GameTheme.Colors.primaryText)
            }
            .padding(.top, GameTheme.Layout.smallSpacing)
        }
        .padding(GameTheme.Layout.mediumPadding)
        .background(
            RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                .fill(backgroundColor)
        )
    }
}

#Preview("Single Line Quote") {
    QuoteView(
        quote: "The day erased, the lesson done",
        attribution: "— Walt Whitman, \"A Clear Midnight\" (1880)"
    )
    .padding()
}

#Preview("Multi-Line Quote") {
    QuoteView(
        quoteLines: [
            "Answer.",
            "That you are here—that life exists and identity,",
            "That the powerful play goes on, and you may contribute a verse."
        ],
        attribution: "— Walt Whitman"
    )
    .padding()
}