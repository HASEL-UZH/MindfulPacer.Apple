//
//  InfoBox.swift
//  iOS
//
//  Created by Grigor Dochev on 15.08.2024.
//

import SwiftUI

struct InfoBox: View {
    var text: String
    
    var body: some View {
        ZStack {
            Label {
                Text(text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.subheadline)
            } icon: {
                Image(systemName: "info.circle.fill")
                    .frame(width: 24)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 8)
                .foregroundStyle(Color(.tertiarySystemFill))
        }
    }
}

// MARK: - Preview

#Preview {
    InfoBox(text: "This is some information.")
}
