//
//  SFSymbolGroupBox.swift
//  iOS
//
//  Created by Grigor Dochev on 22.08.2024.
//

import SwiftUI

struct SFSymbolGroupBox<Content: View, Button: View>: View {
    let label: SFSymbolLabel
    let content: Content
    let button: Button?
    
    init(
        label: SFSymbolLabel,
        @ViewBuilder content: () -> Content,
        @ViewBuilder button: () -> Button? = { nil }
    ) {
        self.label = label
        self.content = content()
        self.button = button()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                label
                    .font(.subheadline.weight(.semibold))
                
                Spacer()
                
                if let button = button {
                    button
                }
            }
            
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 8)
                .foregroundStyle(Color(.secondarySystemGroupedBackground))
        }
    }
}

extension SFSymbolGroupBox where Button == EmptyView {
    init(label: SFSymbolLabel, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
        self.button = EmptyView()
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var isExpanded = false
    @Previewable @Namespace var namespace
    
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
        
        SFSymbolGroupBox(
            label: SFSymbolLabel(
                icon: "info.circle.fill",
                title: "Expandable Box",
                labelColor: .secondary
            )
        ) {
            Group {
                if isExpanded {
                    Text("This is even more information that you can only see when you tap the button to expand the info box.")
                        .font(.subheadline)
                        .matchedGeometryEffect(id: "text", in: namespace)
                        .transition(.opacity.combined(with: .slide))
                } else {
                    Text("This is some information.")
                        .font(.subheadline)
                        .matchedGeometryEffect(id: "text", in: namespace)
                        .transition(.opacity.combined(with: .slide))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isExpanded)
            .fixedSize(horizontal: false, vertical: true)
        } button: {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                    .font(.title2)
            }
            .labelStyle(.iconOnly)
        }
    }
}
