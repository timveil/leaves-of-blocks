import SwiftUI

// MARK: - Whitman Sticker

/// Whitman portrait on a white circle with a folk-art black border.
///
/// The portrait is shifted slightly downward inside the circular sticker so
/// the hat clears the upper arc — the trade-off is that the bottom of the
/// portrait gets clipped by the circle's lower curve, which reads better than
/// cropping the iconic hat. `topOffsetRatio` controls the downward shift as
/// a fraction of the sticker size.
struct WhitmanSticker: View {
    var size: CGFloat = 180
    var topOffsetRatio: CGFloat = 0.08

    var body: some View {
        ZStack {
            Circle().fill(Color.white)

            Image("WhitmanPortrait")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .offset(y: size * topOffsetRatio)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle().stroke(Color.black, lineWidth: GameTheme.Layout.cardBorderWidth)
        )
    }
}

#Preview {
    ZStack {
        GameTheme.Gradients.background
            .ignoresSafeArea()

        VStack(spacing: 24) {
            WhitmanSticker(size: 120)
            WhitmanSticker(size: 180)
            WhitmanSticker(size: 240)
        }
    }
}
