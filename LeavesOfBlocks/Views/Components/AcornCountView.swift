import SwiftUI

/// Renders one acorn icon per unit of `count`, used to visualize difficulty
/// (1 = easy, 2 = moderate, 3 = hard).
struct AcornCountView: View {
    let count: Int
    let height: CGFloat
    let spacing: CGFloat

    init(count: Int, height: CGFloat = 44, spacing: CGFloat = 6) {
        self.count = count
        self.height = height
        self.spacing = spacing
    }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<count, id: \.self) { _ in
                Image("AcornIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: height)
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        AcornCountView(count: 1)
        AcornCountView(count: 2)
        AcornCountView(count: 3)
        AcornCountView(count: 3, height: 30)
    }
    .padding()
}
