import SwiftUI

extension OnboardingView {
    struct MainFeaturesView: View {
        @Bindable var viewModel: OnboardingViewModel

        var body: some View {
            OnboardingPage(viewModel: viewModel, title: String(localized: "Main Features"), systemImage: "chart.xyaxis.line") {
                VStack(alignment: .leading, spacing: 32) {
                    ForEach(viewModel.mainFeatures, id: \.title) { feature in
                        VStack(alignment: .leading, spacing: 16) {
                            Text(feature.title).font(.title2.bold())
                            Text(feature.description).foregroundStyle(Color.secondary)
                            CroppedIPhoneImage(Image(feature.image), heightRatio: 1.05, fill: true)
                                .accessibilityLabel(feature.title)
                                .accessibilityIdentifier("onboarding.feature.\(feature.image)")
                            ForEach(feature.points, id: \.self) { point in
                                Label {
                                    Text(point).foregroundStyle(Color.primary)
                                } icon: {
                                    Image(systemName: "checkmark").foregroundStyle(Color.brandPrimary)
                                }
                                .font(.subheadline)
                            }
                        }
                    }
                }
            }
        }
    }
}
