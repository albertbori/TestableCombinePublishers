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
    
    @Test func expectEquatableValue() async {
        await ["cool"]
            .publisher
            .expect("cool")
            .waitForExpectations(timeout: 1)
        
        await ["cool", "cool", "cool"]
            .publisher
            .expect("cool")
            .waitForExpectations(timeout: 1)
    }
    
    @Test func expectEquatableValueFail() async {
        
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
    
    @Test func expectExactlyCountOfEquatableValues() async {
        await ["cool", "cool"]
            .publisher
            .expectExactly(2, of: "cool")
            .waitForExpectations(timeout: 1)
    }
    
    @Test func expectExactlyCountOfEquatableValuesFail() async {
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
    
    @Test func expectNotEquatableValue() async {
        await ["neat"]
            .publisher
            .expectNot("cool")
            .waitForExpectations(timeout: 1)
    }
    
    @Test func expectNotEquatableValueFail() async {
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
    
    @Test func expectNoValue() async {
        await [String]()
            .publisher
            .expectNoValue()
            .waitForExpectations(timeout: 1)
    }
    
    @Test func expectNoValueFail() async {
        await withKnownIssue("Incorrect assertion should fail") {
            await ["cool"]
                .publisher
                .expectNoValue()
                .waitForExpectations(timeout: 1)
        }
    }
    
    @Test func expectValueClosure() async {
        await ["cool"]
            .publisher
            .expect({ #expect("cool" == $0) })
            .waitForExpectations(timeout: 1)
        
    }
    
    @Test func expectValueClosureFail() async {
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
    
    @Test func expectExactlyCountOfValueClosure() async {
        await ["cool", "cool"]
            .publisher
            .expectExactly(2, { #expect("cool" == $0) })
            .waitForExpectations(timeout: 1)
        
    }
    
    @Test func expectExactlyCountOfValueClosureFail() async {
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
    
    @Test func multipleEquatableValues() async {
        await ["cool", "neat", "awesome"]
            .publisher
            .collect(3)
            .expect(["cool", "neat", "awesome"])
            .waitForExpectations(timeout: 1)
    }
    
    @Test func multipleEquatableValuesFail() async {
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
    
    @Test func multipleValuesClosure() async {
        await ["cool", "neat", "awesome"]
            .publisher
            .collect(3)
            .expect({ #expect($0[1] == "neat") })
            .waitForExpectations(timeout: 1)
    }
    
    @Test func multipleValuesClosureFail() async {
        await withKnownIssue("Incorrect assertion should fail") {
            await ["cool", "neat", "awesome"]
                .publisher
                .collect(3)
                .expect({ #expect($0[0] == "neat") })
                .waitForExpectations(timeout: 1)
        }
    }
    
    // MARK: - Receive Completion Expectations
    
    @Test func completion() async {
        await [Int]()
            .publisher
            .expectCompletion()
            .waitForExpectations(timeout: 1)
    }
    
    @Test func completionFail() async {
        await withKnownIssue("Incorrect assertion should fail") {
            await PassthroughSubject<Void, Never>()
                .expectCompletion()
                .waitForExpectations(timeout: 1)
        }
    }
    
    @Test func noCompletion() async {
        await  PassthroughSubject<Void, Never>()
            .expectNoCompletion()
            .waitForExpectations(timeout: 1)
    }
    
    @Test func noCompletionFail() async {
        await withKnownIssue("Incorrect assertion should fail") {
            await [Int]()
                .publisher
                .expectNoCompletion()
                .waitForExpectations(timeout: 1)
        }
    }
    
    @Test func completionClosure() async {
        await  [Int]()
            .publisher
            .expectCompletion({ #expect($0 == .finished) })
            .waitForExpectations(timeout: 1)
    }
    
    @Test func completionClosureFail() async {
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
    
    @Test func successCompletion() async {
        await [Int]()
            .publisher
            .expectSuccess()
            .waitForExpectations(timeout: 1)
    }
    
    @Test func successCompletionFail() async {
        await withKnownIssue("Incorrect assertion should fail") {
            await PassthroughSubject<Void, Never>()
                .expectSuccess()
                .waitForExpectations(timeout: 1)
        }
    }
    
    // MARK: - Receive Completion Failure Expectations
    
    @Test func failureCompletion() async {
        await Fail<Void, MockError>(error: MockError.someProblem)
            .expectFailure()
            .waitForExpectations(timeout: 1)
    }
    
    @Test func failureCompletionFail() async {
        await withKnownIssue("Incorrect assertion should fail") {
            await PassthroughSubject<Void, MockError>()
                .expectFailure()
                .waitForExpectations(timeout: 1)
        }
    }
    
    @Test func failureValueCompletion() async {
        await Fail<Void, MockError>(error: MockError.someProblem)
            .expectFailure(MockError.someProblem)
            .waitForExpectations(timeout: 1)
    }
    
    @Test func failureValueCompletionFail() async {
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
    
    @Test func notFailureValueCompletion() async {
        await Fail<Void, MockError>(error: MockError.someProblem)
            .expectNotFailure(MockError.otherProblem)
            .waitForExpectations(timeout: 1)
    }
    
    @Test func notFailureValueCompletionFail() async {
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
    
    @Test func failureClosureCompletion() async {
        await Fail<Void, MockError>(error: MockError.someProblem)
            .expectFailure({ #expect($0 == .someProblem) })
            .waitForExpectations(timeout: 1)
    }
    
    @Test func failureClosureCompletionFail() async {
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
    
    // MARK: - Void Publisher Expectations
    
    @Test func void() async {
        await Just<Void>(Void())
            .expectVoid()
            .waitForExpectations(timeout: 1)
    }
    
    @Test func voidFail() async {
        await withKnownIssue("Incorrect assertion should fail") {
            await Empty<Void, Never>(completeImmediately: true)
                .expectVoid()
                .waitForExpectations(timeout: 1)
        }
    }
    
    // MARK: - Misc Tests
    
    @Test func multipleExpectations() async {
        await ["cool"]
            .publisher
            .expect("cool")
            .expect({ #expect($0 == "cool") })
            .expectSuccess()
            .expectCompletion()
            .expectCompletion({ #expect($0 == .finished) })
            .waitForExpectations(timeout: 1)
    }
    
    @Test func multipleFailures() async {
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
    
    @Test func deferredWait() async {
        let currentValueSubject = CurrentValueSubject<String, Never>("cool")
        let test = currentValueSubject
            .collect(2)
            .expect(["cool", "neat"])
        currentValueSubject.value = "neat"
        await test.waitForExpectations(timeout: 1)
    }
    
    @Test func multiThreadedExpectation() async {
        let currentValueSubject = CurrentValueSubject<String, Never>("cool")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            currentValueSubject.value = "neat"
        }
        await currentValueSubject
            .collect(2)
            .expect(["cool", "neat"])
            .waitForExpectations(timeout: 1)
    }
    
    @Test func expectNoValueAndCompletion() async {
        await [String]()
            .publisher
            .expectNoValue()
            .expectCompletion()
            .waitForExpectations(timeout: 1)
    }
    
    @Test func expectNoValueAndCompletionFail() async {
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
