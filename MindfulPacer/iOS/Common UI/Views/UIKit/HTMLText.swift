//
//  HTMLText.swift
//  iOS
//
//  Created by Grigor Dochev on 01.02.2025.
//

import Foundation
import SwiftUI

struct HTMLText: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = html.toAttributedString()
        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {
        uiView.attributedText = html.toAttributedString()
    }
}

extension String {
    func toAttributedString() -> NSAttributedString {
        guard let data = self.data(using: .utf8) else { return NSAttributedString(string: self) }
        do {
            return try NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            )
        } catch {
            return NSAttributedString(string: self)
        }
    }
}
