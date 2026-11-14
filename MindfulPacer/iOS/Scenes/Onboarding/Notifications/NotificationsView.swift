import SwiftUI

extension OnboardingView {
    struct NotificationsView: View {
        @Bindable var viewModel: OnboardingViewModel

        var body: some View {
            OnboardingPage(viewModel: viewModel, title: String(localized: "Receive Reminders for Reflection"), systemImage: "bell.badge") {
                Text("MindfulPacer can remind you to reflect on your activities, energy management, moods and symptoms, for example at specific times or when a biometric value (such as your heart rate or steps) reaches a certain threshold.")
                    .foregroundStyle(Color.secondary)
                Text("You can always change this permission later, by navigating to Settings > Notifications > MindfulPacer.")
                    .font(.footnote).foregroundStyle(Color.secondary)
            }
        }
    }
}
