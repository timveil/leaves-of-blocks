import SwiftUI

// MARK: - Game Card Component

struct GameCardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .gameCardStyle()
    }
}