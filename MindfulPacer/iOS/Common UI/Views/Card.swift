//
//  Card.swift
//  iOS
//
//  Created by Grigor Dochev on 05.09.2024.
//

import SwiftUI

// MARK: - Card

struct Card<Content: View>: View {
    // MARK: Properties
    
    var cornerRadius: CGFloat = 16.0
    var backgroundColor: Color = Color(.secondarySystemGroupedBackground)
    var content: () -> Content

    // MARK: Body
    
    var body: some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .foregroundStyle(backgroundColor)
            }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
        
        VStack(spacing: 32) {
            Card {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Card 1")
                        .font(.title.bold())
                    
                    Divider()
                    
                    Text("This is my card content.")
                }
            }
            
            Card(backgroundColor: .blue) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Card 2")
                        .font(.title.bold())
                    
                    Divider()
                    
                    Text("This is my card, but it's blue.")
                }
            }
        }
        .padding()
    }
}
