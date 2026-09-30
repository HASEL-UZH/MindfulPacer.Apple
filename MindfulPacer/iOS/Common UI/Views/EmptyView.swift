import SwiftUI

struct EmptyStateView: View {
    var image: String
    var title: String
    var description: String
    var isCompact = false
    var buttonTitle: String?
    var buttonAction: (() -> Void)?

    var body: some View {
        if isCompact {
            VStack(spacing: 8) {
                Image(systemName: image)
                    .font(.title2)
                    .symbolVariant(.fill)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.callout.weight(.semibold))
                Text(description)
                    .font(.footnote)
                    .fixedSize(horizontal: false, vertical: true)
                if let buttonTitle, let buttonAction {
                    Button(buttonTitle, action: buttonAction)
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .tint(.brandPrimary)
                }
            }
            .foregroundStyle(Color.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        } else {
            standardContent
        }
    }

    private var standardContent: some View {
        ContentUnavailableView {
            Label(title, systemImage: image)
        } description: {
            Text(description)
        } actions: {
            if let buttonTitle, let buttonAction {
                Button(buttonTitle, action: buttonAction)
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .tint(.brandPrimary)
            }
        }
    }
}
