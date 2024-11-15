//
//  SwiftTestingTestableCombinePublishersTests.swift
//  TestableCombinePublishers
//
//  Created by Ethan van Heerden on 11/15/24.
//

import Testing
import Combine
import Foundation
@testable import SwiftTestingTestableCombinePublishers

final class SwiftTestingTestableCombinePublishersTests {
    
    // MARK: - Receive Value Expectations
    
    @Test func testExpectEquatableValue() async {
        await ["cool"]
            .publisher
            .expect("cool")
            .waitForExpectations(timeout: 1)
        
        // TODO: I had to add .collect() logic here
        await ["cool", "cool", "cool"]
            .publisher
            .collect(3)
            .expect(["cool", "cool", "cool"])
        //            .expect("cool")
            .waitForExpectations(timeout: 1)
    }
    
    @Test func testExpectEquatableValueFail() async {
        
        await withKnownIssue("Incorrect assertion should fail") {
            await ["cool"]
                .publisher
                .expect("neat")
                .waitForExpectations(timeout: 1)
        }
        
        await withKnownIssue("Incorrect assertion should fail") {
            await [String]()
                .publisher
                .expect("neat")
                .waitForExpectations(timeout: 1)
        }
    }
    
    @Test func testExpectExactlyCountOfEquatableValues() async {
        await ["cool", "cool"]
            .publisher
            .expectExactly(2, of: "cool")
            .waitForExpectations(timeout: 1)
    }
    
    @Test func testExpectExactlyCountOfEquatableValuesFail() async {
        await withKnownIssue("Incorrect assertion should fail") {
            await ["cool"]
                .publisher
                .expectExactly(2, of: "neat")
                .waitForExpectations(timeout: 1)
        }
        
        await withKnownIssue("Incorrect assertion should fail") {
            await [String]()
                .publisher
                .expectExactly(2, of: "neat")
                .waitForExpectations(timeout: 1)
        }
        
        await withKnownIssue("Incorrect assertion should fail") {
            await ["cool"]
                .publisher
                .expectExactly(2, of: "cool")
                .waitForExpectations(timeout: 1)
        }
        
        await withKnownIssue("Incorrect assertion should fail") {
            await ["cool", "cool", "cool"]
                .publisher
                .expectExactly(2, of: "cool")
                .waitForExpectations(timeout: 1)
        }
    }
    
    @Test func testExpectNotEquatableValue() async {
        await ["neat"]
            .publisher
            .expectNot("cool")
            .waitForExpectations(timeout: 1)
    }
    
    @Test func testExpectNotEquatableValueFail() async {
        await withKnownIssue("Incorrect assertion should fail") {
            await ["cool"]
                .publisher
                .expectNot("cool")
                .waitForExpectations(timeout: 1)
        }
        
        
        await withKnownIssue("Incorrect assertion should fail") {
            await [String]()
                .publisher
                .expectNot("cool")
                .waitForExpectations(timeout: 1)
        }
    }
    
    @Test func testExpectNoValue() async {
        await [String]()
            .publisher
            .expectNoValue()
            .waitForExpectations(timeout: 1)
    }
    
    @Test func testExpectNoValueFail() async {
        await withKnownIssue("Incorrect assertion should fail") {
            await ["cool"]
                .publisher
                .expectNoValue()
                .waitForExpectations(timeout: 1)
        }
    }
    
