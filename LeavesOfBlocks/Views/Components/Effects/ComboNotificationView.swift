import SwiftUI

// MARK: - Combo Notification Component

struct ComboNotificationView: View {
    let comboCount: Int
    let bonusPoints: Int
    @State private var isVisible: Bool = false
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    @State private var yOffset: CGFloat = 0
    
    private var comboText: String {
        if comboCount >= 5 {
            return "mega_combo".localized
        } else if comboCount >= 3 {
            return "combo_excited".localized
        } else {
            return "combo".localized
        }
    }
    
    private var comboHeaderGradient: LinearGradient {
        if comboCount >= 5 {
            return LinearGradient(
                colors: [GameTheme.Colors.lineCompletionPrimary, GameTheme.Colors.lineCompletionSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if comboCount >= 3 {
            return LinearGradient(
                colors: [GameTheme.Colors.secondaryAccent, GameTheme.Colors.secondaryAccent.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [GameTheme.Colors.primaryAccent, GameTheme.Colors.primaryAccent.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with combo text (similar to ScoreDisplayView header style)
            Text(comboText)
                .font(GameTheme.Typography.fontMedium)
                .fontWeight(.bold)
                .foregroundColor(GameTheme.Colors.buttonText)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, GameTheme.Layout.largePadding)
                .padding(.vertical, GameTheme.Layout.mediumPadding)
                .background(comboHeaderGradient)
            
            // Content area with game styling (similar to ScoreDisplayView content)
            VStack(spacing: GameTheme.Layout.smallSpacing) {
                // Lines cleared indicator
                Text("lines_cleared_format".localized(with: comboCount))
                    .font(GameTheme.Typography.fontSmall)
                    .foregroundColor(GameTheme.Colors.secondaryText)
                    .padding(.top, GameTheme.Layout.mediumPadding)
                
                // Bonus points with larger, prominent display
                Text("+\(bonusPoints)")
                    .font(GameTheme.Typography.fontLarge)
                    .fontWeight(.bold)
                    .foregroundColor(GameTheme.Colors.primaryText)
                    .padding(.bottom, GameTheme.Layout.mediumPadding)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, GameTheme.Layout.largePadding)
            .background(GameTheme.Colors.cardBackground)
        }
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [GameTheme.Colors.accent.opacity(0.4), GameTheme.Colors.accent.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(
            color: GameTheme.Colors.cardShadow.opacity(0.3),
            radius: 12,
            x: 0,
            y: 6
        )
        .frame(maxWidth: 280) // Consistent width with other overlays
        .scaleEffect(scale)
        .opacity(opacity)
        .offset(y: yOffset)
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Entry animation using theme animations
        withAnimation(GameTheme.Animations.springAnimation) {
            scale = 1.0
            opacity = 1.0
            isVisible = true
        }
        
        // Hold for a moment, then exit with theme animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(GameTheme.Animations.smoothEase) {
                opacity = 0.0
                yOffset = -20
                scale = 0.95
            }
        }
    }
}

// MARK: - Combo Notification Manager

struct ComboNotificationOverlay: View {
    @ObservedObject var gameState: GameState
    @State private var activeCombo: (count: Int, bonus: Int)?
    @State private var notificationId: UUID = UUID()
    
    var body: some View {
        ZStack {
            if let combo = activeCombo {
                ComboNotificationView(
                    comboCount: combo.count,
                    bonusPoints: combo.bonus
                )
                .id(notificationId) // Force recreation for each new combo
                .onAppear {
                    // Clear the combo after animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        activeCombo = nil
                    }
                }
            }
        }
        .onChange(of: gameState.currentCombo) { _, newCombo in
            // Only show notification for combos of 2+ lines
            if newCombo >= 2 {
                let bonusPoints = (newCombo - 1) * GameTheme.GameConfig.comboBonus
                activeCombo = (count: newCombo, bonus: bonusPoints)
                notificationId = UUID() // Generate new ID to force recreation
            }
        }
    }
}

#Preview {
    ComboNotificationPreviewContainer()
}

// MARK: - Interactive Preview Container

struct ComboNotificationPreviewContainer: View {
    @State private var showCombo2: Bool = false
    @State private var showCombo3: Bool = false
    @State private var showCombo5: Bool = false
    @State private var comboKey2: UUID = UUID()
    @State private var comboKey3: UUID = UUID()
    @State private var comboKey5: UUID = UUID()
    
    var body: some View {
        ZStack {
            GameTheme.Colors.primaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Title
                Text("combo_notifications_preview".localized)
                    .font(GameTheme.Typography.fontLarge)
                    .foregroundColor(GameTheme.Colors.primaryText)
                    .padding(.top)
                
                // Combo notification display area
                ZStack {
                    if showCombo2 {
                        ComboNotificationView(comboCount: 2, bonusPoints: 50)
                            .id(comboKey2)
                    }
                    
                    if showCombo3 {
                        ComboNotificationView(comboCount: 3, bonusPoints: 100)
                            .id(comboKey3)
                    }
                    
                    if showCombo5 {
                        ComboNotificationView(comboCount: 5, bonusPoints: 200)
                            .id(comboKey5)
                    }
                }
                .frame(height: 150)
                
                Spacer()
                
                // Control buttons
                VStack(spacing: 15) {
                    Text("tap_to_trigger_combos".localized)
                        .font(GameTheme.Typography.fontSmall)
                        .foregroundColor(GameTheme.Colors.secondaryText)
                    
                    VStack(spacing: 12) {
                        Button("two_line_combo_button".localized) {
                            triggerCombo2()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .gameCardStyle()
                        
                        Button("three_line_combo_button".localized) {
                            triggerCombo3()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .gameCardStyle()
                        
                        Button("five_line_combo_button".localized) {
                            triggerCombo5()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .gameCardStyle()
                        
                        Button("show_all_combos".localized) {
                            triggerAllCombos()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .gameBadgeStyle(
                            backgroundColor: GameTheme.Colors.accent.opacity(0.3),
                            borderColor: GameTheme.Colors.accent
                        )
                    }
                    .foregroundColor(GameTheme.Colors.primaryText)
                }
                .padding(.bottom, 40)
            }
            .padding()
        }
    }
    
    private func triggerCombo2() {
        showCombo2 = false
        showCombo3 = false
        showCombo5 = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            comboKey2 = UUID()
            showCombo2 = true
        }
    }
    
    private func triggerCombo3() {
        showCombo2 = false
        showCombo3 = false
        showCombo5 = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            comboKey3 = UUID()
            showCombo3 = true
        }
    }
    
    private func triggerCombo5() {
        showCombo2 = false
        showCombo3 = false
        showCombo5 = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            comboKey5 = UUID()
            showCombo5 = true
        }
    }
    
    private func triggerAllCombos() {
        showCombo2 = false
        showCombo3 = false
        showCombo5 = false
        
        // Show them in sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            comboKey2 = UUID()
            showCombo2 = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            showCombo2 = false
            comboKey3 = UUID()
            showCombo3 = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            showCombo3 = false
            comboKey5 = UUID()
            showCombo5 = true
        }
    }
}