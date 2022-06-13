//
//  PublisherExpectation.swift
//  TestableCombinePublishers
//
//  Copyright (c) 2022 Albert Bori
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Combine
import Foundation
import XCTest

/// Provides a convenient way for `Publisher`s to be unit tested.
/// To use this, you can start by typing `expect` on any `Publisher` type.
/// `waitForExpectations` must be called to evaluate the expectations.
/// Multiple expectations are allowed for a single `Publisher`
public final class PublisherExpectation<UpstreamPublisher: Publisher> {
    private let upstreamPublisher: UpstreamPublisher
    private var cancellables: Set<AnyCancellable> = []
    private var expectations: [XCTestExpectation] = []
    private let delegate: WaiterDelegate = WaiterDelegate()
    
    public init(upstream: UpstreamPublisher) {
        self.upstreamPublisher = upstream
    }
        
    /// Pauses execution of the current thread until all declared expectations are met, or until the timeout period has expired
    /// - Parameters:
    ///   - timeout: The amount of time that the current process will wait for the expectations to be met
    ///   - enforceOrder: (Not currently working) Asserts that the expectations will be fulfilled in order of declaration or a failure will be emitted
    ///   - file: The calling file. Used for showing context-appropriate unit test failures in Xcode
    ///   - line: The calling line of code. Used for showing context-appropriate unit test failures in Xcode
    public func waitForExpectations(timeout: TimeInterval, enforceOrder: Bool = true, file: StaticString = #filePath, line: UInt = #line) {
        let result = XCTWaiter(delegate: delegate).wait(for: expectations, timeout: timeout, enforceOrder: enforceOrder)
        switch result {
        case .completed:
            break
        case .timedOut:
            let timeoutPlural = timeout == 1 ? "" : "s"
            delegate.unfulfilledExpectations
                .forEach({ expectation in
                    let expectation = expectation.asLocatableTestExpectation(file: file, line: line)
                    XCTFail("Publisher expectation timed out after \(String(format: "%g", timeout)) second\(timeoutPlural): \(expectation.description)", file: expectation.file, line: expectation.line)
                })
        case .incorrectOrder:
            delegate.misorderedExpectations
                .forEach({ expectation in
                    let expectation = expectation.asLocatableTestExpectation(file: file, line: line)
                    XCTFail("Publisher expectation executed in the wrong order: \(expectation.description)", file: expectation.file, line: expectation.line)
                })
        case .invertedFulfillment:
            delegate.invertedExpectations
                .forEach({ expectation in
                    let expectation = expectation.asLocatableTestExpectation(file: file, line: line)
                    XCTFail("Publisher expectation were fulfilled inverted: \(expectation.description)", file: expectation.file, line: expectation.line)
                })
        case .interrupted:
            XCTFail("Publisher expectations process was interrupted by: \(delegate.interruptingWaiter?.description ?? "unknown")", file: file, line: line)
        @unknown default:
            break
        }
        cancellables.forEach({ $0.cancel() })
    }
}

// MARK: - Receive Value Expectations

public extension PublisherExpectation {
    
