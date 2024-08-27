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
    var iconColor: Color? = nil
    var labelColor: Color? = nil
    var symbolVariant: SymbolVariants = .fill
    var symbolRenderingMode: SymbolRenderingMode = .monochrome
    var background: Bool = false
    
    private var resolvedTextColor: Color {
        labelColor ?? textColor ?? .primary
    }
    
    private var resolvedIconColor: Color {
        labelColor ?? iconColor ?? .primary
    }
    
    var body: some View {
//        Label {
//            Text(title)
//                .foregroundStyle(resolvedTextColor)
//        } icon: {
//            SFSymbolIcon(
//                name: icon,
//                color: resolvedIconColor,
//                variant: symbolVariant,
//                renderingMode: symbolRenderingMode,
//                background: background
//            )
//        }
        HStack(spacing: 2) {
            SFSymbolIcon(
                name: icon,
                color: resolvedIconColor,
                variant: symbolVariant,
                renderingMode: symbolRenderingMode,
                background: background
            )
            Text(title)
                .foregroundStyle(resolvedTextColor)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        SFSymbolLabel(icon: "figure.walk", title: "Walking", textColor: .blue, iconColor: .pink, background: true)
        SFSymbolLabel(icon: "heart.fill", title: "Heart Rate", labelColor: .pink, background: false)
    }
}
