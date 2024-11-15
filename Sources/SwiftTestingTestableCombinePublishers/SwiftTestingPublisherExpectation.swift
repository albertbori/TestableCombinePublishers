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

/// Provides a convenient way for `Publisher`s to be unit tested.
/// To use this, you can start by typing `expect` on any `Publisher` type.
/// `waitForExpectations` must be called to evaluate the expectations.
/// Multiple expectations are allowed for a single `Publisher`
public final class SwiftTestingPublisherExpectation<UpstreamPublisher: Publisher> {
    private let upstreamPublisher: UpstreamPublisher
    private var cancellables: Set<AnyCancellable> = []
    private var expectations: [SwiftTestingExpectation] = []
    private var fullfilledExpectations: [UUID] = []
    
    init(upstreamPublisher: UpstreamPublisher) {
        self.upstreamPublisher = upstreamPublisher
    }
    
    /// Pauses execution of the current thread until all declared expectations are met, or until the timeout period has expired
    /// - Parameters:
    ///   - timeout: The amount of time that the current process will wait for the expectations to be met
    ///   - enforceOrder: Asserts that the expectations will be fulfilled in order of declaration or a failure will be emitted
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    public func waitForExpectations(timeout: TimeInterval,
                                    sourceLocation: SourceLocation = #_sourceLocation,
                                    enforceOrder: Bool = false) async {
        defer {
            cancellables.forEach { $0.cancel() }
        }
        
        do {
            try await withTimeout(seconds: timeout) { [weak self] in
                guard let strongSelf = self else { throw SelfReferenceError.deallocated }
                
                try await withThrowingTaskGroup(of: SwiftTestingExpectation.self) { group in
                    
                    for expectation in strongSelf.expectations {
                        group.addTask {
                            try await strongSelf.waitForExpectationToBeFulfilled(expectation)
                        }
                        
                        for try await fulfilledExpectation in group {
                            // Check if fulfilled in the correct order
                            strongSelf.fullfilledExpectations.append(fulfilledExpectation.id)
                        }
                    }
                }
                
            } onTimeout: { [weak self] in
                // For checking inverted expectations, we need to wait for the entire timeout first
                guard let strongSelf = self else { throw SelfReferenceError.deallocated }
                
                // Check that all non-inverted expectations are fulfilled, and inverted ones are not
                for expectation in strongSelf.expectations {
                    if expectation.isInverted {
                        if expectation.isFulfilled {
                            throw ExpectationError.invertedExpectation(expectation: expectation)
                        }
                    } else {
                        // Expectation not inverted, check fulfillment
                        guard expectation.isFulfilled else {
                            throw ExpectationError.timedOut(timeout: timeout, expectation: expectation)
                        }
                        
                        if enforceOrder {
                            guard expectation.id == strongSelf.fullfilledExpectations.removeFirst() else {
                                throw ExpectationError.incorrectOrder(expectation: expectation)
                            }
                        }
                    }
                }
            }
            
            // We should only get here if everything has been marked as fulfilled
            for (expectationIndex, expectation) in expectations.enumerated() {
                if expectation.isInverted {
                    throw ExpectationError.invertedExpectation(expectation: expectation)
                }
                
                if enforceOrder {
                    guard fullfilledExpectations[expectationIndex] == expectation.id else {
                        throw ExpectationError.incorrectOrder(expectation: expectation)
                    }
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
        let expectation = SwiftTestingExpectation(description: "expect(\(expected)", sourceLocation: sourceLocation)
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
    func expectNoValue(file: StaticString = #filePath, sourceLocation: SourceLocation = #_sourceLocation) -> Self {
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
    /// Useful for calling `XCTAssert` variants where custom evaluation is required
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

// MARK: - Publisher Extension for Recieve Value Expectations

public extension Publisher {
    /// Asserts that the provided value will be emitted by the `Publisher`
    /// - Parameters:
    ///   - expected: The `Equatable` value expected from the `Publisher`
    ///   - message: The message to attach to the `#expect` failure, if a mismatch is found
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `SwiftTestingPublisherExpectation` that matches the contextual upstream `Publisher` type
    func expect(_ expected: Output, message: String? = nil, sourceLocation: SourceLocation = #_sourceLocation) -> SwiftTestingPublisherExpectation<Self> where Output: Equatable {
        .init(upstreamPublisher: self).expect(expected, message: message, sourceLocation: sourceLocation)
    }
    
    /// Asserts that the provided `Equatable` value will be emitted by the `Publisher` exactly `count` times.
    /// ⚠️ This will wait for the full timeout.
    /// - Parameters:
    ///   - count: The exact number of values that should be emitted from the `Publisher`
    ///   - expected: The `Equatable` value expected from the `Publisher`
    ///   - message: The message to attach to the `#expect` failure, if a mismatch is found
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `SwiftTestingPublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectExactly(_ count: Int, of expected: Output, message: String? = nil, sourceLocation: SourceLocation = #_sourceLocation) -> SwiftTestingPublisherExpectation<Self> where Output: Equatable {
        .init(upstreamPublisher: self).expectExactly(count, of: expected, message: message, sourceLocation: sourceLocation)
    }
    
    /// Asserts that a value will be emitted by the `Publisher` and that it does NOT match the provided `Equatable`
    /// - Parameters:
    ///   - expected: The `Equatable` value NOT expected from the `Publisher`
    ///   - message: The message to attach to the `#expect` failure, if a match is found
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `SwiftTestingPublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectNot(_ expected: Output, message: String? = nil, sourceLocation: SourceLocation = #_sourceLocation) -> SwiftTestingPublisherExpectation<Self> where Output: Equatable {
        .init(upstreamPublisher: self).expectNot(expected, message: message, sourceLocation: sourceLocation)
    }
    
    /// Asserts that no value will be emitted by the `Publisher`.
    /// ⚠️ This will wait for the full timeout.
    /// - Parameters:
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `SwiftTestingPublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectNoValue(sourceLocation: SourceLocation = #_sourceLocation) -> SwiftTestingPublisherExpectation<Self> {
        .init(upstreamPublisher: self).expectNoValue(sourceLocation: sourceLocation)
    }
    
    /// Invokes the provided assertion closure on every value emitted by the `Publisher`.
    /// Useful for calling `#expect` variants where custom evaluation is required
    /// - Parameters:
    ///   - assertion: The assertion to be performed on each emitted value of the `Publisher`
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `SwiftTestingPublisherExpectation` that matches the contextual upstream `Publisher` type
    func expect(_ assertion: @escaping (Output) -> Void, sourceLocation: SourceLocation = #_sourceLocation) -> SwiftTestingPublisherExpectation<Self> {
        .init(upstreamPublisher: self).expect(assertion, sourceLocation: sourceLocation)
    }
    
    /// Invokes the provided assertion closure on every value emitted by the `Publisher`, expecting exactly `count` values emitted.
    /// ⚠️ This will wait for the full timeout.
    /// Useful for calling `#expect` variants where custom evaluation is required
    /// - Parameters:
    ///   - count: The exact number of values that should be emitted from the `Publisher`
    ///   - assertion: The assertion to be performed on each emitted value of the `Publisher`
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `SwiftTestingPublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectExactly(_ count: Int, _ assertion: @escaping (Output) -> Void, sourceLocation: SourceLocation = #_sourceLocation) -> SwiftTestingPublisherExpectation<Self> {
        .init(upstreamPublisher: self).expectExactly(count, assertion, sourceLocation: sourceLocation)
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
    
    /// Invokes the provided assertion closure on the `recieveCompletion` handler of the `Publisher`
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

// MARK: - Publisher Extension for Receive Completion Expectations

public extension Publisher {
    
    /// Asserts that the `Publisher` data stream completes, indifferent of the returned success/failure status (`Subscribers.Completion<Failure>`)
    /// - Parameters:
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `SwiftTestingPublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectCompletion(sourceLocation: SourceLocation = #_sourceLocation) -> SwiftTestingPublisherExpectation<Self> {
        .init(upstreamPublisher: self).expectCompletion(sourceLocation: sourceLocation)
    }
    
    /// Asserts that the `Publisher` data stream does NOT complete.
    /// ⚠️ This will wait for the full timeout.
    /// - Parameters:
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `SwiftTestingPublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectNoCompletion(sourceLocation: SourceLocation = #_sourceLocation) -> SwiftTestingPublisherExpectation<Self> {
        .init(upstreamPublisher: self).expectNoCompletion(sourceLocation: sourceLocation)
    }
    
    /// Invokes the provided assertion closure on the `recieveCompletion` handler of the `Publisher`
    /// Useful for calling `#expect` variants where custom evaluation is required
    /// - Parameters:
    ///   - assertion: The assertion to be performed on the success/fail result status (`Subscribers.Completion<Failure>`)
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `SwiftTestingPublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectCompletion(_ assertion: @escaping (Subscribers.Completion<Failure>) -> Void, sourceLocation: SourceLocation = #_sourceLocation) -> SwiftTestingPublisherExpectation<Self> {
        .init(upstreamPublisher: self).expectCompletion(assertion, sourceLocation: sourceLocation)
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

// MARK: - Publisher Extension for Receive Success Expectations

public extension Publisher {
    
    /// Asserts that the `Publisher` data stream completes with a success status (`.finished`)
    /// - Parameters:
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `PublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectSuccess(sourceLocation: SourceLocation = #_sourceLocation) -> SwiftTestingPublisherExpectation<Self> {
        .init(upstreamPublisher: self).expectSuccess(sourceLocation: sourceLocation)
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

// MARK: - Publisher Extension for Receive Completion Failure Expectations

public extension Publisher {
    
    /// Asserts that the `Publisher` data stream completes with a failure status (`.failure(Failure)`)
    /// - Parameters:
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `SwiftTestingPublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectFailure(sourceLocation: SourceLocation = #_sourceLocation) -> SwiftTestingPublisherExpectation<Self> {
        .init(upstreamPublisher: self).expectFailure(sourceLocation: sourceLocation)
    }
    
    /// Asserts that the provided `Equatable` `Failure` type is returned when the `Publisher` completes
    /// - Parameters:
    ///   - failure: The `Equatable` `Failure` type that should be returned when the `Publisher` completes
    ///   - message: The message to attach to the `#expect` failure, if a mismatch is found
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `SwiftTestingPublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectFailure(_ failure: Failure, message: String? = nil, sourceLocation: SourceLocation = #_sourceLocation) -> SwiftTestingPublisherExpectation<Self> where Failure: Equatable {
        .init(upstreamPublisher: self).expectFailure(failure, message: message, sourceLocation: sourceLocation)
    }
    
    /// Asserts that the `Publisher` completes with a `Failure` type which does NOT match the provided `Equatable` `Failure`
    /// - Parameters:
    ///   - failure: The `Equatable` `Failure` type that should be returned when the `Publisher` completes
    ///   - message: The message to attach to the `#expect` failure, if a mismatch is found
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `SwiftTestingPublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectNotFailure(_ failure: Failure, message: String? = nil, sourceLocation: SourceLocation = #_sourceLocation) -> SwiftTestingPublisherExpectation<Self> where Failure: Equatable {
        .init(upstreamPublisher: self).expectNotFailure(failure, message: message, sourceLocation: sourceLocation)
    }
    
    /// Invokes the provided assertion closure on the `Failure` result's associated `Error` value  of the `Publisher`
    /// Useful for calling `#expect` variants where custom evaluation is required
    /// - Parameters:
    ///   - assertion: The assertion to be performed on the `Failure` result's associated `Error` value
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `SwiftTestingPublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectFailure(_ assertion: @escaping (Failure) -> Void, sourceLocation: SourceLocation = #_sourceLocation) -> SwiftTestingPublisherExpectation<Self> {
        .init(upstreamPublisher: self).expectFailure(assertion, sourceLocation: sourceLocation)
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

// MARK: - Publisher Extension for Void Publisher Expectations
public extension Publisher where Output == Void {
    
    /// Asserts that `Void` will be emitted by the `Publisher` one or more times
    /// - Parameters:
    ///   - sourceLocation: The calling source. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `SwiftTestingPublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectVoid(sourceLocation: SourceLocation = #_sourceLocation) -> SwiftTestingPublisherExpectation<Self> {
        .init(upstreamPublisher: self).expectVoid(sourceLocation: sourceLocation)
    }
}

// MARK: - Private

private extension SwiftTestingPublisherExpectation {
    func waitForExpectationToBeFulfilled(_ expectation: SwiftTestingExpectation) async throws -> SwiftTestingExpectation {
        while !expectation.isFulfilled {
            // Wait for 0.1 seconds
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        
        return expectation
    }
    
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
    case incorrectOrder(expectation: SwiftTestingExpectation)
    case invertedExpectation(expectation: SwiftTestingExpectation)
    case timedOut(timeout: TimeInterval, expectation: SwiftTestingExpectation)
    
    var comment: Comment {
        switch self {
            case .incorrectOrder(let expectation):
                return "Publisher expectation executed in the wrong order: \(expectation.description)"
            case .invertedExpectation(let expectation):
                return "Inverted publisher expectation failed: \(expectation.description)"
            case let .timedOut(timeout, expectation):
                let timeoutPlural = timeout == 1 ? "" : "s"
                return "Publisher expectation timed out after \(String(format: "%g", timeout)) second\(timeoutPlural): \(expectation.description)"
        }
    }
    
    var sourceLocation: SourceLocation {
        switch self {
            case .incorrectOrder(let expectation),
                    .invertedExpectation(let expectation),
                    .timedOut(_, let expectation):
                return expectation.sourceLocation
        }
    }
}

// MARK: SelfReferenceError

enum SelfReferenceError: Error {
    case deallocated
}

#endif