    /// Asserts that the provided `Equatable` value will be emitted by the `Publisher`
    /// - Parameters:
    ///   - expected: The `Equatable` value expected from the `Publisher`
    ///   - message: The message to attach to the `XCTAssertEqual` failure, if a mismatch is found
    ///   - file: The calling file. Used for showing context-appropriate unit test failures in Xcode
    ///   - line: The calling line of code. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `PublisherExpectation` that matches the contextual upstream `Publisher` type
    func expect(_ expected: UpstreamPublisher.Output, message: String? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self where UpstreamPublisher.Output: Equatable {
        let expectation = LocatableTestExpectation(description: "expect(\(expected))", file: file, line: line)
        expectations.append(expectation)
        upstreamPublisher
            .sink { completion in
            } receiveValue: { value in
                XCTAssertEqual(expected, value, message ?? "", file: file, line: line)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        return self
    }
    
    /// Invokes the provided assertion closure on every value emitted by the `Publisher`.
    /// Useful for calling `XCTAssert` variants where custom evaluation is required
    /// - Parameters:
    ///   - assertion: The assertion to be performed on each emitted value of the `Publisher`
    ///   - file: The calling file. Used for showing context-appropriate unit test failures in Xcode
    ///   - line: The calling line of code. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `PublisherExpectation` that matches the contextual upstream `Publisher` type
    func expect(_ assertion: @escaping (UpstreamPublisher.Output) -> Void, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let expectation = LocatableTestExpectation(description: "expect(assertion:)", file: file, line: line)
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
}

public extension Publisher {
    
    /// Asserts that the provided value will be emitted by the `Publisher`
    /// - Parameters:
    ///   - expected: The `Equatable` value expected from the `Publisher`
    ///   - message: The message to attach to the `XCTAssertEqual` failure, if a mismatch is found
    ///   - file: The calling file. Used for showing context-appropriate unit test failures in Xcode
    ///   - line: The calling line of code. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `PublisherExpectation` that matches the contextual upstream `Publisher` type
    func expect(_ expected: Output, message: String? = nil, file: StaticString = #filePath, line: UInt = #line) -> PublisherExpectation<Self> where Output: Equatable {
        .init(upstream: self).expect(expected, message: message, file: file, line: line)
    }
    
    /// Invokes the provided assertion closure on every value emitted by the `Publisher`.
    /// Useful for calling `XCTAssert` variants where custom evaluation is required
    /// - Parameters:
    ///   - assertion: The assertion to be performed on each emitted value of the `Publisher`
    ///   - file: The calling file. Used for showing context-appropriate unit test failures in Xcode
    ///   - line: The calling line of code. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `PublisherExpectation` that matches the contextual upstream `Publisher` type
    func expect(_ assertion: @escaping (Output) -> Void, file: StaticString = #filePath, line: UInt = #line) -> PublisherExpectation<Self> {
        .init(upstream: self).expect(assertion, file: file, line: line)
    }
}

// MARK: - Receive Completion Expectations

public extension PublisherExpectation {
    
    /// Asserts that the `Publisher` data stream completes, indifferent of the returned success/failure status (`Subscribers.Completion<Failure>`)
    /// - Parameters:
    ///   - file: The calling file. Used for showing context-appropriate unit test failures in Xcode
    ///   - line: The calling line of code. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `PublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectCompletion(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let expectation = LocatableTestExpectation(description: "expectCompletion()", file: file, line: line)
        expectations.append(expectation)
        upstreamPublisher
            .sink { completion in
                expectation.fulfill()
            } receiveValue: { value in }
            .store(in: &cancellables)
        return self
    }
    
    /// Invokes the provided assertion closure on the `recieveCompletion` handler of the `Publisher`
    /// Useful for calling `XCTAssert` variants where custom evaluation is required
    /// - Parameters:
    ///   - assertion: The assertion to be performed on the success/fail result status (`Subscribers.Completion<Failure>`)
    ///   - file: The calling file. Used for showing context-appropriate unit test failures in Xcode
    ///   - line: The calling line of code. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `PublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectCompletion(_ assertion: @escaping (Subscribers.Completion<UpstreamPublisher.Failure>) -> Void, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let expectation = LocatableTestExpectation(description: "expectCompletion(assertion:)", file: file, line: line)
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

public extension Publisher {
    
    /// Asserts that the `Publisher` data stream completes, indifferent of the returned success/failure status (`Subscribers.Completion<Failure>`)
    /// - Parameters:
    ///   - file: The calling file. Used for showing context-appropriate unit test failures in Xcode
    ///   - line: The calling line of code. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `PublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectCompletion(file: StaticString = #filePath, line: UInt = #line) -> PublisherExpectation<Self> {
        .init(upstream: self).expectCompletion(file: file, line: line)
    }
    
    /// Invokes the provided assertion closure on the `recieveCompletion` handler of the `Publisher`
    /// Useful for calling `XCTAssert` variants where custom evaluation is required
    /// - Parameters:
    ///   - assertion: The assertion to be performed on the success/fail result status (`Subscribers.Completion<Failure>`)
    ///   - file: The calling file. Used for showing context-appropriate unit test failures in Xcode
    ///   - line: The calling line of code. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `PublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectCompletion(_ assertion: @escaping (Subscribers.Completion<Failure>) -> Void, file: StaticString = #filePath, line: UInt = #line) -> PublisherExpectation<Self> {
        .init(upstream: self).expectCompletion(assertion, file: file, line: line)
    }
}

// MARK: - Receive Success Expectations

public extension PublisherExpectation {
    
