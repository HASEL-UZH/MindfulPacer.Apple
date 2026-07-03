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
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.displayedMissedReflections, id: \.id) { reflection in
                        LabeledCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text(reflection.reminderTriggerSummary)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                TriggerDataChartView(reflection: reflection)
                                    .frame(height: 150)
                                
                                Text(String(localized: "Triggered on \(reflection.date.formatted(.dateTime.month().day().hour().minute()))"))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                Divider()

                                actionButtons(for: reflection)
                            }
                        } label: {
                            Label(
                                reflection.measurementType?.localized ?? String(localized: "Measurement"),
                                systemImage: reflection.measurementType?.icon ?? "waveform.path.ecg"
                            )
                            .foregroundStyle(reflection.measurementType?.color ?? Color("BrandPrimary"))
                        } accessory: {
                            missedReflectionAccessory(reflection)
                        }
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
                            Label("Load More", systemImage: "arrow.down.circle.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color("BrandPrimary"))
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

        @ViewBuilder
        private func missedReflectionAccessory(_ reflection: Reflection) -> some View {
            if let reminderType = reflection.reminderType {
                Image(systemName: "alarm")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(reminderType.color)
                    .frame(width: 30, height: 30)
                    .background(reminderType.color.opacity(0.12), in: Circle())
            }
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
