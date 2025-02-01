//
//  EmptyView.swift
//  iOS
//
//  Created by Grigor Dochev on 19.09.2024.
//

import SwiftUI

// MARK: - EmptyStateView

struct EmptyStateView: View {
    var image: String
    var title: String
    var description: String
    var buttonTitle: String?
    var buttonAction: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Image(systemName: image)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .symbolVariant(.fill)
                .padding(.bottom, 8)

            Text(title)
                .font(.callout.bold())

            Text(description)
                .font(.footnote)
            
            if let buttonTitle,
               let buttonAction {
                Button {
                    buttonAction()
                } label: {
                    Text(buttonTitle)
                        .foregroundStyle(.white)
                        .font(.footnote.weight(.semibold))
                }
                .tint(Color("BrandPrimary"))
                .buttonBorderShape(.capsule)
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
        }
        .foregroundStyle(.secondary)
    }
}

// MARK: - Preview

#Preview {
    EmptyStateView(
        image: "book.pages",
        title: "No Reflections",
        description: "Tap the + button to create a reflection.",
        buttonTitle: "Create Reflection"
    ) {
        
    }
}
