import SwiftUI

extension View {
    
    // MARK: - Conditional Modifiers
    
    /// Conditionally applies a modifier to a view
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Conditionally applies one of two modifiers to a view
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        ifTrue: (Self) -> TrueContent,
        ifFalse: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTrue(self)
        } else {
            ifFalse(self)
        }
    }
    
    // MARK: - Debug Helpers
    
    /// Prints the frame of a view for debugging
    func debugFrame(_ label: String = "Frame") -> some View {
        self.background(
            GeometryReader { geometry in
                Color.clear.onAppear {
                    if AppConfiguration.FeatureFlags.enableDebugMode {
                        BuildConfiguration.log("\(label): \(geometry.frame(in: .global))", level: .debug)
                    }
                }
            }
        )
    }
    
    /// Adds a colored border for debugging layout issues
    func debugBorder(_ color: Color = .red, width: CGFloat = 1) -> some View {
        self.overlay(
            Rectangle()
                .stroke(color, lineWidth: width)
                .opacity(AppConfiguration.FeatureFlags.enableDebugMode ? 1 : 0)
        )
    }
    
    // MARK: - Animation Helpers
    
    /// Applies a spring animation with consistent timing
    func gameAnimation<V: Equatable>(value: V) -> some View {
        self.animation(GameTheme.Animations.mediumSpring, value: value)
    }
    
    /// Fast animation for immediate feedback
    func fastAnimation<V: Equatable>(value: V) -> some View {
        self.animation(GameTheme.Animations.fastSpring, value: value)
    }
    
    /// Smooth animation for transitions
    func smoothAnimation<V: Equatable>(value: V) -> some View {
        self.animation(GameTheme.Animations.smoothEase, value: value)
    }
    
    /// Line clearing animation
    func lineClearAnimation<V: Equatable>(value: V) -> some View {
        self.animation(GameTheme.Animations.lineClearAnimation, value: value)
    }
    
    /// Applies a bounce effect when a value changes
    func bounceEffect<V: Equatable>(value: V, scale: CGFloat = 1.1) -> some View {
        self.scaleEffect(1.0)
            .animation(GameTheme.Animations.fastSpring, value: value)
    }
}