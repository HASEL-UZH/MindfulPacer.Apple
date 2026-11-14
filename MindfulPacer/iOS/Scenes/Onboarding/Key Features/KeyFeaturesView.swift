import SwiftUI

extension OnboardingView {
    struct KeyFeaturesView: View {
        @Bindable var viewModel: OnboardingViewModel

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 36) {
                    VStack(spacing: 16) {
                        Image("MindfulPacer Icon")
                            .resizable().scaledToFit()
                            .frame(width: 88, height: 88)
                            .accessibilityHidden(true)
                        Text("MindfulPacer")
                            .font(.largeTitle.bold())
                            .lineLimit(1)
                            .minimumScaleFactor(0.4)
                            .foregroundStyle(Color.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 32)

                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(viewModel.keyFeatures, id: \.title) { feature in
                            HStack(alignment: .top, spacing: 16) {
                                Image(systemName: feature.icon)
                                    .font(.title2)
                                    .foregroundStyle(Color.brandPrimary)
                                    .frame(width: 32)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(feature.title).font(.headline)
                                    Text(feature.description)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
                .frame(maxWidth: 600)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ActionBar(viewModel: viewModel)
            }
            .background(Color(.systemBackground))
            .scrollEdgeEffectStyle(.soft, for: .bottom)
        }
    }
}

#Preview { OnboardingView() }
