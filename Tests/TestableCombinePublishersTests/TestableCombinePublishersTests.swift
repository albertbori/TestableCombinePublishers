//
//  TestableCombinePublishersTests.swift
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
import XCTest
@testable import TestableCombinePublishers

final class TestableCombinePublishersTests: XCTestCase {
    
    // MARK: - Receive Value Expectations
    
    func testExpectEquatableValue() {
        ["cool"]
            .publisher
            .expect("cool")
            .waitForExpectations(timeout: 1)
        
        ["cool", "cool", "cool"]
            .publisher
            .expect("cool")
            .waitForExpectations(timeout: 1)
    }
    
    func testExpectEquatableValueFail() {
        XCTExpectFailure("Incorrect assertion should fail")
        ["cool"]
            .publisher
            .expect("neat")
            .waitForExpectations(timeout: 1)
        
        XCTExpectFailure("Incorrect assertion should fail")
        [String]()
            .publisher
            .expect("neat")
            .waitForExpectations(timeout: 1)
    }
    
    func testExpectExactlyCountOfEquatableValues() {
        ["cool", "cool"]
            .publisher
            .expectExactly(2, of: "cool")
            .waitForExpectations(timeout: 1)
    }
    
    func testExpectExactlyCountOfEquatableValuesFail() {
        XCTExpectFailure("Incorrect assertion should fail")
        ["cool"]
            .publisher
            .expectExactly(2, of: "neat")
            .waitForExpectations(timeout: 1)
        
        XCTExpectFailure("Incorrect assertion should fail")
        [String]()
            .publisher
            .expectExactly(2, of: "neat")
            .waitForExpectations(timeout: 1)
        
        XCTExpectFailure("Incorrect assertion should fail")
        ["cool"]
            .publisher
            .expectExactly(2, of: "cool")
            .waitForExpectations(timeout: 1)
        
        XCTExpectFailure("Incorrect assertion should fail")
        ["cool", "cool", "cool"]
            .publisher
            .expectExactly(2, of: "cool")
            .waitForExpectations(timeout: 1)
    }
    
    func testExpectNotEquatableValue() {
        ["neat"]
            .publisher
            .expectNot("cool")
            .waitForExpectations(timeout: 1)
    }
    
    func testExpectNotEquatableValueFail() {
        XCTExpectFailure("Incorrect assertion should fail")
        ["cool"]
            .publisher
            .expectNot("cool")
            .waitForExpectations(timeout: 1)
        
        XCTExpectFailure("Incorrect assertion should fail")
        [String]()
            .publisher
            .expectNot("cool")
            .waitForExpectations(timeout: 1)
    }
    
    func testExpectNoValue() {
        [String]()
            .publisher
            .expectNoValue()
            .waitForExpectations(timeout: 1)
    }
    
    func testExpectNoValueFail() {
        XCTExpectFailure("Incorrect assertion should fail")
        ["cool"]
            .publisher
            .expectNoValue()
            .waitForExpectations(timeout: 1)
    }
    
    func testExpectValueClosure() async {
        ["cool"]
            .publisher
            .expect({ XCTAssertEqual("cool", $0) })
            .waitForExpectations(timeout: 1)

    }
    
    func testExpectValueClosureFail() async {
        XCTExpectFailure("Incorrect assertion should fail")
        ["cool"]
            .publisher
            .expect({ XCTAssertEqual("neat", $0) })
            .waitForExpectations(timeout: 1)
        
        XCTExpectFailure("Incorrect assertion should fail")
        [String]()
            .publisher
            .expect({ XCTAssertEqual("neat", $0) })
            .waitForExpectations(timeout: 1)

    }
    
    func testExpectExactlyCountOfValueClosure() async {
        ["cool", "cool"]
            .publisher
            .expectExactly(2, { XCTAssertEqual("cool", $0) })
            .waitForExpectations(timeout: 1)

    }
    
    func testExpectExactlyCountOfValueClosureFail() async {
        XCTExpectFailure("Incorrect assertion should fail")
        ["cool", "cool"]
            .publisher
            .expectExactly(2, { XCTAssertEqual("neat", $0) })
            .waitForExpectations(timeout: 1)
        
        XCTExpectFailure("Incorrect assertion should fail")
        ["cool"]
            .publisher
            .expectExactly(2, { XCTAssertEqual("cool", $0) })
            .waitForExpectations(timeout: 1)
        
        XCTExpectFailure("Incorrect assertion should fail")
        ["cool", "cool", "cool"]
            .publisher
            .expectExactly(2, { XCTAssertEqual("cool", $0) })
            .waitForExpectations(timeout: 1)
        
        XCTExpectFailure("Incorrect assertion should fail")
        ["cool", "cool", "neat"]
            .publisher
            .expectExactly(2, { XCTAssertEqual("cool", $0) })
            .waitForExpectations(timeout: 1)

    }
    
