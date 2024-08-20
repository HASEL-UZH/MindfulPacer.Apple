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
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            if let icon {
                Label(title, systemImage: icon)
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
        .tint(Color("BrandPrimary"))
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: 16))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 32) {
        PrimaryButton(title: "Done", icon: "checkmark") {}
        
        PrimaryButton(title: "Continue") {}
            .disabled(true)
    }
}
