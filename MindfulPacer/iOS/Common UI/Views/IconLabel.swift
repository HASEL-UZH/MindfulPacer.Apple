//
//  IconLabel.swift
//  iOS
//
//  Created by Grigor Dochev on 15.08.2024.
//

import SwiftUI

// MARK: - IconLabel

/// The default `Label` does not set a fixed frame on the image, so images with different widths cause stacked labels to be misaligned
struct IconLabel: View {    
    var icon: String
    var title: String
    var textColor: Color? = nil
    var iconColor: Color? = nil
    var labelColor: Color? = nil
    var symbolVariant: SymbolVariants = .fill
    var symbolRenderingMode: SymbolRenderingMode = .monochrome
    var background: Bool = false
    var axis: Axis = .horizontal
    
    private var resolvedTextColor: Color {
        labelColor ?? textColor ?? .primary
    }
    
    private var resolvedIconColor: Color {
        labelColor ?? iconColor ?? .primary
    }
    
    var body: some View {
        switch axis {
        case .horizontal:
            Label {
                Text(title)
                    .foregroundStyle(resolvedTextColor)
                    .truncationMode(.middle)
            } icon: {
                Icon(
                    name: icon,
                    color: resolvedIconColor,
                    variant: symbolVariant,
                    renderingMode: symbolRenderingMode,
                    background: background
                )
            }
        case .vertical:
            VStack(alignment: .leading, spacing: 8) {
                Icon(
                    name: icon,
                    color: resolvedIconColor,
                    variant: symbolVariant,
                    renderingMode: symbolRenderingMode,
                    background: background
                )
                
                Text(title)
                    .foregroundStyle(resolvedTextColor)
                    .truncationMode(.middle)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        IconLabel(icon: "figure.walk", title: "Walking", textColor: .blue, iconColor: .pink, background: true)
        IconLabel(icon: "heart.fill", title: "Heart Rate", labelColor: .pink, background: false)
    }
}
