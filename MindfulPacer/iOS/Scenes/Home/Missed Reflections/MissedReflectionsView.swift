//
//  MissedReflectionsView.swift
//  iOS
//
//  Created by Grigor Dochev on 30.12.2024.
//

import SwiftUI

// MARK: - MissedReflectionsView

struct MissedReflectionsView: View {
    
    // MARK: Properties
        
    @Bindable var viewModel: HomeViewModel
    
    // MARK: Body
        
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TabView {
                    ForEach(viewModel.missedReflections) { missedReflection in
                        missedReflectionCard(missedReflection)
                    }
                }
                .tabViewStyle(
                    PageTabViewStyle(indexDisplayMode: .always)
                )
              
                Spacer()
                
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
    }
    
    @ViewBuilder func missedReflectionCard(_ missedReflection: MissedReflection) -> some View {
        VStack {
            VStack(spacing: 32) {
                IconLabel(
                    icon: "bell.badge.fill",
                    title: "Triggered at \(missedReflection.date.formatted(.dateTime.month().day().hour().minute()))",
                    labelColor: .brandPrimary,
                    background: true
                )
                .font(.title3 .weight(.semibold))
                .padding([.top, .horizontal])
           
                Card(backgroundColor: Color(.tertiarySystemGroupedBackground)) {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            IconLabel(
                                icon: missedReflection.measurementType.icon,
                                title: missedReflection.measurementType.rawValue,
                                labelColor: missedReflection.measurementType == .heartRate ? .pink : .teal
                            )
                            .font(.subheadline.weight(.semibold))
                            
                            Text(missedReflection.triggerSummary)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Icon(
                            name: "alarm",
                            color: missedReflection.reminderType.color,
                            background: true
                        )
                    }
                    .foregroundStyle(Color.primary)
                }
                .padding(.horizontal)
                
                Spacer()

                HStack(spacing: 8) {
                    Button {
                        viewModel.rejectMissedReflection(missedReflection)
                    } label: {
                        ZStack {
                            UnevenRoundedRectangle(cornerRadii: .init(topLeading: 16, bottomLeading: 16))
                                .foregroundStyle(.red.opacity(0.7))
                            
                            IconLabel(icon: "xmark", title: "Reject")
                                .font(.body.weight(.semibold))
                            
                            UnevenRoundedRectangle(cornerRadii: .init(topLeading: 16, bottomLeading: 16))
                                .stroke(Color.red, lineWidth: 1)
                        }
                    }
                    
                    Button {
                        viewModel.acceptMissedReflection(missedReflection)
                    } label: {
                        ZStack {
                            UnevenRoundedRectangle(cornerRadii: .init(bottomTrailing: 16, topTrailing: 16))
                                .foregroundStyle(.green.opacity(0.7))
                            
                            IconLabel(icon: "checkmark", title: "Accept")
                                .font(.body.weight(.semibold))
                            
                            UnevenRoundedRectangle(cornerRadii: .init(bottomTrailing: 16, topTrailing: 16))
                                .stroke(Color.green, lineWidth: 1)
                        }
                    }
                }
                .frame(height: 52)
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
        .padding()
        .padding(.bottom, 32)
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.homeViewModel()

    MissedReflectionsView(viewModel: viewModel)
}
