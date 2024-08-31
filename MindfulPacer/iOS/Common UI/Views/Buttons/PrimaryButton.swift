//
//  PrimaryButton.swift
//  iOS
//
//  Created by Grigor Dochev on 14.08.2024.
//

import SwiftUI

struct PrimaryButton: View {
    @Environment(\.isEnabled) private var isEnabled: Bool
    
    var title: String
    var icon: String? = nil
    var color: Color = Color("BrandPrimary")
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            if let icon {
                IconLabel(
                    icon: icon,
                    title: title,
                    labelColor: isEnabled ? .white : Color(.systemGray2)
                )
                .frame(height: 40)
                .frame(maxWidth: .infinity)
                .fontWeight(.semibold)
            } else {
                Text(title)
                    .frame(height: 40)
                    .frame(maxWidth: .infinity)
                    .fontWeight(.semibold)
            }
        }
        .tint(color)
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: 16))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 32) {
        PrimaryButton(title: "Delete", icon: "trash", color: .red) {}
        
        PrimaryButton(title: "Done", icon: "checkmark") {}
        
        PrimaryButton(title: "Continue") {}
            .disabled(true)
    }
}
