//
//  SFSymbolIcon.swift
//  iOS
//
//  Created by Grigor Dochev on 26.08.2024.
//

import SwiftUI

// MARK: - SFSymbolIcon

struct SFSymbolIcon: View {
    var name: String
    var color: Color = .primary
    var variant: SymbolVariants = .fill
    var renderingMode: SymbolRenderingMode = .monochrome
    var background: Bool = false
    
    var body: some View {
        Image(systemName: name)
            .frame(width: 24, height: 24)
            .symbolVariant(variant)
            .symbolRenderingMode(renderingMode)
            .foregroundStyle(color)
            .padding(background ? 4 : 0)
            .background {
                if background {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .foregroundStyle(color.opacity(0.1))
                        
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(color, lineWidth: 1.5)
                    }
                }
            }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        SFSymbolIcon(name: "heart")
        SFSymbolIcon(name: "bell.badge", color: .green, variant: .fill, renderingMode: .hierarchical, background: true)
    }
}
