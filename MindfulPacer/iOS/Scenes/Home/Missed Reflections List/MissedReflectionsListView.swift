//
//  MissedReflectionsListView.swift
//  iOS
//
//  Created by Grigor Dochev on 22.08.2025.
//

import SwiftUI

// MARK: - MissedReflectionsListView

extension HomeView {
    struct MissedReflectionsListView: View {
        
        // MARK: Properties
        
        @Bindable var viewModel: HomeViewModel
        
        // MARK: Body
        
        var body: some View {
            if viewModel.missedReflections.isEmpty {
                emptyState
            } else {
                missedReflectionsList
            }
        }
        
        // MARK: Action Buttons
        @ViewBuilder
        private func actionButtons(for reflection: Reflection) -> some View {
            HStack(spacing: 16) {
                Spacer()
                
                Button {
                    withAnimation {
                        viewModel.rejectMissedReflection(reflection: reflection)
                    }
                } label: {
                    Label("Reject", systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Button {
                    withAnimation {
                        viewModel.acceptMissedReflection(reflection: reflection)
                    }
                } label: {
                    Label("Accept", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
            .buttonStyle(.borderless)
            .buttonBorderShape(.capsule)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        
        // MARK: Missed Reflections List
        
        private var missedReflectionsList: some View {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.displayedMissedReflections) { reflection in
                        IconLabelGroupBox(
                            label: IconLabel(
                                icon: reflection.measurementType!.icon,
                                title: reflection.measurementType!.localized,
                                description: reflection.reminderTriggerSummary,
                                labelColor: reflection.measurementType!.color
                            )
                        ) {
                            VStack(alignment: .leading, spacing: 16) {
                                TriggerDataChartView(reflection: reflection)
                                    .frame(height: 150)
                                Text(String(localized: "Triggered on \(reflection.date.formatted(.dateTime.month().day().hour().minute()))"))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        } accessoryIndicator: {
                            Icon(
                                name: "alarm",
                                color: reflection.reminderType!.color,
                                background: true
                            )
                        } footer: {
                            actionButtons(for: reflection)
                        }
                        .iconLabelGroupBoxStyle(.divider)
                        .padding(.horizontal)
                    }

                    if viewModel.isFetchingMissedReflections {
                        ProgressView()
                            .padding(.vertical, 12)
                    }

                    if !viewModel.displayedMissedReflections.isEmpty {
                        Text("\(viewModel.displayedMissedReflections.count) of \(viewModel.missedReflections.count)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 8)
                    }
                }
                
                if viewModel.canLoadMoreMissed && !viewModel.isFetchingMissedReflections {
                    HStack {
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                viewModel.loadMoreMissed()
                            }
                        } label: {
                            IconLabel(
                                icon: "arrow.down.circle.fill",
                                title: "Load More",
                                labelColor: .brandPrimary
                            )
                            .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Missed Reflections")
        }
        
        // MARK: Empty State
        
        private var emptyState: some View {
            ContentUnavailableView {
                Label("No Missed Reflections", systemImage: "square.stack.fill")
            } description: {
                Text("You do not have any missed reflections.")
            }
            .navigationTitle("Missed Reflections")
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: HomeViewModel = ScenesContainer.shared.homeViewModel()
    
    HomeView.MissedReflectionsListView(viewModel: viewModel)
}
