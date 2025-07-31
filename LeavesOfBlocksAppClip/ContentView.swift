//
//  ContentView.swift
//  LeavesOfBlocksAppClip
//
//  Created by Tim Veil on 7/27/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showGetAppPrompt = false
    
    // Helper function for localization (since App Clip doesn't have String+Extensions)
    private func localized(_ key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
    
    // Helper function to get block colors similar to the main game
    private func getBlockColor(row: Int, col: Int) -> Color {
        let colors = [
            Color(red: 0.9, green: 0.7, blue: 0.1),    // Golden amber
            Color(red: 0.9, green: 0.5, blue: 0.1),    // Burnt orange
            Color(red: 0.8, green: 0.4, blue: 0.1),    // Deep orange
            Color(red: 0.3, green: 0.6, blue: 0.2),    // Forest green
            Color(red: 0.8, green: 0.2, blue: 0.1),    // Deep crimson
            Color(red: 0.5, green: 0.3, blue: 0.4),    // Purple
        ]
        return colors[(row + col) % colors.count]
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.05, blue: 0.02),
                    Color(red: 0.2, green: 0.15, blue: 0.1),
                    Color(red: 0.15, green: 0.1, blue: 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Title
                VStack(spacing: 8) {
                    Text(localized("app_title"))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color(red: 0.9, green: 0.7, blue: 0.1))
                    
                    Text(localized("app_tagline"))
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(red: 0.9, green: 0.8, blue: 0.7).opacity(0.7))
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Game Preview
                VStack(spacing: 20) {
                    // Grid preview - mimicking actual game grid appearance
                    ZStack {
                        // Grid background
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 0.15, green: 0.1, blue: 0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(red: 0.4, green: 0.25, blue: 0.1), lineWidth: 2)
                            )
                        
                        // Grid cells
                        VStack(spacing: 1) {
                            ForEach(0..<8) { row in
                                HStack(spacing: 1) {
                                    ForEach(0..<8) { col in
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(
                                                // Create a sample pattern with some "filled" cells
                                                (row == 7 && col < 6) || 
                                                (row == 6 && col > 1 && col < 5) ||
                                                (row == 5 && col == 3) ||
                                                (row < 3 && col == 0) ||
                                                (row < 2 && col == 1) ?
                                                getBlockColor(row: row, col: col) :
                                                Color(red: 0.2, green: 0.15, blue: 0.1)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color(red: 0.3, green: 0.2, blue: 0.1).opacity(0.3), lineWidth: 0.5)
                                            )
                                            .frame(width: 28, height: 28)
                                    }
                                }
                            }
                        }
                        .padding(12)
                    }
                    .frame(width: 280, height: 280)
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Text(localized("app_description"))
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.95, green: 0.9, blue: 0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                // Features list
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "square.grid.3x3.fill", text: localized("feature_8x8_grid"))
                    FeatureRow(icon: "cube.fill", text: localized("feature_21_shapes"))
                    FeatureRow(icon: "gauge.with.dots.needle.33percent", text: localized("feature_3_difficulties"))
                    FeatureRow(icon: "trophy.fill", text: localized("feature_high_scores"))
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Action Button
                Button(action: {
                    showGetAppPrompt = true
                }) {
                    HStack {
                        Image(systemName: "arrow.down.app.fill")
                        Text(localized("get_full_game"))
                    }
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(red: 0.1, green: 0.05, blue: 0.02))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.9, green: 0.7, blue: 0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 30)
                
                Text(localized("free_to_play"))
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.9, green: 0.8, blue: 0.7).opacity(0.5))
                    .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showGetAppPrompt) {
            GetFullAppView()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color(red: 0.9, green: 0.7, blue: 0.1))
                .frame(width: 25)
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.95, green: 0.9, blue: 0.8))
            
            Spacer()
        }
    }
}

struct GetFullAppView: View {
    @Environment(\.dismiss) var dismiss
    
    // Helper function for localization (since App Clip doesn't have String+Extensions)
    private func localized(_ key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.05, blue: 0.02),
                    Color(red: 0.15, green: 0.1, blue: 0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color(red: 0.9, green: 0.8, blue: 0.7).opacity(0.5))
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Content
                VStack(spacing: 20) {
                    Text(localized("get_full_experience"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(red: 0.9, green: 0.7, blue: 0.1))
                        .multilineTextAlignment(.center)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        FullFeatureRow(icon: "gamecontroller.fill", text: localized("feature_complete_gameplay"))
                        FullFeatureRow(icon: "chart.line.uptrend.xyaxis", text: localized("feature_track_progress"))
                        FullFeatureRow(icon: "clock.arrow.circlepath", text: localized("feature_game_history"))
                        FullFeatureRow(icon: "trophy.fill", text: localized("feature_persistent_scores"))
                        FullFeatureRow(icon: "square.stack.3d.up.fill", text: localized("feature_all_shapes"))
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 10)
                    
                    Spacer()
                    
                    // App Store button
                    Link(destination: URL(string: "https://apps.apple.com/app/leaves-of-blocks/idYOUR_APP_ID")!) {
                        HStack {
                            Image(systemName: "arrow.down.app.fill")
                            Text(localized("download_from_app_store"))
                        }
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 30)
                    
                    Text(localized("free_no_purchases"))
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.9, green: 0.8, blue: 0.7).opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 30)
            }
        }
    }
}

struct FullFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(Color(red: 0.9, green: 0.7, blue: 0.1))
                .frame(width: 30)
            
            Text(text)
                .font(.system(size: 18))
                .foregroundColor(Color(red: 0.95, green: 0.9, blue: 0.8))
            
            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
