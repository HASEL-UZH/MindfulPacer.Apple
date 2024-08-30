//
//  ReviewsListView.swift
//  iOS
//
//  Created by Grigor Dochev on 29.08.2024.
//

import SwiftUI

// MARK: - ReviewsListView

struct ReviewsListView: View {
    @Bindable var viewModel: HomeViewModel
    
    var body: some View {
        List {
            Section {
                ForEach(0..<3) { index in
                    Button {
                        // Handle button action
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .foregroundStyle(Color(.secondarySystemGroupedBackground))
                            
                            HStack {
                                Text("This is a long sentence to take up the screen.")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .frame(maxHeight: .infinity)
                                
                                Spacer()
                                
                                Icon(name: "chevron.right", color: Color(.systemGray2))
                            }
                            .padding()
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                // Handle swipe action
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                }
                .contentShape(Rectangle())
                .listRowInsets(.init())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            
            Section {
                Text("This is one element.")
                Text("This is another element")
            }
        }
        .buttonStyle(.plain)
        .listRowSpacing(16)
        .navigationTitle("Reviews")
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.homeViewModel()
    
    NavigationStack {
        ReviewsListView(viewModel: viewModel)
    }
}
