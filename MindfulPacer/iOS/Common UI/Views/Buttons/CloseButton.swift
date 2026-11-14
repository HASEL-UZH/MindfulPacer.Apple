//
//  CloseButton.swift
//  iOS
//
//  Created by Grigor Dochev on 15.08.2024.
//

import SwiftUI

// MARK: - CloseButton

struct CloseButton: View {
    // MARK: Properties

    @Environment(\.dismiss) private var dismiss

    // MARK: Body

    var body: some View {
        Button {
            dismiss()
        } label: {
            Label("Close", systemImage: "xmark")
        }
    }
}

// MARK: - Preview

#Preview {
    CloseButton()
}
