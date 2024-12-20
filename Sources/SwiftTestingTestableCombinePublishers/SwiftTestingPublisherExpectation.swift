//
//  SwiftTestingPublisherExpectation.swift
//  TestableCombinePublishers
//
//  Created by Ethan van Heerden on 11/14/24.
//

#if canImport(Testing)

import Foundation
import Testing
import Combine
import TestableCombinePublishersUtility

// MARK: - Swift Testing-Usable Publisher Extension

public extension Publisher {
    
    /// Creates an explicit `SwiftTestingPublisherExpectation` whose upstream publisher refers to this `Publisher`.
    /// This function is required to be called on a `Publisher` before any of the Swift Testing convenience testing functions can be used.
    /// This method is required to avoid compiler confusion, as both the Swift Testing and XCTest versions of this library have the same function names.
    /// - Returns: A chainable `SwiftTestingPublisherExpectation` that matches the contextual upstream `Publisher` type
    func testable() -> SwiftTestingPublisherExpectation<Self> {
        .init(upstreamPublisher: self)
    }
}

// MARK: - SwiftTestingPublisherExpectation

/// Provides a convenient way for `Publisher`s to be unit tested.
/// To use this, you can start by typing `expect` on any `Publisher` type.
/// `waitForExpectations` must be called to evaluate the expectations.
/// Multiple expectations are allowed for a single `Publisher`
public final class SwiftTestingPublisherExpectation<UpstreamPublisher: Publisher> {
    private let upstreamPublisher: UpstreamPublisher
    private var cancellables: Set<AnyCancellable> = []
    private var expectations: [SwiftTestingExpectation] = []
    
    init(upstreamPublisher: UpstreamPublisher) {
        self.upstreamPublisher = upstreamPublisher
    }
    
    /// Pauses execution of the current thread until all declared expectations are met, or until the timeout period has expired
    /// - Parameters:
    ///   - timeout: The amount of time that the current process will wait for the expectations to be met
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    public func waitForExpectations(timeout: TimeInterval, sourceLocation: SourceLocation = #_sourceLocation) async {
        defer {
            cancellables.forEach { $0.cancel() }
        }
        
        do {
            try await withTimeout(seconds: timeout) {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    for expectation in self.expectations {
                        group.addTask {
                            try await self.waitForExpectationToBeFulfilled(expectation)
                        }
                    }
                }
            } onTimeout: {
                // We need to recheck for fulfilled expectations on timeout since inverted expectations
                // need to wait for the entire timeout.
                for expectation in self.expectations {
                    if expectation.isInverted {
                        if expectation.isFulfilled {
                            throw ExpectationError.invertedExpectation(expectation: expectation)
                        }
                    } else {
                        // Expectation not inverted, check fulfillment
                        guard expectation.isFulfilled else {
                            throw ExpectationError.timedOut(timeout: timeout, expectation: expectation)
                        }
                    }
                }
            }
            
            // We should only get here if everything has been marked as fulfilled
            for expectation in expectations {
                if expectation.isInverted {
                    throw ExpectationError.invertedExpectation(expectation: expectation)
                }
            }
        } catch _ as TimeoutError {
            // Ignore this error as we handle this in the onTimeout closure
        } catch let error as ExpectationError {
            Issue.record(error.comment, sourceLocation: error.sourceLocation)
        } catch {
            Issue.record("Publisher expectations process was interrupted by: \(error.localizedDescription)", sourceLocation: sourceLocation)
        }
    }
}

// MARK: - Receive Value Expectations

public extension SwiftTestingPublisherExpectation {
    /// Asserts that the provided `Equatable` value will be emitted by the `Publisher` one or more times.
    /// - Parameters:
    ///   - expected: The `Equatable` value expected from the `Publisher`
    ///   - message: The message to attach to the `#expect` failure, if a mismatch is found
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `SwiftTestingPublisherExpectation` that matches the contextual upstream `Publisher` type
    func expect(_ expected: UpstreamPublisher.Output, message: String? = nil, sourceLocation: SourceLocation = #_sourceLocation) -> Self where UpstreamPublisher.Output: Equatable {
        let expectation = SwiftTestingExpectation(description: "expect(\(expected))",
                                                  sourceLocation: sourceLocation)
        expectations.append(expectation)
        
        upstreamPublisher
            .sink { completion in
            } receiveValue: { value in
                #expect(expected == value,
                        Self.buildFailureMessage(lhs: expected, rhs: value, message: message),
                        sourceLocation: sourceLocation)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        return self
    }
    