    func testMulitpleEquatableValues() async {
        ["cool", "neat", "awesome"]
            .publisher
            .collect(3)
            .expect(["cool", "neat", "awesome"])
            .waitForExpectations(timeout: 1)
    }
    
    func testMulitpleEquatableValuesFail() async {
        XCTExpectFailure("Incorrect assertion should fail")
        ["cool", "neat", "awesome"]
            .publisher
            .collect(3)
            .expect(["cool", "neat", "not awesome"])
            .waitForExpectations(timeout: 1)
        
        XCTExpectFailure("Incorrect assertion should fail")
        [String]()
            .publisher
            .collect(3)
            .expect(["cool", "neat", "awesome"])
            .waitForExpectations(timeout: 1)
    }
    
    func testMulitpleValuesClosure() async {
        ["cool", "neat", "awesome"]
            .publisher
            .collect(3)
            .expect({ XCTAssertEqual($0[1], "neat") })
            .waitForExpectations(timeout: 1)
    }
    
    func testMulitpleValuesClosureFail() async {
        XCTExpectFailure("Incorrect assertion should fail")
        ["cool", "neat", "awesome"]
            .publisher
            .collect(3)
            .expect({ XCTAssertEqual($0[0], "neat") })
            .waitForExpectations(timeout: 1)
    }
    
    // MARK: - Receive Completion Expectations
    
    func testCompletion() {
        [Int]()
            .publisher
            .expectCompletion()
            .waitForExpectations(timeout: 1)
    }
    
    func testCompletionFail() {
        XCTExpectFailure("Incorrect assertion should fail")
        PassthroughSubject<Void, Never>()
            .expectCompletion()
            .waitForExpectations(timeout: 1)
    }
    
    func testNoCompletion() {
        PassthroughSubject<Void, Never>()
            .expectNoCompletion()
            .waitForExpectations(timeout: 1)
    }
    
    func testNoCompletionFail() {
        XCTExpectFailure("Incorrect assertion should fail")
        [Int]()
            .publisher
            .expectNoCompletion()
            .waitForExpectations(timeout: 1)
    }
    
    func testCompletionClosure() {
        [Int]()
            .publisher
            .expectCompletion({ XCTAssertEqual($0, .finished) })
            .waitForExpectations(timeout: 1)
    }
    
    func testCompletionClosureFail() {
        XCTExpectFailure("Incorrect assertion should fail")
        Fail<Void, MockError>(error: MockError.someProblem)
            .expectCompletion({ XCTAssertEqual($0, .finished) })
            .waitForExpectations(timeout: 1)
        
        XCTExpectFailure("Incorrect assertion should fail")
        PassthroughSubject<Void, Never>()
            .expectCompletion({ XCTAssertEqual($0, .finished) })
            .waitForExpectations(timeout: 1)
    }
    
    // MARK: - Receive Success Expectations
    
    func testSuccessCompletion() {
        [Int]()
            .publisher
            .expectSuccess()
            .waitForExpectations(timeout: 1)
    }
    
    func testSuccessCompletionFail() {
        XCTExpectFailure("Incorrect assertion should fail")
        PassthroughSubject<Void, Never>()
            .expectSuccess()
            .waitForExpectations(timeout: 1)
    }
    
    // MARK: - Receive Completion Failure Expectations
    
    func testFailureCompletion() {
        Fail<Void, MockError>(error: MockError.someProblem)
            .expectFailure()
            .waitForExpectations(timeout: 1)
    }
    
    func testFailureCompletionFail() {
        XCTExpectFailure("Incorrect assertion should fail")
        PassthroughSubject<Void, MockError>()
            .expectFailure()
            .waitForExpectations(timeout: 1)
    }
    
    func testFailureValueCompletion() {
        Fail<Void, MockError>(error: MockError.someProblem)
            .expectFailure(MockError.someProblem)
            .waitForExpectations(timeout: 1)
    }
    
