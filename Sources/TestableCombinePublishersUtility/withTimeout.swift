//
//  withTimeout.swift
//  TestableCombinePublishers
//
//  Created by Albert Bori on 11/15/24.
//

import Foundation

/// Invokes the block of code. If the timeout period is surpassed before the block of code is complete, a ``TimeoutError`` is thrown.
/// Note: This does not cancel the current Task if a timeout occurs.
/// - Parameters:
///   - seconds: The number of seconds that must pass before the task is cancelled.
///   - operation: The block of code to execute before the timeout. Note that this block requires cooperative cancellation. (Proactive checking for cancellation)
///   - onTimeout: An optional closure to be fired just before the timeout error is thrown back to callers. Use this to help with cooperative cancellation, if needed. For example, if you're storing async continuations, you can use this to complete them.
/// - Throws: ``TimeoutError`` if the timeout period is expired, ``NoTimeoutTaskResultError`` if something prevents the timeout functionality from working properly, or ``InvalidTimeoutError`` if the provided timeout interval is not greater than zero.
/// - Returns: The block's result, if not ``Void``
public func withTimeout<OperationResult>(
    seconds: TimeInterval,
    operation: @escaping @Sendable () async throws -> OperationResult,
    onTimeout: @escaping @Sendable () async throws -> Void = { }
) async throws -> OperationResult {
    return try await withThrowingTaskGroup(of: OperationResult.self) { group in
        // Start actual work.
        group.addTask {
            try await operation()
        }
        // Start timeout child task.
        group.addTask {
            guard seconds > 0 else { throw InvalidTimeoutError() }
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            try Task.checkCancellation()
            // We’ve reached the timeout.
            throw TimeoutError()
        }
        // First finished child task wins, cancel the other task.
        do {
            guard let result = try await group.next() else {
                throw NoTimeoutTaskResultError()
            }
            group.cancelAll() // Cancels timeout task
            return result
        } catch let error as TimeoutError {
            try await onTimeout()
            throw error // Automatically cancels all group tasks
        }
    }
}

/// Thrown when ``withTimeout(seconds:operation:)`` reaches its limit without completing the code in the block
public struct TimeoutError: Error { }

/// Thrown when ``withTimeout(seconds:operation:)`` is called and the result of the main code block fails to return a result or throw an error.
public struct NoTimeoutTaskResultError: Error { }

/// Thrown when the provided  timeout value is not in the future.
public struct InvalidTimeoutError: Error { }
