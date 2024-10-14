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
    
    // MARK: Coordinator
    
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
    
    // MARK: View Controller
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
        let viewController = MFMailComposeViewController()
        viewController.mailComposeDelegate = context.coordinator
        viewController.setToRecipients(["support@mindfulpacer.ch"])
        viewController.setSubject("MindfulPacer - Feedback/Question")
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: UIViewControllerRepresentableContext<MailView>) {}
}
