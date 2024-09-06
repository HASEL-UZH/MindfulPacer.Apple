//
//  Extractable.swift
//  iOS
//
//  Created by Grigor Dochev on 06.09.2024.
//

import SwiftUI

@MainActor
protocol Extractable: View {
    associatedtype Content: View
    associatedtype ViewsContent: View

    var content: () -> Content { get }
    var views: (Views) -> ViewsContent { get }

    init(_ content: Content, @ViewBuilder views: @escaping (Views) -> ViewsContent)
    init(@ViewBuilder _ content: @escaping () -> Content, @ViewBuilder views: @escaping (Views) -> ViewsContent)
}

public typealias Views = _VariadicView.Children
