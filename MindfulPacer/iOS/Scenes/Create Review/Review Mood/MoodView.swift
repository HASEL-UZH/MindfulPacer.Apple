//
//  MoodView.swift
//  iOS
//
//  Created by Grigor Dochev on 12.08.2024.
//

import SwiftUI

private struct MoodView: View {
    @State private var selectedEmoji: String? = nil
    let emojis = ["🥲", "😀", "😡", "🙃", "🙁", "😫", "🤭"]
    
    var body: some View {
        NavigationStack {
            VStack {
                LazyVGrid(columns: Array(repeating: GridItem(spacing: 16), count: 5), spacing: 16) {
                    ForEach(emojis, id: \.self) { emoji in
                        emojiIconButton(for: emoji)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .navigationTitle("Mood")
        }
    }
    
    @ViewBuilder private func emojiIconButton(for emoji: String) -> some View {
        Button {
            selectEmoji(emoji)
        } label: {
            Text(emoji)
                .font(.title)
                .padding(8)
                .background {
                    Circle()
                        .foregroundStyle(Color("PrimaryGreen").opacity(0.1))
                }
                .padding(6)
                .overlay {
                    if selectedEmoji == emoji {
                        Circle()
                            .stroke(Color("PrimaryGreen"), lineWidth: 3)
                    }
                }
        }
    }
    
    func selectEmoji(_ emoji: String) {
        if selectedEmoji == emoji {
            selectedEmoji = nil
        } else {
            selectedEmoji = emoji
        }
    }
}

// MARK: - Preview

#Preview {
    MoodView()
}