    /// Asserts that the provided `Equatable` value will be emitted by the `Publisher` exactly `count` times.
    /// ⚠️ This will wait for the full timeout.
    /// - Parameters:
    ///   - count: The exact number of values that should be emitted from the `Publisher`
    ///   - expected: The `Equatable` value expected from the `Publisher`
    ///   - message: The message to attach to the `#expect` failure, if a mismatch is found
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `SwiftTestingPublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectExactly(_ count: Int, of expected: UpstreamPublisher.Output, message: String? = nil, sourceLocation: SourceLocation = #_sourceLocation) -> Self where UpstreamPublisher.Output: Equatable {
        let minExpectation = SwiftTestingExpectation(description: "min expectExactly(\(count), of: \(expected))",
                                                     expectedFulfillmentCount: count,
                                                     sourceLocation: sourceLocation)
        
        let maxExpectation = SwiftTestingExpectation(description: "max expectExactly(\(count), of: \(expected))",
                                                     expectedFulfillmentCount: count + 1,
                                                     isInverted: true,
                                                     sourceLocation: sourceLocation)
        expectations.append(minExpectation)
        expectations.append(maxExpectation)
        
        upstreamPublisher
            .sink { completion in
            } receiveValue: { value in
                #expect(expected == value,
                        Self.buildFailureMessage(lhs: expected, rhs: value, message: message),
                        sourceLocation: sourceLocation)
                minExpectation.fulfill()
                maxExpectation.fulfill()
            }
            .store(in: &cancellables)
        return self
    }
    
    /// Asserts that a value will be emitted by the `Publisher` and that it does NOT match the provided `Equatable`.
    /// - Parameters:
    ///   - expected: The `Equatable` value NOT expected from the `Publisher`
    ///   - message: The message to attach to the `#expect`  failure, if a match is found
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `SwiftTestingPublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectNot(_ expected: UpstreamPublisher.Output, message: String? = nil, sourceLocation: SourceLocation = #_sourceLocation) -> Self where UpstreamPublisher.Output: Equatable {
        let expectation = SwiftTestingExpectation(description: "expectNot(\(expected))",
                                                  sourceLocation: sourceLocation)
        expectations.append(expectation)
        
        upstreamPublisher
            .sink { completion in
            } receiveValue: { value in
                #expect(expected != value,
                        Self.buildFailureMessage(lhs: expected, rhs: value, message: message),
                        sourceLocation: sourceLocation)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        return self
    }
    
    /// Asserts that no value will be emitted by the `Publisher`.
    /// ⚠️ This will wait for the full timeout.
    /// - Parameters:
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `SwiftTestingPublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectNoValue(sourceLocation: SourceLocation = #_sourceLocation) -> Self {
        let expectation = SwiftTestingExpectation(description: "expectNoValue()",
                                                  isInverted: true,
                                                  sourceLocation: sourceLocation)
        expectations.append(expectation)
        
        upstreamPublisher
            .sink { completion in
            } receiveValue: { value in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        return self
    }
    
    /// Invokes the provided assertion closure on every value emitted by the `Publisher`, expecting at least one `Output` value.
    /// Useful for calling `#expect` variants where custom evaluation is required.
    /// - Parameters:
    ///   - assertion: The assertion to be performed on each emitted value of the `Publisher`
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `SwiftTestingPublisherExpectation` that matches the contextual upstream `Publisher` type
    func expect(_ assertion: @escaping (UpstreamPublisher.Output) -> Void, sourceLocation: SourceLocation = #_sourceLocation) -> Self {
        let expectation = SwiftTestingExpectation(description: "expect(assertion:)",
                                                  sourceLocation: sourceLocation)
        expectations.append(expectation)
        
        upstreamPublisher
            .sink { completion in
            } receiveValue: { value in
                assertion(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        return self
    }
    
    /// Invokes the provided assertion closure on every value emitted by the `Publisher`, expecting exactly `count` values emitted.
    /// ⚠️ This will wait for the full timeout.
    /// Useful for calling `#expect` variants where custom evaluation is required
    /// - Parameters:
    ///   - count: The exact number of values that should be emitted from the `Publisher`
    ///   - assertion: The assertion to be performed on each emitted value of the `Publisher`
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `SwiftTestingPublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectExactly(_ count: Int, _ assertion: @escaping (UpstreamPublisher.Output) -> Void, sourceLocation: SourceLocation = #_sourceLocation) -> Self {
        let minExpectation = SwiftTestingExpectation(description: "min expectExactly(\(count) assertion)",
                                                     expectedFulfillmentCount: count,
                                                     sourceLocation: sourceLocation)
        
        let maxExpectation = SwiftTestingExpectation(description: "max expectExactly(\(count) assertion)",
                                                     expectedFulfillmentCount: count + 1,
                                                     isInverted: true,
                                                     sourceLocation: sourceLocation)
        expectations.append(minExpectation)
        expectations.append(maxExpectation)
        
        upstreamPublisher
            .sink { completion in
            } receiveValue: { value in
                assertion(value)
                minExpectation.fulfill()
                maxExpectation.fulfill()
            }
            .store(in: &cancellables)
        return self
    }
}

// MARK: - Receive Completion Expectations

public extension SwiftTestingPublisherExpectation {
    
    /// Asserts that the `Publisher` data stream completes, indifferent of the returned success/failure status (`Subscribers.Completion<Failure>`)
    /// - Parameters:
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `SwiftTestingPublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectCompletion(sourceLocation: SourceLocation = #_sourceLocation) -> Self {
        let expectation = SwiftTestingExpectation(description: "expectCompletion()",
                                                  sourceLocation: sourceLocation)
        expectations.append(expectation)
        
        upstreamPublisher
            .sink { completion in
                expectation.fulfill()
            } receiveValue: { value in }
            .store(in: &cancellables)
        return self
    }
    
    /// Asserts that the `Publisher` data stream does NOT complete.
    /// ⚠️ This will wait for the full timeout.
    /// - Parameters:
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `SwiftTestingPublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectNoCompletion(sourceLocation: SourceLocation = #_sourceLocation) -> Self {
        let expectation = SwiftTestingExpectation(description: "expectNoCompletion()",
                                                  isInverted: true,
                                                  sourceLocation: sourceLocation)
        expectations.append(expectation)
        
        upstreamPublisher
            .sink { completion in
                expectation.fulfill()
            } receiveValue: { value in }
            .store(in: &cancellables)
        return self
    }
    
    /// Invokes the provided assertion closure on the `receiveCompletion` handler of the `Publisher`
    /// Useful for calling `#expect` variants where custom evaluation is required
    /// - Parameters:
    ///   - assertion: The assertion to be performed on the success/fail result status (`Subscribers.Completion<Failure>`)
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `SwiftTestingPublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectCompletion(_ assertion: @escaping (Subscribers.Completion<UpstreamPublisher.Failure>) -> Void, sourceLocation: SourceLocation = #_sourceLocation) -> Self {
        let expectation = SwiftTestingExpectation(description: "expectCompletion(assertion:)",
                                                  sourceLocation: sourceLocation)
        expectations.append(expectation)
        
        upstreamPublisher
            .sink { completion in
                assertion(completion)
                expectation.fulfill()
            } receiveValue: { value in }
            .store(in: &cancellables)
        return self
    }
}

// MARK: - Receive Success Expectations

public extension SwiftTestingPublisherExpectation {
    
    /// Asserts that the `Publisher` data stream completes with a success status (`.finished`)
    /// - Parameters:
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `SwiftTestingPublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectSuccess(sourceLocation: SourceLocation = #_sourceLocation) -> Self {
        let expectation = SwiftTestingExpectation(description: "expectSuccess()",
                                                  sourceLocation: sourceLocation)
        expectations.append(expectation)
        
        upstreamPublisher
            .sink { completion in
                if case .finished = completion {
                    expectation.fulfill()
                }
            } receiveValue: { value in }
            .store(in: &cancellables)
        return self
    }
}

// MARK: - Receive Completion Failure Expectations

public extension SwiftTestingPublisherExpectation {
    
    /// Asserts that the `Publisher` data stream completes with a failure status (`.failure(Failure)`)
    /// - Parameters:
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `SwiftTestingPublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectFailure(sourceLocation: SourceLocation = #_sourceLocation) -> Self {
        let expectation = SwiftTestingExpectation(description: "expectFailure()",
                                                  sourceLocation: sourceLocation)
        expectations.append(expectation)
        
        upstreamPublisher
            .sink { completion in
                if case .failure = completion {
                    expectation.fulfill()
                }
            } receiveValue: { value in }
            .store(in: &cancellables)
        return self
    }
    
    /// Asserts that the provided `Equatable` `Failure` type is returned when the `Publisher` completes
    /// - Parameters:
    ///   - failure: The `Equatable` `Failure` type that should be returned when the `Publisher` completes
    ///   - message: The message to attach to the `#expect` failure, if a mismatch is found
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `SwiftTestingPublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectFailure(_ failure: UpstreamPublisher.Failure, message: String? = nil, sourceLocation: SourceLocation = #_sourceLocation) -> Self where UpstreamPublisher.Failure: Equatable {
        let expectation = SwiftTestingExpectation(description: "expectFailure(\(failure))",
                                                  sourceLocation: sourceLocation)
        expectations.append(expectation)
        
        upstreamPublisher
            .sink { completion in
                if case .failure(let error) = completion {
                    #expect(failure == error,
                            Self.buildFailureMessage(lhs: failure, rhs: error, message: message),
                            sourceLocation: sourceLocation)
                    expectation.fulfill()
                }
            } receiveValue: { value in }
            .store(in: &cancellables)
        return self
    }
    
    /// Asserts that the `Publisher` completes with a `Failure` type which does NOT match the provided `Equatable` `Failure`
    /// - Parameters:
    ///   - failure: The `Equatable` `Failure` type that should NOT be returned when the `Publisher` completes
    ///   - message: The message to attach to the `#expect` failure, if a mismatch is found
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `SwiftTestingPublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectNotFailure(_ failure: UpstreamPublisher.Failure, message: String? = nil, sourceLocation: SourceLocation = #_sourceLocation) -> Self where UpstreamPublisher.Failure: Equatable {
        let expectation = SwiftTestingExpectation(description: "expectNotFailure(\(failure))",
                                                  sourceLocation: sourceLocation)
        expectations.append(expectation)
        
        upstreamPublisher
            .sink { completion in
                if case .failure(let error) = completion {
                    #expect(failure != error,
                            Self.buildFailureMessage(lhs: failure, rhs: error, message: message),
                            sourceLocation: sourceLocation)
                    expectation.fulfill()
                }
            } receiveValue: { value in }
            .store(in: &cancellables)
        return self
    }
    
    /// Invokes the provided assertion closure on the `Failure` result's associated `Error` value  of the `Publisher`
    /// Useful for calling `#expect` variants where custom evaluation is required
    /// - Parameters:
    ///   - assertion: The assertion to be performed on the `Failure` result's associated `Error` value
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `SwiftTestingPublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectFailure(_ assertion: @escaping (UpstreamPublisher.Failure) -> Void, sourceLocation: SourceLocation = #_sourceLocation) -> Self {
        let expectation = SwiftTestingExpectation(description: "expectFailure(assertion:)",
                                                  sourceLocation: sourceLocation)
        expectations.append(expectation)
        
        upstreamPublisher
            .sink { completion in
                if case .failure(let error) = completion {
                    assertion(error)
                    expectation.fulfill()
                }
            } receiveValue: { value in }
            .store(in: &cancellables)
        return self
    }
}

// MARK: - Void Publisher Expectations

public extension SwiftTestingPublisherExpectation where UpstreamPublisher.Output == Void {
    
    /// Asserts that `Void` will be emitted by the `Publisher` one or more times
    /// - Parameters:
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `PublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectVoid(sourceLocation: SourceLocation = #_sourceLocation) -> Self {
        let expectation = SwiftTestingExpectation(description: "expectVoid()",
                                                  sourceLocation: sourceLocation)
        expectations.append(expectation)
        
        upstreamPublisher
            .sink { completion in
            } receiveValue: { value in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        return self
    }
}

// MARK: - Private

private extension SwiftTestingPublisherExpectation {
    
    /// Waits for the given `SwiftTestingExpectation` to be marked as fulfilled.
    /// - Parameter expectation: The `SwiftTestingExpectation` to wait fulfillment for
    func waitForExpectationToBeFulfilled(_ expectation: SwiftTestingExpectation) async throws {
        while !expectation.isFulfilled {
            // Wait for 0.1 seconds
            try await Task.sleep(nanoseconds: 100_000_000)
        }
    }
    
    /// Creates a Swift Testing `Comment` used for displaying useful test failure messages in the Xcode console.
    /// - Parameters:
    ///   - lhs: The left-hand side value that a comparison was done with
    ///   - rhs: The right-hand side value that a comparison was done with
    ///   - message: An optional description to add to the `Comment`
    /// - Returns: The Swift Testing Comment describing a test
    static func buildFailureMessage<T: Equatable>(lhs: T, rhs: T, message: String?) -> Comment {
        let failureMessage = [
            message,
            RecursiveComparator.compare(lhs: lhs, rhs: rhs).debugDescription
        ]
            .compactMap({ $0 })
            .joined(separator: " - ")
        
        return Comment(rawValue: failureMessage)
    }
}

// MARK: - ExpectationError

enum ExpectationError: Error {
    case invertedExpectation(expectation: SwiftTestingExpectation)
    case timedOut(timeout: TimeInterval, expectation: SwiftTestingExpectation)
    
    var comment: Comment {
        switch self {
            case .invertedExpectation(let expectation):
                return "Inverted publisher expectation failed: \(expectation.description)"
            case let .timedOut(timeout, expectation):
                let timeoutPlural = timeout == 1 ? "" : "s"
                return "Publisher expectation timed out after \(String(format: "%g", timeout)) second\(timeoutPlural): \(expectation.description)"
        }
    }
    
    var sourceLocation: SourceLocation {
        switch self {
            case .invertedExpectation(let expectation),
                    .timedOut(_, let expectation):
                return expectation.sourceLocation
        }
    }
}

#endif
