//
//  ReviewSubcategoryView.swift
//  iOS
//
//  Created by Grigor Dochev on 20.08.2024.
//

import SwiftUI
import SwiftData

// MARK: - ReviewSubcategoryView

extension CreateReviewView {
    struct ReviewSubcategoryView: View {
        @Bindable var viewModel: CreateReviewViewModel
        var category: Category
        
        var body: some View {
            ScrollView {
                
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let container = ModelContainer.preview
    let viewModel = ScenesContainer.shared.createReviewViewModel()
    
    CreateReviewView.ReviewSubcategoryView(viewModel: viewModel, category: Category())
        .modelContainer(container)
        .tint(Color("BrandPrimary"))
}
