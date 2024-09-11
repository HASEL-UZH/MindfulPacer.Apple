//
//  InfoBox.swift
//  iOS
//
//  Created by Grigor Dochev on 15.08.2024.
//

import SwiftUI

// MARK: - InfoBox

struct InfoBox: View {
    // MARK: Properties
    
    var text: String
    
    // MARK: Body
    
    var body: some View {
        Card(backgroundColor: Color(.tertiarySystemFill)) {
            ZStack {
                Label {
                    Text(text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } icon: {
                    Icon(name: "info.circle", color: .secondary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    InfoBox(text: "This is some information.")
}
