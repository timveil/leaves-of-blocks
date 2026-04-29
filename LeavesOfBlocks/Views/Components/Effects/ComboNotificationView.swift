import SwiftUI

// MARK: - Combo Notification Component

struct ComboNotificationView: View {
    let comboCount: Int
    let bonusPoints: Int
    @State private var scale: CGFloat = 0.9
    @State private var opacity: Double = 0.0
    @State private var yOffset: CGFloat = 0
    @State private var dismissTask: Task<Void, Never>?

    private var comboText: String {
        if comboCount >= 5 {
            return "mega_combo".localized
        } else if comboCount >= 3 {
            return "combo_excited".localized
        } else {
            return "combo".localized
        }
    }

    var body: some View {
        GoldHeaderCard(title: comboText) {
            VStack(spacing: GameTheme.Layout.smallSpacing) {
                Text("lines_cleared_format".localized(with: comboCount))
                    .font(GameTheme.Typography.body)
                    .foregroundColor(GameTheme.Colors.secondaryText)

                Text("+\(bonusPoints)")
                    .font(GameTheme.Typography.display)
                    .foregroundColor(GameTheme.Colors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: 280)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ax_combo_format".localized(with: comboText, comboCount, bonusPoints))
        .scaleEffect(scale)
        .opacity(opacity)
        .offset(y: yOffset)
        .onAppear {
            AccessibilityNotification.Announcement("ax_combo_format".localized(with: comboText, comboCount, bonusPoints)).post()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }

            dismissTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.5))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.25)) {
                    opacity = 0.0
                    yOffset = -15
                    scale = 0.9
                }
            }
        }
        .onDisappear {
            dismissTask?.cancel()
        }
    }
}

// MARK: - Combo Notification Manager

struct ComboNotificationOverlay: View {
    var gameState: GameState
    @State private var activeCombo: (count: Int, bonus: Int)?
    @State private var notificationId: UUID = UUID()
    
    var body: some View {
        ZStack {
            if let combo = activeCombo {
                // Match the dim used by GameOver / SaveGame overlays so the
                // combo popup reads with the same visual weight as those modals.
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .transition(.opacity)

                // Position combo notification higher on screen
                VStack {
                    ComboNotificationView(
                        comboCount: combo.count,
                        bonusPoints: combo.bonus
                    )
                    .padding(.top, 80) // Position higher than center

                    Spacer()
                }
                .id(notificationId) // Force recreation for each new combo
                .task {
                    // Clear the combo after animation completes - faster dismissal
                    try? await Task.sleep(for: .seconds(1.0))
                    withAnimation(.easeInOut(duration: 0.25)) {
                        activeCombo = nil
                    }
                }
            }
        }
        .onChange(of: gameState.currentCombo) { _, newCombo in
            // Only show notification for combos of 2+ lines
            if newCombo >= 2 {
                let bonusPoints = (newCombo - 1) * GameTheme.GameConfig.comboBonus
                withAnimation(.easeInOut(duration: 0.2)) {
                    activeCombo = (count: newCombo, bonus: bonusPoints)
                }
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
                    .font(GameTheme.Typography.title)
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
                        .font(GameTheme.Typography.body)
                        .foregroundColor(GameTheme.Colors.secondaryText)
                    
                    VStack(spacing: 12) {
                        Button("two_line_combo_button".localized) {
                            triggerCombo2()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(GameTheme.Colors.cardBackground)
                        .folkArtCard()
                        
                        Button("three_line_combo_button".localized) {
                            triggerCombo3()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(GameTheme.Colors.cardBackground)
                        .folkArtCard()
                        
                        Button("five_line_combo_button".localized) {
                            triggerCombo5()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(GameTheme.Colors.cardBackground)
                        .folkArtCard()
                        
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

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.1))
            comboKey2 = UUID()
            showCombo2 = true
        }
    }

    private func triggerCombo3() {
        showCombo2 = false
        showCombo3 = false
        showCombo5 = false

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.1))
            comboKey3 = UUID()
            showCombo3 = true
        }
    }

    private func triggerCombo5() {
        showCombo2 = false
        showCombo3 = false
        showCombo5 = false

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.1))
            comboKey5 = UUID()
            showCombo5 = true
        }
    }

    private func triggerAllCombos() {
        showCombo2 = false
        showCombo3 = false
        showCombo5 = false

        // Show them in sequence
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.1))
            comboKey2 = UUID()
            showCombo2 = true

            try? await Task.sleep(for: .seconds(2.9))
            showCombo2 = false
            comboKey3 = UUID()
            showCombo3 = true

            try? await Task.sleep(for: .seconds(3.0))
            showCombo3 = false
            comboKey5 = UUID()
            showCombo5 = true
        }
    }
}
