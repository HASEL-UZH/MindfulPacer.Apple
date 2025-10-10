//
//  PrimaryButton.swift
//  iOS
//
//  Created by Grigor Dochev on 14.08.2024.
//

import SwiftUI

// MARK: - PrimaryButton

struct PrimaryButton: View {
    // MARK: Properties

    @Environment(\.isEnabled) private var isEnabled: Bool

    var title: String
    var icon: String?
    var color: Color = Color("BrandPrimary")
    var action: () -> Void

    // MARK: Body

    var body: some View {
        if #available(iOS 26.0, *) {
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
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.roundedRectangle(radius: 16))
        } else {
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
