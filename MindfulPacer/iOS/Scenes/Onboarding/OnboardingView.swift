//
//  OnboardingView.swift
//  iOS
//
//  Created by Grigor Dochev on 10.09.2024.
//

import SwiftUI

// MARK: - Presentation Enums

enum OnboardingNavigationDestination: Hashable {
    case appleWatchConnection
    case notifications
    case appleHealth
    case mainFeatures
    case activityPromotingFeatures
    case modeOfUse
    case disclaimer
    case deviceMode
}

// MARK: - OnboardingView

struct OnboardingView: View {

    // MARK: Properties

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: OnboardingViewModel = ScenesContainer.shared.onboardingViewModel()

    // MARK: Body

    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                KeyFeaturesView(viewModel: viewModel)
            }
            .navigationDestination(for: OnboardingNavigationDestination.self) { destination in
                navigationDestination(for: destination)
            }
            .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
                if shouldDismiss {
                    dismiss()
                }
            }
        }
        .onViewFirstAppear { viewModel.onViewFirstAppear() }
    }

    // MARK: Navigation Destination

    @ViewBuilder
    private func navigationDestination(for destination: OnboardingNavigationDestination) -> some View {
        switch destination {
        case .appleWatchConnection:
            AppleWatchConnectionView(viewModel: viewModel)
        case .notifications:
            NotificationsView(viewModel: viewModel)
        case .appleHealth:
            AppleHealthView(viewModel: viewModel)
        case .mainFeatures:
            MainFeaturesView(viewModel: viewModel)
        case .modeOfUse:
            ModeOfUseView(viewModel: viewModel)
        case .activityPromotingFeatures:
            ActivityPromotingFeaturesView(viewModel: viewModel)
        case .disclaimer:
            DisclaimerView(viewModel: viewModel)
        case .deviceMode:
            DeviceModeView(viewModel: viewModel)
        }
    }

}

extension OnboardingView {
    struct ActionBar: View {
        @Bindable var viewModel: OnboardingViewModel

        var body: some View {
            PrimaryButton(title: viewModel.actionButtonTitle) {
                viewModel.actionButtonTapped()
            }
            .disabled(viewModel.isActionButtonDisabled)
            .frame(maxWidth: 600)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(.bar)
        }
    }
}

// MARK: - Onboarding Page

extension OnboardingView {
    struct OnboardingPage<Content: View>: View {

        // MARK: Properties

        @Bindable var viewModel: OnboardingViewModel
        var title: String
        var systemImage: String = "sparkles"
        var symbolTint: Color = .brandPrimary
        var showSkipButton: Bool = true
        @ViewBuilder var content: () -> Content

        // MARK: Body

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Image(systemName: systemImage)
                        .font(.system(size: 64, weight: .regular))
                        .foregroundStyle(symbolTint.gradient)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .accessibilityHidden(true)

                    Text(title)
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)

                    content()

                }
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ActionBar(viewModel: viewModel)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background {
                Color(.systemBackground)
                    .ignoresSafeArea()
            }
            .navigationBarTitleDisplayMode(.inline)
            .scrollEdgeEffectStyle(.soft, for: .bottom)
            .toolbar {
                if showSkipButton {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Skip") {
                            viewModel.skipButtonTapped()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .tint(Color("BrandPrimary"))
}

// MARK: - Onboarding Details

extension OnboardingView {
    /// Secondary setup instructions stay available without dominating the step.
    struct SetupDetail<Content: View, Footer: View>: View {
        let label: IconLabel
        var description: Text?
        @ViewBuilder var content: () -> Content
        @ViewBuilder var footer: () -> Footer

        @State private var isExpanded = false

        var body: some View {
            LabeledCard(contentSpacing: 12) {
                description?
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if isExpanded {
                    VStack(alignment: .leading, spacing: 16) {
                        content()
                        footer()
                    }
                    .foregroundStyle(Color.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } label: {
                Button {
                    withAnimation(.snappy) { isExpanded.toggle() }
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        label.frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                    .contentShape(.rect)
                }
                .accessibilityValue(isExpanded ? String(localized: "Details expanded") : String(localized: "Details collapsed"))
            }
            .backgroundStyle(Color(.secondarySystemBackground))
        }
    }

    struct ChoiceRow: View {
        let title: String
        let description: String
        let isSelected: Bool
        let action: () -> Void

        var body: some View {
            SingleSelectRow(isSelected: isSelected, action: action) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline).foregroundStyle(isSelected ? Color.brandPrimary : Color.primary)
                    Text(description).font(.subheadline).foregroundStyle(Color.secondary)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

extension OnboardingView.SetupDetail where Footer == EmptyView {
    init(label: IconLabel, description: Text? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.description = description
        self.content = content
        self.footer = { EmptyView() }
    }
}
