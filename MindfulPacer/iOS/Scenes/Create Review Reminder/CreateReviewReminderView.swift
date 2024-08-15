//
//  CreateReviewReminderView.swift
//  iOS
//
//  Created by Grigor Dochev on 15.08.2024.
//

import SwiftUI

// MARK: - Create Review Reminder

struct CreateReviewReminderView: View {
    @Environment(\.keyboardShowing) private var keyboardShowing
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Image(systemName: "applewatch.radiowaves.left.and.right")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 128)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.accentColor)
                    Text("This allows you to add a new alarm which can be triggered on your Apple Watch or iPhone.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Create Reminder")
            .safeAreaInset(edge: .bottom) {
                continueButton
            }
        }
    }
    
    private var continueButton: some View {
        PrimaryButton(title: "Continue") {

        }
        .padding(keyboardShowing ? [.all] : [.horizontal, .top])
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}

// MARK: - Preview

#Preview {
    CreateReviewReminderView()
        .tint(Color("PrimaryGreen"))
}
