import SwiftUI

/// Shared call to action for onboarding and information screens.
struct PrimaryButton: View {
    var title: String
    var icon: String?
    var color: Color = Color("BrandPrimary")
    var action: () -> Void

    var body: some View {
        if #available(iOS 26.0, *) {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.borderedProminent)
        }
    }

    private var button: some View {
        Button(action: action) {
            Group {
                if let icon {
                    Label(title, systemImage: icon)
                } else {
                    Text(title)
                }
            }
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
        }
        .controlSize(.large)
        .buttonBorderShape(.capsule)
        .tint(color)
    }
}

#Preview {
    VStack(spacing: 24) {
        PrimaryButton(title: "Continue", icon: "arrow.right") {}
        PrimaryButton(title: "Continue") {}.disabled(true)
    }
    .padding()
}
