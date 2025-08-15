//
//  Message.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 19.08.2024.
//

import Foundation

// MARK: - MessageCommand

/// Manages the types of commands you send, ensuring type safety and reducing hardcoding.
enum MessageCommand: String {
    case triggerLocalNotification
    case remindersUpdated
    case createReflection
    case requestCreateReflection
    case openReflectionForEditing
}

// MARK: - MessageKeys

/// Manages the keys used in message dictionaries, ensuring consistency and preventing typos.
struct MessageKeys {
    static let command = "command"
    static let data = "data"
}
