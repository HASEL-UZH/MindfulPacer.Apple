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

    var name: String?
    var image: String?
    var color: Color = Color("BrandPrimary")
    var variant: SymbolVariants = .fill
    var renderingMode: SymbolRenderingMode = .monochrome
    var background: Bool = false

    // MARK: Body

    var body: some View {
        Group {
            if let image = image {
                Image(image)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .padding(2)
            } else if let name = name {
                Image(systemName: name)
                    .symbolVariant(variant)
                    .symbolRenderingMode(renderingMode)
                    .frame(width: 24, height: 24)
            }
        }
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
        
        Icon(
            name: "apple.logo",
            color: .gray, variant: .fill,
            renderingMode: .hierarchical,
            background: true
        )
        
        Icon(
            image: "android-logo",
            color: Color(.androidGreen),
            background: true
        )
    }
}
