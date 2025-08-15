//
//  ActiveAlertsView.swift
//  WatchOS
//
//  Created by Grigor Dochev on 15.08.2025.
//

import SwiftUI

struct ActiveAlertsView: View {
    @Bindable var viewModel: HomeViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                ForEach(viewModel.activeRules) { alertRule in
                    ReminderCell(rule: alertRule)
                }
            }
            .navigationTitle("Active Reminders")
        }
    }
}

#Preview {
    ActiveAlertsView(viewModel: HomeViewModel())
}