    func testFailureValueCompletionFail() {
        XCTExpectFailure("Incorrect assertion should fail")
        PassthroughSubject<Void, MockError>()
            .expectFailure(MockError.someProblem)
            .waitForExpectations(timeout: 1)
        
        XCTExpectFailure("Incorrect assertion should fail")
        Fail<Void, MockError>(error: MockError.otherProblem)
            .expectFailure(MockError.someProblem)
            .waitForExpectations(timeout: 1)
    }
    
    func testNotFailureValueCompletion() {
        Fail<Void, MockError>(error: MockError.someProblem)
            .expectNotFailure(MockError.otherProblem)
            .waitForExpectations(timeout: 1)
    }
    
    func testNotFailureValueCompletionFail() {
        XCTExpectFailure("Incorrect assertion should fail")
        PassthroughSubject<Void, MockError>()
            .expectNotFailure(MockError.someProblem)
            .waitForExpectations(timeout: 1)
        
        XCTExpectFailure("Incorrect assertion should fail")
        Fail<Void, MockError>(error: MockError.someProblem)
            .expectNotFailure(MockError.someProblem)
            .waitForExpectations(timeout: 1)
    }
    
    func testFailureClosureCompletion() {
        Fail<Void, MockError>(error: MockError.someProblem)
            .expectFailure({ XCTAssertEqual($0, .someProblem) })
            .waitForExpectations(timeout: 1)
    }
    
    func testFailureClosureCompletionFail() {
        XCTExpectFailure("Incorrect assertion should fail")
        Fail<Void, MockError>(error: MockError.someProblem)
            .expectFailure({ XCTAssertEqual($0, .otherProblem) })
            .waitForExpectations(timeout: 1)
        
        XCTExpectFailure("Incorrect assertion should fail")
        PassthroughSubject<Void, MockError>()
            .expectFailure({ XCTAssertEqual($0, .someProblem) })
            .waitForExpectations(timeout: 1)
        
    }
    
    // MARK: - Misc Tests
    
    func testMultipleExpectations() {
        ["cool"]
            .publisher
            .expect("cool")
            .expect({ XCTAssertEqual($0, "cool") })
            .expectSuccess()
            .expectCompletion()
            .expectCompletion({ XCTAssertEqual($0, .finished) })
            .waitForExpectations(timeout: 1)
    }
    
    func testMultipleFailures() {
        XCTExpectFailure("Incorrect assertion should fail")
        PassthroughSubject<String, MockError>()
            .expect("cool")
            .expect({ XCTAssertEqual($0, "cool") })
            .expectFailure()
            .expectFailure({ XCTAssertEqual($0, .someProblem) })
            .expectFailure(.someProblem)
            .expectSuccess()
            .expectCompletion()
            .expectCompletion({ XCTAssertEqual($0, .finished) })
            .waitForExpectations(timeout: 1)
    }
    
    // TODO: This is currently failing. The expectations should respect sequence, if possible.
    func testOrderFail() {
        XCTExpectFailure("Incorrect assertion should fail")
        ["cool"]
            .publisher
            .expectSuccess()
            .expect("cool")
            .waitForExpectations(timeout: 1)
    }
    
    func testDeferredWait() {
        let currentValueSubject = CurrentValueSubject<String, Never>("cool")
        let expectation = currentValueSubject
            .collect(2)
            .expect(["cool", "neat"])
        currentValueSubject.value = "neat"
        expectation.waitForExpectations(timeout: 1)
    }
    
    func testMultiThreadedExpectation() {
        let currentValueSubject = CurrentValueSubject<String, Never>("cool")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            currentValueSubject.value = "neat"
        }
        currentValueSubject
            .collect(2)
            .expect(["cool", "neat"])
            .waitForExpectations(timeout: 1)
    }
    
    func testExpectNoValueAndCompletion() {
        [String]()
            .publisher
            .expectNoValue()
            .expectCompletion()
            .waitForExpectations(timeout: 1)
    }
    
    func testExpectNoValueAndCompletionFail() {
        XCTExpectFailure("Incorrect assertion should fail")
        CurrentValueSubject<String, Never>("cool")
            .expectNoValue()
            .expectCompletion()
            .waitForExpectations(timeout: 1)
        
        XCTExpectFailure("Incorrect assertion should fail")
        PassthroughSubject<String, Never>()
            .expectNoValue()
            .expectCompletion()
            .waitForExpectations(timeout: 1)
    }
}

extension TestableCombinePublishersTests {
    enum MockError: Error {
        case someProblem
        case otherProblem
    }
}
