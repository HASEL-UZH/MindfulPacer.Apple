import SwiftUI

extension HomeView {
    struct ReflectionsWidget: View {
        @Bindable var viewModel: HomeViewModel

        let onOpenList: () -> Void

        var body: some View {
            LabeledCard(
                contentSpacing: 12,
                action: onOpenList,
                actionAccessibilityIdentifier: "home.reflections.showAll"
            ) {
                if viewModel.reflections.isEmpty {
                    Button(action: onOpenList) {
                        EmptyStateView(image: "book.pages", title: String(localized: "No Reflections"),
                                       description: String(localized: "Record how you feel with a reflection."),
                                       isCompact: true)
                            .frame(maxWidth: .infinity)
                            .contentShape(.rect)
                    }
                } else {
                    VStack(spacing: 0) {
                        ForEach(viewModel.recentReflections) { reflection in
                            if reflection.id != viewModel.recentReflections.first?.id {
                                Divider().padding(.leading, 36)
                            }
                            Button {
                                viewModel.presentSheet(.editReflectionView(reflection))
                            } label: {
                                historyRow(reflection)
                            }
                            .accessibilityIdentifier("home.reflection.\(reflection.id)")
                        }
                    }
                }
            } label: {
                Label("My Reflections", systemImage: "book.pages.fill")
                    .foregroundStyle(Color.accentColor)
            } accessory: {
                HStack(spacing: 4) {
                    Text("Show All")
                    Image(systemName: "chevron.right")
                }
                .font(.subheadline)
                .foregroundStyle(Color.accentColor)
            }
        }

        private func historyRow(_ reflection: Reflection) -> some View {
            HStack(spacing: 12) {
                Image(systemName: reflection.subactivity?.icon ?? reflection.activity?.icon ?? "book.closed")
                    .font(.body)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 4) {
                    Text(reflection.subactivity?.name ?? reflection.activity?.name ?? String(localized: "Uncategorized"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary)
                    Text(reflection.date, format: .dateTime.month(.abbreviated).day().hour().minute())
                        .font(.caption).foregroundStyle(Color.secondary)
                    if reflection.didTriggerCrash {
                        Label("Crash", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption).foregroundStyle(.red)
                    } else if let wellBeing = reflection.wellBeing {
                        Text(Symptom.wellBeing(wellBeing).description)
                            .font(.caption).foregroundStyle(Symptom.wellBeing(wellBeing).color)
                    } else if let mood = reflection.mood {
                        Text("\(mood.emoji) \(mood.text)")
                            .font(.caption).foregroundStyle(Color.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(minHeight: 44)
            .padding(.top, reflection.id == viewModel.recentReflections.first?.id ? 0 : 8)
            .padding(.bottom, reflection.id == viewModel.recentReflections.last?.id ? 0 : 8)
            .contentShape(.rect)
        }
    }
}
