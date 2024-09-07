//
//  Icon.swift
//  iOS
//
//  Created by Grigor Dochev on 26.08.2024.
//

import SwiftUI

// MARK: - Icon

struct Icon: View {
    // MARK: Properties
    
    var name: String
    var color: Color = Color("BrandPrimary")
    var variant: SymbolVariants = .fill
    var renderingMode: SymbolRenderingMode = .monochrome
    var background: Bool = false
    
    // MARK: Body
    
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
                            .stroke(color.opacity(0.1), lineWidth: 1.5)
                    }
                }
            }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        Icon(name: "heart")
        Icon(name: "bell.badge", color: .green, variant: .fill, renderingMode: .hierarchical, background: true)
    }
}
