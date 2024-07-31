//
//  DragAndDropTest.swift
//  iOS
//
//  Created by Grigor Dochev on 30.07.2024.
//

import SwiftUI

struct ColorItemView: View {
    let backgroundColor: Color
    
    var body: some View {
        HStack {
            Spacer()
            Text(backgroundColor.description.capitalized)
            Spacer()
        }
        .padding(.vertical, 40)
        .background(backgroundColor)
        .cornerRadius(20)
    }
}

struct DropViewDelegate: DropDelegate {
    let destinationItem: Color
    @Binding var colors: [Color]
    @Binding var draggedItem: Color?
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        // Swap Items
        if let draggedItem {
            let fromIndex = colors.firstIndex(of: draggedItem)
            if let fromIndex {
                let toIndex = colors.firstIndex(of: destinationItem)
                if let toIndex, fromIndex != toIndex {
                    withAnimation {
                        self.colors.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: (toIndex > fromIndex ? (toIndex + 1) : toIndex))
                    }
                }
            }
        }
    }
}

struct DragAndDropTest: View {
    @State private var draggedColor: Color?
    @State private var colors: [Color] = [.purple, .blue, .cyan, .yellow, .red]
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    LazyVGrid(columns: [GridItem(spacing: 16), GridItem(spacing: 16)]) {
                        ForEach(colors.prefix(4), id: \.self) { color in
                            ColorItemView(backgroundColor: color)
                                .onDrag {
                                    self.draggedColor = color
                                    return NSItemProvider()
                                }
                                .onDrop(of: [.text],
                                        delegate: DropViewDelegate(destinationItem: color, colors: $colors, draggedItem: $draggedColor)
                                )
                        }
                    }
                    
                    ForEach(colors.suffix(1), id: \.self) { color in
                        ColorItemView(backgroundColor: color)
                            .onDrag {
                                self.draggedColor = color
                                return NSItemProvider()
                            }
                            .onDrop(of: [.text],
                                    delegate: DropViewDelegate(destinationItem: color, colors: $colors, draggedItem: $draggedColor)
                            )
                    }
                }
            }
        }
    }
}

#Preview {
    DragAndDropTest()
}
