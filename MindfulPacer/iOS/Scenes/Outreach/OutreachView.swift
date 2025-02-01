//
//  OutreachView.swift
//  iOS
//
//  Created by Grigor Dochev on 01.02.2025.
//

import SwiftUI

// MARK: - OutreachView

struct OutreachView: View {
    
    // MARK: Properties
    
    @State private var viewModel: OutreachViewModel = ScenesContainer.shared.outreachViewModel()
    
    // MARK: Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(viewModel.blogArticles) { article in
                        BlogArticleCell(article: article)
                    }
                }
                .padding([.horizontal, .bottom])
            }
            .navigationTitle("Outreach")
            .background {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
            }
            //            .navigationDestination(for: HomeViewNavigationDestination.self, destination: navigationDestination)
            //            .sheet(item: $viewModel.activeSheet, onDismiss: {
            //                withAnimation {
            //                    viewModel.onSheetDismissed()
            //                }
            //            }, content: { sheet in
            //                sheetContent(for: sheet)
            //            })
            //            .toast(item: $viewModel.activeToast) { toast in
            //                toastContent(for: toast)
            //            }
            .onViewFirstAppear {
                viewModel.onViewFirstAppear()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OutreachView()
}
