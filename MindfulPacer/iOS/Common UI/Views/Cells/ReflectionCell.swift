//
//  ReflectionCell.swift
//  iOS
//
//  Created by Grigor Dochev on 01.09.2024.
//

import SwiftUI

// MARK: - ReflectionCell

struct ReflectionCell: View {
    
    // MARK: Properties
    
    @AppStorage(ModeOfUse.appStorageKey, store: DefaultsStore.shared)
    private var modeOfUseRaw: String = ModeOfUse.essentials.rawValue
    
    private var modeOfUse: ModeOfUse {
        ModeOfUse(rawValue: modeOfUseRaw) ?? .essentials
    }
    
    var reflection: Reflection
    var backgroundColor: Color = Color(.secondarySystemGroupedBackground)
    var onTap: () -> Void
    
    // MARK: Body
    
    var body: some View {
        Button {
            onTap()
        } label: {
            cellContent
                .padding()
                .background(backgroundColor)
        }
    }
    
    // MARK: Cell Content

    private var cellContent: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                if let subactivity = reflection.subactivity {
                    IconLabel(icon: subactivity.icon, title: subactivity.name, labelColor: Color.primary)
                        .font(.subheadline.weight(.semibold))
                } else if let activity = reflection.activity {
                    IconLabel(icon: activity.icon, title: activity.name, labelColor: Color.primary)
                        .font(.subheadline.weight(.semibold))
                } else {
                    IconLabel(
                        icon: "questionmark",
                        title: String(localized: "Uncategorized"),
                        labelColor: Color.primary
                    )
                    .font(.subheadline.weight(.semibold))
                }

                Text(reflection.date.formatted(.dateTime.day().month().hour().minute()))
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)

                ReflectionStatusLabels(reflection: reflection)
                    .font(.caption)
            }

            Spacer()

            if modeOfUse != .essentials, let mood = reflection.mood {
                Text(mood.emoji)
                    .font(.title3)
                    .accessibilityLabel(mood.text)
            }
        }
    }
}

// MARK: - Preview

// TODO: Add mock reflection
//#Preview {
//    ReflectionCell(reflection: Reflection()) {
//
//    }
//}

/// Shared by history, Home, and Analytics so a severity value always has context.
struct ReflectionStatusLabels: View {
    let reflection: Reflection

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let value = reflection.wellBeing {
                let wellBeing = Symptom.wellBeing(value)
                Label {
                    Text("\(Text("Subjective Well-being")): \(Text(wellBeing.description))")
                } icon: {
                    Image(systemName: wellBeing.icon)
                }
                .foregroundStyle(wellBeing.color)
            }
            if reflection.didTriggerCrash {
                Label("Crash", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
        }
        .labelStyle(.titleAndIcon)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }
}
