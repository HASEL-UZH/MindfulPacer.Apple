import SwiftUI

extension OnboardingView {
    struct ActivityPromotingFeaturesView: View {
        @Bindable var viewModel: OnboardingViewModel

        var body: some View {
            OnboardingPage(viewModel: viewModel, title: String(localized: "Disable Activity Promoting Features"), systemImage: "bell.slash") {
                Text("Apple has many activity-promoting features on the iPhone and Apple Watch. If you want to disable these features, follow these steps.")
                    .foregroundStyle(Color.secondary)
                VStack(spacing: 12) {
                    ForEach(viewModel.activityPromotingFeatures, id: \.title) { feature in
                        SetupDetail(label: IconLabel(icon: feature.icon, title: feature.title, labelColor: Color.primary)) {
                            Text(feature.steps).frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
    }
}
