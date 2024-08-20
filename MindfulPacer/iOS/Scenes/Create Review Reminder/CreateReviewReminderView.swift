//
//  CreateReviewReminderView.swift
//  iOS
//
//  Created by Grigor Dochev on 15.08.2024.
//

import SwiftUI

// MARK: - Navigation Enums

enum CreateReviewReminderNavigationDestination: Hashable {
    case measurementType
    case alarmType
    case threshold
    case vibrationStrength
    case interval
    case summary
}

enum CreateReviewReminderSheet: Identifiable {
    case alarmTypeInfo
    case heartRateThresholdInfo
    case vibrationStrengthInfo
    case intervalInfo
    
    var id: Int {
        hashValue
    }
}

// MARK: - CreateReviewReminderView

struct CreateReviewReminderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.keyboardShowing) private var keyboardShowing
    @State var viewModel: CreateReviewReminderViewModel = ScenesContainer.shared.createReviewReminderViewModel()
    
    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                intro
            }
            .navigationTitle("Create Reminder")
            .alert(item: $viewModel.alertItem) { $0.alert }
            .sheet(item: $viewModel.activeSheet) { sheet in
                switch sheet {
                case .alarmTypeInfo:
                    alarmTypeInfoView
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                case .heartRateThresholdInfo:
                    thresholdInfoView
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                case .vibrationStrengthInfo:
                    vibrationStrengthInfoView
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                case .intervalInfo:
                    intervalInfoView
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                }
            }
            .navigationDestination(for: CreateReviewReminderNavigationDestination.self) { destination in
                switch destination {
                case .measurementType:
                    MeasurementTypeView(viewModel: viewModel)
                case .alarmType:
                    AlarmTypeView(viewModel: viewModel)
                case .threshold:
                    ThresholdView(viewModel: viewModel)
                case .vibrationStrength:
                    VibrationStrengthView(viewModel: viewModel)
                case .interval:
                    IntervalView(viewModel: viewModel)
                case .summary:
                    SummaryView(viewModel: viewModel)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if viewModel.showContinueButton {
                continueButton
            }
        }
    }
    
    private var continueButton: some View {
        PrimaryButton(title: viewModel.continueButtonTitle) {
            viewModel.continueButtonTapped()
        }
        .padding(keyboardShowing ? [.all] : [.horizontal, .top])
        .disabled(viewModel.isContinueButtonDisabled)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
    }
    
    private var intro: some View {
        VStack(spacing: 32) {
            // TODO: Change to literal using . notation
            Image("Create Review Reminder")
                .resizable()
                .scaledToFit()
            
            Text("This allows you to add a new alarm which can be triggered on your Apple Watch or iPhone.")
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
        }
        .padding()
    }
    
    private var alarmTypeInfoView: some View {
        InfoSheetView(
            title: "Alarm Type Information",
            info: "You can choose between three different alarm types.") {
                Text(
                    """
                    1. **Light**: coloured display, vibration.
                    2. **Medium**: vibration, confirmation required.
                    3. **Strong**: blinking display, vibration, sound, confirmation required.
                    """
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.subheadline)
            }
    }
    
    private var thresholdInfoView: some View {
        InfoSheetView(
            title: "Threshold Information",
            info: "Values that must be exceeded for the given interval (duration) so that the Review Reminder will be triggered."
        )
    }
    
    private var vibrationStrengthInfoView: some View {
        InfoSheetView(
            title: "Vibration Strength Information",
            info: "The vibration strength allows you to adjust how strong the smartwatch should vibrate when this alarm is triggered."
        ) {
            Text("You can test how the selected vibration strength feels by tapping on the '**Test**' button. Please ensure you are wearing your Apple Watch to be able to test this functionality.")
        }
    }
    
    private var intervalInfoView: some View {
        InfoSheetView(
            title: "Interval Information",
            info: "Duration during which the heart rate has to be greater than or equal to the threshold in order for the Review Reminder to be triggered."
        )
    }
}

// MARK: - Preview

#Preview {
    CreateReviewReminderView()
        .tint(Color("BrandPrimary"))
}
