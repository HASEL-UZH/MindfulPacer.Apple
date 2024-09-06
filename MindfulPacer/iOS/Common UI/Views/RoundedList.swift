//
//  RoundedList.swift
//  iOS
//
//  Created by Grigor Dochev on 06.09.2024.
//

import SwiftUI

// MARK: - RoundedList

struct RoundedList<Content: View>: View {
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                content()
            }
            .padding(.horizontal)
        }
        .background {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
        }
    }
}

// MARK: - RoundedSection

struct RoundedSection<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        Extract(content) { views in
            VStack(spacing: 0) {
                ForEach(Array(views.enumerated()), id: \.offset) { index, view in
                    ZStack {
                        let corners = getCorners(for: index, totalCount: views.count)
                        
                        // Apply the background based on position (first, middle, last)
                        UnevenRoundedRectangle(cornerRadii: corners)
                            .foregroundStyle(Color(.secondarySystemGroupedBackground))
                        
                        // Ensure full row is tappable with background highlighting
                        view
                            .padding()
                            .background(Color.clear)
                            .contentShape(Rectangle())  // Make the entire area tappable
                            .modifier(CellHighlightModifier(cornerRadii: corners)) // Apply full-cell highlight behavior with dynamic corner rounding
                    }
                    .padding(.bottom, index != views.count - 1 ? 1 : 0)  // Add spacing between rows except last one
                }
            }
        }
    }
    
    // Helper function to determine which corners to round based on the row's position
    private func getCorners(for index: Int, totalCount: Int) -> RectangleCornerRadii {
        if totalCount == 1 {
            RectangleCornerRadii(topLeading: 16, bottomLeading: 16, bottomTrailing: 16, topTrailing: 16)
        } else if index == 0 {
            // First row - round top corners
            RectangleCornerRadii(topLeading: 16, topTrailing: 16)
        } else if index == totalCount - 1 {
            // Last row - round bottom corners
            RectangleCornerRadii(bottomLeading: 16, bottomTrailing: 16)
        } else {
            // Middle row - no rounding
            RectangleCornerRadii()
        }
    }
}

// MARK: - Custom Modifier for Cell Highlighting

/// Custom modifier to apply background highlighting to the entire cell, including rounded corners
struct CellHighlightModifier: ViewModifier {
    let cornerRadii: RectangleCornerRadii
    
    func body(content: Content) -> some View {
        Button(action: {}) {
            content
                .background(Color.clear)
                .contentShape(Rectangle())
        }
        .buttonStyle(CellHighlightStyle(cornerRadii: cornerRadii)) // Apply custom highlight style with rounded corners
    }
}

// MARK: - CellHighlightStyle

/// Custom button style for highlighting the full background on tap with dynamic rounded corners
struct CellHighlightStyle: ButtonStyle {
    let cornerRadii: RectangleCornerRadii
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                configuration.isPressed
                ? UnevenRoundedRectangle(cornerRadii: cornerRadii)
                    .foregroundStyle(Color(.systemGray5))  // Highlight with rounded corners based on row position
                : UnevenRoundedRectangle(cornerRadii: cornerRadii)
                    .foregroundStyle(.clear)
            }
            .contentShape(Rectangle())  // Ensure the entire row is tappable
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var navigationPath: [Int] = []
    
    NavigationStack(path: $navigationPath) {
        RoundedList {
            RoundedSection {
                // FIXME: this shouldn't be highlighted on cell tap
                DatePicker(selection: .constant(.now)) {
                    IconLabel(icon: "calendar", title: "Date", labelColor: Color("BrandPrimary"), background: true)
                        .font(.subheadline.weight(.semibold))
                }
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        IconLabel(icon: "figure.run", title: "Movement")
                            .font(.subheadline.weight(.semibold))
                        
                        Text(Date.now.formatted(.dateTime.day().month().hour().month()))
                            .font(.footnote)
                            .foregroundStyle(Color.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color(.systemGray2))
                }
                .contentShape(Rectangle())  // Make the entire row tappable
                .onTapGesture {
                    navigationPath.append(1)
                }
                
            }
            
            RoundedSection {
                Text("Heyo")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .navigationTitle("Rounded List")
        .navigationDestination(for: Int.self) { value in
            switch value {
            case 1: Text("One")
            default: EmptyView()
            }
        }
    }
}
