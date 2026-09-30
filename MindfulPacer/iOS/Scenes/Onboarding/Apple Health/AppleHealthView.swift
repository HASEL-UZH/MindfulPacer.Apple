import SwiftUI

extension OnboardingView {
    struct AppleHealthView: View {
        @Bindable var viewModel: OnboardingViewModel

        var body: some View {
            OnboardingPage(viewModel: viewModel, title: String(localized: "Connect to Apple Health"),
                           systemImage: "heart.text.clipboard", showSkipButton: false) {
                Text(
                    """
                    MindfulPacer can visualize your biometric data (as measured by your Apple Watch) and visualize it together with your diary entries in the Analysis page.
                    
                    Please allow MindfulPacer to access your Apple Health data. Select the biometric data that you want to share (e.g. heart rate and/or steps).
                    """
                )
                .foregroundStyle(Color.secondary)

                Label {
                    Text(viewModel.descriptionForPermissions).foregroundStyle(Color.primary)
                } icon: {
                    Image(systemName: "checkmark.shield").foregroundStyle(Color.brandPrimary)
                }

                SetupDetail(label: IconLabel(icon: "hand.raised", title: String(localized: "Correct Permissions"), labelColor: Color.primary)) {
                    Image(viewModel.imageNameForPermissions)
                        .resizable().scaledToFit()
                        .frame(maxHeight: 360)
                        .frame(maxWidth: .infinity)
                }

                Text("You can always change this permission later, by navigating to Settings > Privacy & Security > Health > MindfulPacer.")
                    .font(.footnote).foregroundStyle(Color.secondary)
            }
        }
    }
}
