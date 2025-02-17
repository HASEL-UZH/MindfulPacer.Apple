//
//  Calendar+Extensions.swift
//  iOS
//
//  Created by Grigor Dochev on 07.02.2025.
//

import Foundation

extension Calendar {
    func endOfDay(for date: Date) -> Date {
        let startOfDay = self.startOfDay(for: date)
        return self.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay)!
    }
}
