//
//  Date+Extensions.swift
//  iOS
//
//  Created by Grigor Dochev on 17.09.2024.
//

import Foundation

extension Date {
    var weekdayInt: Int {
        Calendar.current.component(.weekday, from: self)
    }
}
