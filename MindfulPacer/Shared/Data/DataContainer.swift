//
//  DataContainer.swift
//  iOS
//
//  Created by Grigor Dochev on 05.07.2024.
//

import Factory

final class DataContainer: SharedContainer, @unchecked Sendable {
    static let shared = DataContainer()
    var manager = ContainerManager()
}