    @Test func testExpectValueClosure() async {
        await ["cool"]
            .publisher
            .expect({ #expect("cool" == $0) })
            .waitForExpectations(timeout: 1)
        
    }
    
    @Test func testExpectValueClosureFail() async {
        await withKnownIssue("Incorrect assertion should fail") {
            await  ["cool"]
                .publisher
                .expect({ #expect("neat" == $0) })
                .waitForExpectations(timeout: 1)
        }
        
        await withKnownIssue("Incorrect assertion should fail") {
            await [String]()
                .publisher
                .expect({ #expect("neat" == $0) })
                .waitForExpectations(timeout: 1)
        }
        
    }
    
    @Test func testExpectExactlyCountOfValueClosure() async {
        await ["cool", "cool"]
            .publisher
            .expectExactly(2, { #expect("cool" == $0) })
            .waitForExpectations(timeout: 1)
        
    }
    
    @Test func testExpectExactlyCountOfValueClosureFail() async {
        await withKnownIssue("Incorrect assertion should fail") {
            await ["cool", "cool"]
                .publisher
                .expectExactly(2, { #expect("neat" == $0) })
                .waitForExpectations(timeout: 1)
        }
        
        await withKnownIssue("Incorrect assertion should fail") {
            await ["cool"]
                .publisher
                .expectExactly(2, { #expect("cool" == $0) })
                .waitForExpectations(timeout: 1)
        }
        
        await withKnownIssue("Incorrect assertion should fail") {
            await ["cool", "cool", "cool"]
                .publisher
                .expectExactly(2, { #expect("cool" == $0) })
                .waitForExpectations(timeout: 1)
        }
        
        await withKnownIssue("Incorrect assertion should fail") {
            await ["cool", "cool", "neat"]
                .publisher
                .expectExactly(2, { #expect("cool" == $0) })
                .waitForExpectations(timeout: 1)
        }
    }
    
    @Test func testMulitpleEquatableValues() async {
        await ["cool", "neat", "awesome"]
            .publisher
            .collect(3)
            .expect(["cool", "neat", "awesome"])
            .waitForExpectations(timeout: 1)
    }
    
    @Test func testMulitpleEquatableValuesFail() async {
        await withKnownIssue("Incorrect assertion should fail") {
            await ["cool", "neat", "awesome"]
                .publisher
                .collect(3)
                .expect(["cool", "neat", "not awesome"])
                .waitForExpectations(timeout: 1)
        }
        
        await withKnownIssue("Incorrect assertion should fail") {
            await [String]()
                .publisher
                .collect(3)
                .expect(["cool", "neat", "awesome"])
                .waitForExpectations(timeout: 1)
        }
    }
    
    @Test func testMulitpleValuesClosure() async {
        await ["cool", "neat", "awesome"]
            .publisher
            .collect(3)
            .expect({ #expect($0[1] == "neat") })
            .waitForExpectations(timeout: 1)
    }
    
    @Test func testMulitpleValuesClosureFail() async {
        await withKnownIssue("Incorrect assertion should fail") {
            await ["cool", "neat", "awesome"]
                .publisher
                .collect(3)
                .expect({ #expect($0[0] == "neat") })
                .waitForExpectations(timeout: 1)
        }
    }
    
    // MARK: - Receive Completion Expectations
    
    @Test func testCompletion() async {
        await [Int]()
            .publisher
            .expectCompletion()
            .waitForExpectations(timeout: 1)
    }
    
    @Test func testCompletionFail() async {
        await withKnownIssue("Incorrect assertion should fail") {
            await PassthroughSubject<Void, Never>()
                .expectCompletion()
                .waitForExpectations(timeout: 1)
        }
    }
    
    @Test func testNoCompletion() async {
        await  PassthroughSubject<Void, Never>()
            .expectNoCompletion()
            .waitForExpectations(timeout: 1)
    }
    
    @Test func testNoCompletionFail() async {
        await withKnownIssue("Incorrect assertion should fail") {
            await [Int]()
                .publisher
                .expectNoCompletion()
                .waitForExpectations(timeout: 1)
        }
    }
    
    @Test func testCompletionClosure() async {
        await  [Int]()
            .publisher
            .expectCompletion({ #expect($0 == .finished) })
            .waitForExpectations(timeout: 1)
    }
    
    @Test func testCompletionClosureFail() async {
        await withKnownIssue("Incorrect assertion should fail") {
            await Fail<Void, MockError>(error: MockError.someProblem)
                .expectCompletion({ #expect($0 == .finished) })
                .waitForExpectations(timeout: 1)
        }
        
        await withKnownIssue("Incorrect assertion should fail") {
            await PassthroughSubject<Void, Never>()
                .expectCompletion({ #expect($0 == .finished) })
                .waitForExpectations(timeout: 1)
        }
    }
    
    // MARK: - Receive Success Expectations
    
    @Test func testSuccessCompletion() async {
        await [Int]()
            .publisher
            .expectSuccess()
            .waitForExpectations(timeout: 1)
    }
    
    @Test func testSuccessCompletionFail() async {
        await withKnownIssue("Incorrect assertion should fail") {
            await PassthroughSubject<Void, Never>()
                .expectSuccess()
                .waitForExpectations(timeout: 1)
        }
    }
    
    // MARK: - Receive Completion Failure Expectations
    
    @Test func testFailureCompletion() async {
        await Fail<Void, MockError>(error: MockError.someProblem)
            .expectFailure()
            .waitForExpectations(timeout: 1)
    }
    
    @Test func testFailureCompletionFail() async {
        await withKnownIssue("Incorrect assertion should fail") {
            await PassthroughSubject<Void, MockError>()
                .expectFailure()
                .waitForExpectations(timeout: 1)
        }
    }
    
    @Test func testFailureValueCompletion() async {
        await Fail<Void, MockError>(error: MockError.someProblem)
            .expectFailure(MockError.someProblem)
            .waitForExpectations(timeout: 1)
    }
    
    @Test func testFailureValueCompletionFail() async {
        await withKnownIssue("Incorrect assertion should fail") {
            await PassthroughSubject<Void, MockError>()
                .expectFailure(MockError.someProblem)
                .waitForExpectations(timeout: 1)
        }
        
        await withKnownIssue("Incorrect assertion should fail") {
            await Fail<Void, MockError>(error: MockError.otherProblem)
                .expectFailure(MockError.someProblem)
                .waitForExpectations(timeout: 1)
        }
    }
    
    @Test func testNotFailureValueCompletion() async {
        await Fail<Void, MockError>(error: MockError.someProblem)
            .expectNotFailure(MockError.otherProblem)
            .waitForExpectations(timeout: 1)
    }
    
    @Test func testNotFailureValueCompletionFail() async {
        await withKnownIssue("Incorrect assertion should fail") {
            await PassthroughSubject<Void, MockError>()
                .expectNotFailure(MockError.someProblem)
                .waitForExpectations(timeout: 1)
        }
        
        await withKnownIssue("Incorrect assertion should fail") {
            await Fail<Void, MockError>(error: MockError.someProblem)
                .expectNotFailure(MockError.someProblem)
                .waitForExpectations(timeout: 1)
        }
    }
    
    @Test func testFailureClosureCompletion() async {
        await Fail<Void, MockError>(error: MockError.someProblem)
            .expectFailure({ #expect($0 == .someProblem) })
            .waitForExpectations(timeout: 1)
    }
    
    @Test func testFailureClosureCompletionFail() async {
        await withKnownIssue("Incorrect assertion should fail") {
            await Fail<Void, MockError>(error: MockError.someProblem)
                .expectFailure({ #expect($0 == .otherProblem) })
                .waitForExpectations(timeout: 1)
        }
        
        await withKnownIssue("Incorrect assertion should fail") {
            await PassthroughSubject<Void, MockError>()
                .expectFailure({ #expect($0 == .someProblem) })
                .waitForExpectations(timeout: 1)
        }
    }
    
    @Test func testVoid() async {
        await Just<Void>(Void())
            .expectVoid()
            .waitForExpectations(timeout: 1)
    }
    
    @Test func testVoidFail() async {
        await withKnownIssue("Incorrect assertion should fail") {
            await Empty<Void, Never>(completeImmediately: true)
                .expectVoid()
                .waitForExpectations(timeout: 1)
        }
    }
    
    // MARK: - Misc Tests
    
    @Test func testMultipleExpectations() async {
        await ["cool"]
            .publisher
            .expect("cool")
            .expect({ #expect($0 == "cool") })
            .expectSuccess()
            .expectCompletion()
            .expectCompletion({ #expect($0 == .finished) })
            .waitForExpectations(timeout: 1)
    }
    
    @Test func testMultipleFailures() async {
        await withKnownIssue("Incorrect assertion should fail") {
            await PassthroughSubject<String, MockError>()
                .expect("cool")
                .expect({ #expect($0 == "cool") })
                .expectFailure()
                .expectFailure({ #expect($0 == .someProblem) })
                .expectFailure(.someProblem)
                .expectSuccess()
                .expectCompletion()
                .expectCompletion({ #expect($0 == .finished) })
                .waitForExpectations(timeout: 1)
        }
    }
    
    // TODO: Why is this supposed to fail?
    @Test func testOrderFail() async {
        await withKnownIssue("Incorrect assertion should fail") {
            let publisher = PassthroughSubject<String, Never>()
            let test: SwiftTestingPublisherExpectation = publisher
                .expectSuccess()
                .expect("cool")
            publisher.send("cool")
            publisher.send(completion: .finished)
            await test.waitForExpectations(timeout: 1, enforceOrder: true)
        }
    }
    
    @Test func succeedsWhenEnforceOrderCorrectOrder() async {
        let publisher = PassthroughSubject<String, Never>()
        let test: SwiftTestingPublisherExpectation = publisher
            .collect(3)
            .expectSuccess()
            .expect(["this", "is", "cool"])
        publisher.send("this")
        publisher.send("is")
        publisher.send("cool")
        publisher.send(completion: .finished)
        await test.waitForExpectations(timeout: 1, enforceOrder: true)
    }
    
    @Test func failsWhenEnforceOrderIncorrectOrder() async {
        await withKnownIssue("Incorrect assertion should fail") {
            let publisher = PassthroughSubject<String, Never>()
            let test: SwiftTestingPublisherExpectation = publisher
                .collect(3)
                .expectSuccess()
                .expect(["this", "is", "cool"])
            publisher.send("cool")
            publisher.send("is")
            publisher.send("this")
            publisher.send(completion: .finished)
            await test.waitForExpectations(timeout: 1, enforceOrder: true)
        }
    }
    
    @Test func succeedsNonEnforceOrderIncorrectOrder() async {
        let publisher = PassthroughSubject<String, Never>()
        let test: SwiftTestingPublisherExpectation = publisher
            .collect(3)
            .expectSuccess()
            .expect(["this", "is", "cool"])
        publisher.send("cool")
        publisher.send("this")
        publisher.send("is")
        publisher.send(completion: .finished)
        await test.waitForExpectations(timeout: 1)
    }
    
    @Test func testDeferredWait() async {
        let currentValueSubject = CurrentValueSubject<String, Never>("cool")
        let test = currentValueSubject
            .collect(2)
            .expect(["cool", "neat"])
        currentValueSubject.value = "neat"
        await test.waitForExpectations(timeout: 1)
    }
    
    @Test func testMultiThreadedExpectation() async {
        let currentValueSubject = CurrentValueSubject<String, Never>("cool")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            currentValueSubject.value = "neat"
        }
        await currentValueSubject
            .collect(2)
            .expect(["cool", "neat"])
            .waitForExpectations(timeout: 1)
    }
    
    @Test func testExpectNoValueAndCompletion() async {
        await [String]()
            .publisher
            .expectNoValue()
            .expectCompletion()
            .waitForExpectations(timeout: 1)
    }
    
    @Test func testExpectNoValueAndCompletionFail() async {
        await withKnownIssue("Incorrect assertion should fail") {
            await CurrentValueSubject<String, Never>("cool")
                .expectNoValue()
                .expectCompletion()
                .waitForExpectations(timeout: 1)
        }
        
        await withKnownIssue("Incorrect assertion should fail") {
            await PassthroughSubject<String, Never>()
                .expectNoValue()
                .expectCompletion()
                .waitForExpectations(timeout: 1)
        }
    }
}

extension SwiftTestingTestableCombinePublishersTests {
    enum MockError: Error {
        case someProblem
        case otherProblem
    }
}
