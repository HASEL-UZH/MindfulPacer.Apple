//
//  RootViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 05.07.2024.
//

import Foundation

class RootViewModel: ObservableObject {
    @Published private(set) var state: RootViewState = .initial
    
    init() {
    }
    
    // MARK: View Events
    
    func onViewFirstAppear() {
       
    }
    
    // MARK: Observing and Updating State
}
