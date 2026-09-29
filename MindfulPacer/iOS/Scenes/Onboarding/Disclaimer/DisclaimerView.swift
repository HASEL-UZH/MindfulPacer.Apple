import SwiftUI

extension OnboardingView {
    struct DisclaimerView: View {
        @Bindable var viewModel: OnboardingViewModel

        var body: some View {
            OnboardingPage(viewModel: viewModel, title: String(localized: "Disclaimer"),
                           systemImage: "exclamationmark.triangle.fill", symbolTint: .orange, showSkipButton: false) {
                Text(
                    """
                    MindfulPacer as well as the Apple Watch are **NOT** medical grade apps and may display inaccurate data.

                    MindfulPacer only processes raw data from your Apple Watch and your diary entries, and does **NOT** make automated recommendations.

                    Do **NOT** solely rely on MindfulPacer for pacing and managing your activities and energy.

                    When in doubt, please contact an experienced physician, personal trainer or other qualified professional.
                    """
                )
                .foregroundStyle(Color.primary)
                .lineSpacing(4)
                Text("You can reach out to the following email address in case you have further questions: **support@mindfulpacer.ch**")
                    .font(.footnote).foregroundStyle(Color.secondary)

                GroupBox {
                    Toggle("I Understand and Accept", isOn: $viewModel.didAcceptTerms)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary)
                        .tint(.brandPrimary)
                }
            }
        }
    }
}
