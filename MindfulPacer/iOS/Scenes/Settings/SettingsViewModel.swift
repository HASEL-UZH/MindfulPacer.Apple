//
//  SettingsViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 13.09.2024.
//

import CocoaLumberjackSwift
import Foundation
import MessageUI

@Observable
class SettingsViewModel {
    
    // MARK: - Dependencies
    // MARK: - Published Properties
    
    var activeSheet: SettingsSheet?
    
    var mailResult: Result<MFMailComposeResult, Error>?
    
    // MARK: - Initialization
    
    init(
    ) {
    }
    
    // MARK: - View Events
    
    func onViewAppear() {}
    
    // MARK: - Presentation
    
    func presentSheet(_ sheet: SettingsSheet) {
        DDLogInfo("Presenting sheet: \(sheet)")
        activeSheet = sheet
    }
    
    // MARK: - User Actions
    
    // MARK: - Private Methods
}
