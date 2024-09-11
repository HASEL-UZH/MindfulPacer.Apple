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
    case disclaimer
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
                Color(.systemGroupedBackground)
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
        .safeAreaInset(edge: .bottom) {
            actionButton
        }
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
        case .activityPromotingFeatures:
            ActivityPromotingFeaturesView(viewModel: viewModel)
        case .disclaimer:
            DisclaimerView(viewModel: viewModel)
        }
    }
    
    // MARK: Action Button
    
    private var actionButton: some View {
        VStack(spacing: 16) {
            if viewModel.showAcceptTermsButton {
                acceptTermsButton
            }
            
            PrimaryButton(title: viewModel.actionButtonTitle) {
                viewModel.actionButtonTapped()
            }
            .disabled(viewModel.isActionButtonDisabled)
        }
        .padding([.horizontal, .top])
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { newValue in
            viewModel.actionButtonHeight = newValue.height
        }
    }
    
    // MARK: Accept Terms Button
    
    private var acceptTermsButton: some View {
        HStack(spacing: 8) {
            Button {
                withAnimation {
                    viewModel.didAcceptTerms.toggle()
                }
            } label: {
                Image(systemName: viewModel.didAcceptTerms ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.semibold))
            }
            .contentTransition(.symbolEffect(.replace))
            .foregroundStyle(Color("BrandPrimary"))
            
            Text("I Understand and Accept")
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Onboarding Page

extension OnboardingView {
    struct OnboardingPage<Content: View>: View {
        // MARK: Properties
        
        @Bindable var viewModel: OnboardingViewModel
        var title: String
        var showSkipButton: Bool = true
        var content: () -> Content
        
        // MARK: Body
        
        var body: some View {
            ScrollView {
                VStack(spacing: 16) {
                    Text(title)
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    content()
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .safeAreaPadding(.bottom, viewModel.actionButtonHeight)
            .background {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
            }
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
