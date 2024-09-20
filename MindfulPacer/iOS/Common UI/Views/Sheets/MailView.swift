//
//  MailView.swift
//  iOS
//
//  Created by Grigor Dochev on 17.09.2024.
//

import SwiftUI
import MessageUI

// MARK: - MailView

struct MailView: UIViewControllerRepresentable {
    @Binding var result: Result<MFMailComposeResult, Error>?
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var result: Result<MFMailComposeResult, Error>?
        
        init(result: Binding<Result<MFMailComposeResult, Error>?>) {
            _result = result
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            guard error == nil else {
                self.result = .failure(error!)
                return
            }
            
            self.result = .success(result)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(result: $result)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
        let viewController = MFMailComposeViewController()
        viewController.mailComposeDelegate = context.coordinator
        viewController.setToRecipients(["strengtheon@gmail.com"])
        
        // Adding subject and body
        viewController.setSubject("Bug Report for Strengtheon")
        let messageBody = """
        **Bug Report for Strengtheon**
        
        **Information:**
        - App Version: [App version where the bug was encountered]
        - Date: [Date when the report is being sent]
        
        **Device Information:**
        - Device: [e.g., iPhone 14 Pro]
        - OS Version: [e.g., iOS 15.4]
        
        **Bug Description:**
        Please describe the issue in detail. Include what you were trying to do when the bug occurred, and any specific actions that triggered the issue.
        
        **Steps to Reproduce:**
        1. [First step]
        2. [Second step]
        3. [And so on...]
        
        **Expected Behavior:**
        Describe what you expected to happen when you performed the above steps.
        
        **Actual Behavior:**
        Describe what actually happened instead.
        
        **Frequency:**
        How often does the bug occur? [Always, sometimes (please specify frequency), once]
        
        **Screenshots:**
        If possible, attach screenshots or videos that demonstrate the issue.
        
        **Additional Information:**
        Include any other information that you think could be helpful in diagnosing the problem, such as specific settings used.
        """
        viewController.setMessageBody(messageBody, isHTML: false)
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: UIViewControllerRepresentableContext<MailView>) {}
}
