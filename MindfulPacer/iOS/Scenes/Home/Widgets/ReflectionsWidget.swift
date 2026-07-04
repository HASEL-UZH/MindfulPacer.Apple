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
            NavigationLink(value: HomeNavigationDestination.reviewsList) {
                LabeledCard(
                    contentSpacing: 18,
                    contentPadding: 16,
                    cornerRadius: 24
                ) {
                    VStack(alignment: .leading, spacing: 14) {
                        if viewModel.reflections.isEmpty {
                            EmptyStateView(
                                image: "book.pages",
                                title: "No Reflections",
                                description: String(localized: "Tap the + button to create a reflection.")
                            )
                        } else {
                            Text(reflectionsHeadline)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)

                            Divider()

                            recentReflectionsSummary
                        }

                        Divider()

                        createReflectionButton
                    }
                } label: {
                    Label("My Reflections", systemImage: "book.pages.fill")
                        .foregroundStyle(Color("BrandPrimary"))
                } accessory: {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(.systemGray2))
                }
            }
            .buttonStyle(.plain)
        }

        // MARK: Create Reflection Button
        
        private var createReflectionButton: some View {
            Button {
                viewModel.presentSheet(.editReflectionView(nil))
            } label: {
                Label("Create Reflection", systemImage: "plus.circle.fill")
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
        }

        private func reflectionRow(_ reflection: Reflection) -> some View {
            Button {
                viewModel.presentSheet(.editReflectionView(reflection))
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: reflectionIconName(reflection))
                        .font(.headline)
                        .foregroundStyle(reflectionTint(reflection))
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(reflectionTitle(reflection))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(reflection.date.formatted(.dateTime.month(.abbreviated).day()))

                            subtitleSeparator

                            Text(reflection.date.formatted(.dateTime.hour().minute()))

                            if reflectionHasMetadata(reflection) {
                                subtitleSeparator

                                reflectionMetadata(reflection)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    }
                }
                .padding(.vertical, 10)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }

        @ViewBuilder
        private func reflectionMetadata(_ reflection: Reflection) -> some View {
            if reflection.didTriggerCrash {
                Text("Crash")
                    .foregroundStyle(.red)
            } else if let mood = reflection.mood {
                Text("\(mood.emoji) \(mood.text)")
            } else if let wellBeing = reflection.wellBeing {
                Text(Symptom.wellBeing(wellBeing).description)
                    .foregroundStyle(Symptom.wellBeing(wellBeing).color)
            }
        }

        private var subtitleSeparator: some View {
            Rectangle()
                .fill(Color(.separator))
                .frame(width: 1, height: 13)
        }

        private func reflectionHasMetadata(_ reflection: Reflection) -> Bool {
            if reflection.didTriggerCrash {
                return true
            }

            return reflection.mood != nil || reflection.wellBeing != nil
        }

        private func reflectionIconName(_ reflection: Reflection) -> String {
            reflection.subactivity?.icon ?? reflection.activity?.icon ?? "questionmark"
        }

        private func reflectionTint(_ reflection: Reflection) -> Color {
            if reflection.didTriggerCrash {
                return .red
            }

            if let wellBeing = reflection.wellBeing {
                return Symptom.wellBeing(wellBeing).color
            }

            return Color("BrandPrimary")
        }

        private func reflectionTitle(_ reflection: Reflection) -> String {
            reflection.subactivity?.name ?? reflection.activity?.name ?? String(localized: "Uncategorized")
        }

        private var reflectionsHeadline: String {
            switch viewModel.reflections.count {
            case 1:
                String(localized: "You've logged 1 reflection.")
            default:
                String(localized: "You've logged \(viewModel.reflections.count) reflections.")
            }
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
