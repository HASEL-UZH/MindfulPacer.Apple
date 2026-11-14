import SwiftUI

struct ReminderCell: View {
    let rule: AlertRule

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Label(rule.measurementType.localized, systemImage: rule.measurementType.icon)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(rule.measurementType.color)
                Spacer(minLength: 2)
                Image(systemName: rule.reminderType.icon)
                    .foregroundStyle(rule.reminderType.color)
                    .accessibilityLabel(rule.reminderType.localized)
            }
            Text(rule.alertMessage)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
    }
}
