//
//  PrimaryButton.swift
//  iOS
//
//  Created by Grigor Dochev on 14.08.2024.
//

import SwiftUI

struct PrimaryButton: View {
    var title: String
    var icon: String? = nil
    var action: () -> Void
    
    var body: some View {
        Button {
            
        } label: {
            ZStack {
                if let icon {
                    Label(title, systemImage: icon)
                } else {
                    Text(title)
                }
            }
            .foregroundStyle(.white)
            .fontWeight(.semibold)
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .foregroundStyle(Color("PrimaryGreen"))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 32) {
        PrimaryButton(title: "Done", icon: "checkmark") {}
        
        PrimaryButton(title: "Continue") {}
    }
}