    /// Asserts that the `Publisher` data stream completes with a success status (`.finished`)
    /// - Parameters:
    ///   - file: The calling file. Used for showing context-appropriate unit test failures in Xcode
    ///   - line: The calling line of code. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `PublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectSuccess(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let expectation = LocatableTestExpectation(description: "expectSuccess()", file: file, line: line)
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

public extension Publisher {
    
    /// Asserts that the `Publisher` data stream completes with a success status (`.finished`)
    /// - Parameters:
    ///   - file: The calling file. Used for showing context-appropriate unit test failures in Xcode
    ///   - line: The calling line of code. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `PublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectSuccess(file: StaticString = #filePath, line: UInt = #line) -> PublisherExpectation<Self> {
        .init(upstream: self).expectSuccess(file: file, line: line)
    }
}

// MARK: - Receive Completion Error Expectations

public extension PublisherExpectation {
    
    /// Asserts that the `Publisher` data stream completes with a failure status (`.failure(Failure)`)
    /// - Parameters:
    ///   - file: The calling file. Used for showing context-appropriate unit test failures in Xcode
    ///   - line: The calling line of code. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `PublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectFailure(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let expectation = LocatableTestExpectation(description: "expectFailure()", file: file, line: line)
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
    ///   - message: The message to attach to the `XCTAssertEqual` failure, if a mismatch is found
    ///   - file: The calling file. Used for showing context-appropriate unit test failures in Xcode
    ///   - line: The calling line of code. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `PublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectFailure(_ failure: UpstreamPublisher.Failure, message: String? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self where UpstreamPublisher.Failure: Equatable {
        let expectation = LocatableTestExpectation(description: "expectFailure(\(failure))", file: file, line: line)
        expectations.append(expectation)
        upstreamPublisher
            .sink { completion in
                if case .failure(let error) = completion {
                    XCTAssertEqual(failure, error, message ?? "", file: file, line: line)
                    expectation.fulfill()
                }
            } receiveValue: { value in }
            .store(in: &cancellables)
        return self
    }
    
    /// Invokes the provided assertion closure on the `Failure` result's associated `Error` value  of the `Publisher`
    /// Useful for calling `XCTAssert` variants where custom evaluation is required
    /// - Parameters:
    ///   - assertion: The assertion to be performed on the `Failure` result's associated `Error` value
    ///   - file: The calling file. Used for showing context-appropriate unit test failures in Xcode
    ///   - line: The calling line of code. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `PublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectFailure(_ assertion: @escaping (UpstreamPublisher.Failure) -> Void, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let expectation = LocatableTestExpectation(description: "expectFailure(assertion:)", file: file, line: line)
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

public extension Publisher {
    
    /// Asserts that the `Publisher` data stream completes with a failure status (`.failure(Failure)`)
    /// - Parameters:
    ///   - file: The calling file. Used for showing context-appropriate unit test failures in Xcode
    ///   - line: The calling line of code. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `PublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectFailure(file: StaticString = #filePath, line: UInt = #line) -> PublisherExpectation<Self> {
        .init(upstream: self).expectFailure(file: file, line: line)
    }
    
