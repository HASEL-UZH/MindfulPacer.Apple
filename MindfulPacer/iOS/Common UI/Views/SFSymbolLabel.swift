//
//  SFSymbolLabel.swift
//  iOS
//
//  Created by Grigor Dochev on 15.08.2024.
//

import SwiftUI

/// The default `Label` does not set a fixed frame on the image, so images with different widths cause stacked labels to be misaligned
struct SFSymbolLabel: View {
    var icon: String
    var title: String
    var textColor: Color? = nil
    var symbolVariant: SymbolVariants = .fill
    var symbolRenderingMode: SymbolRenderingMode = .monochrome
    
    var body: some View {
        Label {
            if let textColor {
                Text(title)
                    .foregroundStyle(textColor)
            } else {
                Text(title)
            }
        } icon: {
            Image(systemName: icon)
                .frame(width: 24)
                .symbolVariant(symbolVariant)
                .symbolRenderingMode(symbolRenderingMode)
        }

    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        SFSymbolLabel(icon: "figure.walk", title: "Walking")
        SFSymbolLabel(icon: "heart.fill", title: "Heart Rate")
    }
}
