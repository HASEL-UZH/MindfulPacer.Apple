//
//  Optional+Extensions.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 13.08.2024.
//

import Foundation

extension Optional {
    /// Returns `true` if the optional has no value, otherwise `false`.
    @inlinable
    var isNil: Bool {
        switch self {
        case .none: return true
        case .some: return false
        }
    }

    /// Returns `true` if the optional wraps a value, otherwise `false`.
    @inlinable
    var isNotNil: Bool { !isNil }

    /// Evaluates the first closure when this Optional instance is not nil, passing the unwrapped value as a parameter,
    /// or the second when the instance is nil.
    func ifLet<U>(then onSome: (Wrapped) throws -> U, else onNone: () throws -> U) rethrows -> U {
        switch self {
        case let .some(value):
            return try onSome(value)
        case .none:
            return try onNone()
        }
    }

    /// Evaluates the first async closure when this Optional instance is not nil, passing the unwrapped value as a parameter,
    /// or the second when the instance is nil.
    func ifAsyncLet<U>(then onSome: (Wrapped) async throws -> U, else onNone: () async throws -> U) async rethrows -> U {
        switch self {
        case let .some(value):
            return try await onSome(value)
        case .none:
            return try await onNone()
        }
    }

    /// Execute some code when the Optional instance has _any_ wrapped value.
    @discardableResult
    func whenSome(_ block: (Wrapped) -> ()) -> Wrapped? {
        _ = map(block)
        return self
    }

    /// Execute some code when the Optional instance does not contain any wrapped value.
    @discardableResult
    func whenNone(_ block: () -> ()) -> Wrapped? {
        if case .none = self {
            block()
        }

        return self
    }
}

extension Optional where Wrapped: Collection {
    /// Returns a Boolean value indicating whether the collection has no value or is empty.
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }
}