    /// Asserts that the provided `Equatable` `Failure` type is returned when the `Publisher` completes
    /// - Parameters:
    ///   - failure: The `Equatable` `Failure` type that should be returned when the `Publisher` completes
    ///   - message: The message to attach to the `XCTAssertEqual` failure, if a mismatch is found
    ///   - file: The calling file. Used for showing context-appropriate unit test failures in Xcode
    ///   - line: The calling line of code. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `PublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectFailure(_ failure: Failure, message: String? = nil, file: StaticString = #filePath, line: UInt = #line) -> PublisherExpectation<Self> where Failure: Equatable {
        .init(upstream: self).expectFailure(failure, message: message, file: file, line: line)
    }
    
    /// Invokes the provided assertion closure on the `Failure` result's associated `Error` value  of the `Publisher`
    /// Useful for calling `XCTAssert` variants where custom evaluation is required
    /// - Parameters:
    ///   - assertion: The assertion to be performed on the `Failure` result's associated `Error` value
    ///   - file: The calling file. Used for showing context-appropriate unit test failures in Xcode
    ///   - line: The calling line of code. Used for showing context-appropriate unit test failures in Xcode
    /// - Returns: A chainable `PublisherExpectation` that matches the contextual upstream `Publisher` type
    func expectFailure(_ assertion: @escaping (Failure) -> Void, file: StaticString = #filePath, line: UInt = #line) -> PublisherExpectation<Self> {
        .init(upstream: self).expectFailure(assertion, file: file, line: line)
    }
}

// MARK: - WaiterDelegate

extension PublisherExpectation {
    /// Gathers failure information for helpful XCTest error descriptions.
    final class WaiterDelegate: NSObject, XCTWaiterDelegate {
        private(set) var unfulfilledExpectations: [XCTestExpectation] = []
        private(set) var misorderedExpectations: [XCTestExpectation] = []
        private(set) var invertedExpectations: [XCTestExpectation] = []
        private(set) var interruptingWaiter: XCTWaiter?
        
        var failedExpectations: [XCTestExpectation] {
            unfulfilledExpectations + misorderedExpectations + invertedExpectations
        }
        
        var failedExpectationsDescription: String {
            "\"" + failedExpectations.map({ $0.description }).joined(separator: "\", \"") + "\""
        }
        
        public func waiter(_ waiter: XCTWaiter, didTimeoutWithUnfulfilledExpectations unfulfilledExpectations: [XCTestExpectation]) {
            self.unfulfilledExpectations = unfulfilledExpectations
        }
        
        public func waiter(_ waiter: XCTWaiter, fulfillmentDidViolateOrderingConstraintsFor expectation: XCTestExpectation, requiredExpectation: XCTestExpectation) {
            misorderedExpectations.append(expectation)
        }
        
        public func waiter(_ waiter: XCTWaiter, didFulfillInvertedExpectation expectation: XCTestExpectation) {
            invertedExpectations.append(expectation)
        }
        
        public func nestedWaiter(_ waiter: XCTWaiter, wasInterruptedByTimedOutWaiter outerWaiter: XCTWaiter) {
            interruptingWaiter = outerWaiter
        }
    }
}

// MARK: - LocatableTestExpectation

/// Used by `PublisherExpectation` to emit contextual Xcode unit test errors (showing the errors at the location of the expectation call within the unit test)
final class LocatableTestExpectation: XCTestExpectation {
    /// The unit test file where the expectation was declared
    let file: StaticString
    /// The line of the unit test file where the expectation was declared
    let line: UInt
    
    init(description: String, file: StaticString, line: UInt) {
        self.file = file
        self.line = line
        super.init(description: description)
    }
}

extension XCTestExpectation {
    /// For display purposes only.
    /// Attempts to unbox or create a new `LocatableTestExpectation` instance with the provided file and line information    
    func asLocatableTestExpectation(file: StaticString, line: UInt) -> LocatableTestExpectation {
        (self as? LocatableTestExpectation) ?? .init(description: description, file: file, line: line)
    }
}
