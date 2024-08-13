//
//  ReviewCategoryView.swift
//  iOS
//
//  Created by Grigor Dochev on 12.08.2024.
//

import SwiftUI
//import SwiftData
//
//struct ReviewCategoryView: View {
//    @Binding var selectedCategory: Category?
//    
//    let categories: [Category]
//    let columns: [GridItem] = [GridItem(spacing: 16), GridItem(spacing: 16)]
//    var onSelectCategory: ((Category) -> Void)?
//    
//    var body: some View {
//        ScrollView {
//            LazyVGrid(columns: columns, spacing: 16) {
//                ForEach(categories) { category in
//                    Button {
//                        onSelectCategory(category)
//                    } label: {
//                        VStack(spacing: 16) {
//                            Image(systemName: category.icon)
//                                .resizable()
//                                .scaledToFit()
//                                .symbolVariant(.fill)
//                                .frame(width: 64, height: 64)
//                            Text(category.name)
//                                .fontWeight(.semibold)
//                        }
//                        .padding()
//                        .frame(maxWidth: .infinity)
//                        .background {
//                            RoundedRectangle(cornerRadius: 16)
//                                .foregroundStyle(selectedCategory == category ? Color("PrimaryGreen").opacity(0.1) : Color(.secondarySystemGroupedBackground))
//                        }
//                        .overlay {
//                            if selectedCategory == category {
//                                RoundedRectangle(cornerRadius: 16)
//                                    .stroke(Color("PrimaryGreen"), lineWidth: 2)
//                            }
//                        }
//                    }
//                    .foregroundStyle(selectedCategory == category ? Color("PrimaryGreen") : Color.primary)
//                }
//            }
//            .padding(.horizontal)
//        }
//        .navigationTitle("Category")
//        .background(
//            Color(.systemGroupedBackground)
//                .ignoresSafeArea()
//        )
//    }
//}
//
//// MARK: - Preview
//
//#Preview(traits: .sampleData) {
//    @Previewable @Query var categories: [Category]
//    @Previewable @State var selectedCategory: Category? = nil
//    
//    NavigationStack {
//        ReviewCategoryView(selectedCategory: $selectedCategory, categories: categories, onSelectCategory: { category in
//            
//        })
//        .tint(Color.primaryGreen)
//        .navigationTitle("Category")
//    }
//}
//
