//
//  ReflectionsWidget.swift
//  iOS
//
//  Created by Grigor Dochev on 31.08.2024.
//

import SwiftUI

// MARK: - ReflectionsWidget

extension HomeView {
    struct ReflectionsWidget: View {
        
        // MARK: Properties

        @Bindable var viewModel: HomeViewModel

        // MARK: Body

        var body: some View {
            LabeledCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Summary of your most recent reflections.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if viewModel.reflections.isEmpty {
                        EmptyStateView(
                            image: "book.pages",
                            title: "No Reflections",
                            description: String(localized: "Tap the + button to create a reflection.")
                        )
                    } else {
                        recentReflectionsSummary
                    }

                    Divider()

                    createReflectionButton
                }
            } label: {
                Label("My Reflections", systemImage: "book.pages.fill")
                    .foregroundStyle(Color("BrandPrimary"))
            } accessory: {
                NavigationLink(value: HomeNavigationDestination.reviewsList) {
                    navigationAccessory("View")
                }
                .buttonStyle(.plain)
            }
        }

        // MARK: Create Reflection Button
        
        private var createReflectionButton: some View {
            Button {
                viewModel.presentSheet(.editReflectionView(nil))
            } label: {
                Label("Create Reflection", systemImage: "plus.circle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("BrandPrimary"))
            }
            .buttonStyle(.plain)
        }
        
        // MARK: Recent Reflections Summary
        
        private var recentReflectionsSummary: some View {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.recentReflections, id: \.id) { reflection in
                    reflectionRow(reflection)

                    if reflection != viewModel.recentReflections.last {
                        Divider()
                    }
                }
            }
            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }

        private func reflectionRow(_ reflection: Reflection) -> some View {
            Button {
                viewModel.presentSheet(.editReflectionView(reflection))
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: reflectionIconName(reflection))
                        .font(.headline)
                        .foregroundStyle(Color("BrandPrimary"))
                        .frame(width: 34, height: 34)
                        .background(Color("BrandPrimary").opacity(0.12), in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(reflectionTitle(reflection))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text(reflection.date.formatted(.dateTime.day().month().hour().minute()))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    reflectionAccessory(reflection)
                }
                .padding()
            }
            .buttonStyle(.plain)
        }

        @ViewBuilder
        private func reflectionAccessory(_ reflection: Reflection) -> some View {
            if reflection.didTriggerCrash {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red)
                    .frame(width: 30, height: 30)
                    .background(.red.opacity(0.12), in: Circle())
            } else if let mood = reflection.mood {
                Text(mood.emoji)
                    .font(.title3)
                    .frame(width: 30, height: 30)
                    .background(Color.yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else if let wellBeing = reflection.wellBeing {
                Image(systemName: "cross.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Symptom.wellBeing(wellBeing).color)
                    .frame(width: 30, height: 30)
                    .background(Symptom.wellBeing(wellBeing).color.opacity(0.12), in: Circle())
            }
        }

        private func reflectionIconName(_ reflection: Reflection) -> String {
            reflection.subactivity?.icon ?? reflection.activity?.icon ?? "questionmark"
        }

        private func reflectionTitle(_ reflection: Reflection) -> String {
            reflection.subactivity?.name ?? reflection.activity?.name ?? String(localized: "Uncategorized")
        }

        private func navigationAccessory(_ title: String) -> some View {
            HStack(spacing: 6) {
                Text(title)
                Image(systemName: "chevron.right")
            }
            .font(.subheadline)
            .foregroundStyle(Color(.systemGray2))
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.homeViewModel()

    ScrollView {
        HomeView.ReflectionsWidget(viewModel: viewModel)
            .padding()
    }
    .background(Color(.systemGroupedBackground))
}
