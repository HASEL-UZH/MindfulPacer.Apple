//
//  CroppedIPhoneImage.swift
//  iOS
//
//  Created by Grigor Dochev on 22.08.2025.
//

import SwiftUI

struct CroppedIPhoneImage: View {
    let image: Image
    let heightRatio: CGFloat
    let alignment: Alignment
    let fill: Bool
    
    init(
        _ image: Image,
        heightRatio: CGFloat = 0.6,
        alignment: Alignment = .top,
        fill: Bool = false
    ) {
        self.image = image
        self.heightRatio = heightRatio
        self.alignment = alignment
        self.fill = fill
    }
    
    var body: some View {
        Color.clear
            .aspectRatio(1.0 / heightRatio, contentMode: .fit)
            
            .overlay(
                GeometryReader { geo in
                    if fill {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height, alignment: alignment)
                            .clipped()
                    } else {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width, height: geo.size.height, alignment: alignment)
                            .clipped()
                    }
                }
            )
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Text("Content Above")
        
        CroppedIPhoneImage(Image(.appleWatchReturnToClock), heightRatio: 1.2, fill: true)
            .background(Color.green)
            .border(Color.red)

        Text("Content Below")
        Spacer()
    }
    .padding()
}
