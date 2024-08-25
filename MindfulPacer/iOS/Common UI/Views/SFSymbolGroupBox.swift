//
//  SFSymbolGroupBox.swift
//  iOS
//
//  Created by Grigor Dochev on 22.08.2024.
//

import SwiftUI

struct SFSymbolGroupBox<Content: View>: View {
    var icon: String
    var title: String
    var labelColor: Color = .secondary
    var content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SFSymbolLabel(icon: icon, title: title)
                    .foregroundStyle(labelColor)
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }
            
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .foregroundStyle(Color(.secondarySystemGroupedBackground))
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
        
        SFSymbolGroupBox(icon: "info.circle.fill", title: "Info Box") {
            Text("This is some information.")
        }
    }
}
