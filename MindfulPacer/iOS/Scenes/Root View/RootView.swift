//
//  RootView.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 30.06.2024.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @State var viewModel: RootViewModel = ScenesContainer.shared.rootViewModel()
    // Temporary
    @State private var showCreateReviewView = false
    @Query private var reviews: [Review]
    
    var body: some View {
        TabView {
            List {
                if reviews.isEmpty {
                    Text("No Reviews")
                } else {
                    ForEach(reviews) { review in
                        VStack(alignment: .leading, spacing: 16) {
                            Text(review.category?.name ?? "No category selected")
                            Text(review.subcategory?.name ?? "No subcategory selected")
                            Text(review.mood ?? "No mood selected")
                            Text("Crash triggered? \(review.didTriggerCrash ?? false))")
                            Text("Headaches rating: \(review.headachesRating ?? 0)")
                        }
                    }
                }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .onAppear {
                showCreateReviewView.toggle()
            }
        }
        .onViewFirstAppear {
            viewModel.onViewFirstAppear()
        }
        .sheet(isPresented: $showCreateReviewView) {
            CreateReviewView()
                .interactiveDismissDisabled()
        }
    }
}

#Preview {
    RootView()
}
