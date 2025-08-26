//
//  MissedReflectionsView.swift
//  iOS
//
//  Created by Grigor Dochev on 22.08.2025.
//

import SwiftUI
import CardStack
import Charts

// MARK: - MissedReflectionsView

struct MissedReflectionsView: View {
    
    // MARK: Properties
    
    @Bindable var viewModel: HomeViewModel
    @State private var currentIndex: Int = 0
    @State private var currentReflection: Reflection?
    
    // MARK: Body
    
    var body: some View {
        NavigationStack {
            if viewModel.missedReflections.isEmpty {
                emptyState
                    .navigationTitle("Missed Reflections")
            } else {
                cardStack
            }
        }
        .onAppear {
            if currentReflection == nil, !viewModel.missedReflections.isEmpty {
                currentReflection = viewModel.missedReflections[currentIndex]
            }
        }
    }
    
    // MARK: Card Stack
    
    private var cardStack: some View {
        VStack(spacing: 16) {
            CardStack(
                viewModel.missedReflections,
                currentIndex: $currentIndex
            ) { missedReflection in
                missedReflectionCard(missedReflection)
            }
            .padding(.horizontal)
            .onChange(of: currentIndex) { oldIndex, newIndex in
                self.currentReflection = nil
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    guard newIndex < viewModel.missedReflections.count else { return }
                    self.currentReflection = viewModel.missedReflections[newIndex]
                }
            }
            
            IconLabel(
                icon: "arrow.left.and.line.vertical.and.arrow.right",
                title: "Swipe the cards to view more missed reflections",
                labelColor: .secondary
            )
            .font(.footnote)
        }
        .navigationTitle("Missed Reflections")
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                CloseButton()
            }
        }
    }
    
    // MARK: Empty State
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Missed Reflections", systemImage: "square.stack.fill")
        } description: {
            Text("You do not have any missed reflections.")
        }
    }
    
    // MARK: Missed Reflection Card
    
    @ViewBuilder
    func missedReflectionCard(_ reflection: Reflection) -> some View {
        VStack {
            VStack(spacing: 32) {
                Card(backgroundColor: Color(.tertiarySystemGroupedBackground)) {
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                IconLabel(
                                    icon: reflection.measurementType?.icon,
                                    title: reflection.measurementType?.localized ?? "",
                                    labelColor: reflection.measurementType == .heartRate ? .pink : .teal
                                )
                                .font(.subheadline.weight(.semibold))
                                
                                Text(reflection.reminderTriggerSummary)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            Icon(
                                name: "alarm",
                                color: reflection.reminderType!.color,
                                background: true
                            )
                        }
                        .foregroundStyle(Color.primary)
                        
                        Divider()
                        
                        IconLabel(title: String(localized: "Triggered on \(reflection.date.formatted(.dateTime.month().day().hour().minute()))"))
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                
                Spacer()
                
                Card(backgroundColor: Color(.tertiarySystemGroupedBackground)) {
                    Group {
                        if reflection.id == currentReflection?.id {
                            TriggerDataChartView(reflection: reflection)
                        } else {
                            ProgressView()
                                .frame(height: 256)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .controlSize(.extraLarge)
                                .tint(.primary)
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                actionButtons(for: reflection)
                    .padding()
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .foregroundStyle(Color(.secondarySystemGroupedBackground))
                
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            }
        )
    }
    
    // MARK: Action Buttons
    
    @ViewBuilder
    private func actionButtons(for reflection: Reflection) -> some View {
        HStack(spacing: 0) {
            Button {
                viewModel.rejectMissedReflection(reflection: reflection)
            } label: {
                ZStack {
                    UnevenRoundedRectangle(cornerRadii: .init(topLeading: 16, bottomLeading: 16))
                        .foregroundStyle(.red.opacity(0.1))
                    
                    IconLabel(icon: "xmark", title: String(localized: "Reject"), labelColor: .red)
                        .font(.body.weight(.semibold))
                    
                    UnevenRoundedRectangle(cornerRadii: .init(topLeading: 16, bottomLeading: 16))
                        .stroke(Color.secondary, lineWidth: 1)
                }
            }
            .contentShape(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 16, bottomLeading: 16)))
            
            Button {
                viewModel.acceptMissedReflection(reflection: reflection)
            } label: {
                ZStack {
                    UnevenRoundedRectangle(cornerRadii: .init(bottomTrailing: 16, topTrailing: 16))
                        .foregroundStyle(.green.opacity(0.1))
                    
                    IconLabel(icon: "checkmark", title: String(localized: "Accept"), labelColor: .green)
                        .font(.body.weight(.semibold))
                    
                    UnevenRoundedRectangle(cornerRadii: .init(bottomTrailing: 16, topTrailing: 16))
                        .stroke(Color.secondary, lineWidth: 1)
                }
            }
            .contentShape(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 16, bottomLeading: 16)))
        }
        .frame(height: 52)
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.homeViewModel()
    
    MissedReflectionsView(viewModel: viewModel)
}
