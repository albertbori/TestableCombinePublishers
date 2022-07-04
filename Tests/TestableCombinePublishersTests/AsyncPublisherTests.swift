//
//  AsyncPublisherTests.swift
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
import TestableCombinePublishers

class AsyncPublisherTest: XCTestCase {
    
    func testFail() async throws {
        enum TestError: Error, Equatable {
            case expectedTestError
        }
        
        do {
            _ = try await Fail<String, Error>(error: TestError.expectedTestError).awaitFirstValue()
            XCTFail("This should not pass")
        } catch let error as TestError {
            XCTAssertEqual(error, .expectedTestError)
        }
    }
    
    func testFinishedWithoutValue() async throws {
        do {
            let subject = PassthroughSubject<String, Error>()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                subject.send(completion: .finished)
            }
            
            _ = try await subject.awaitFirstValue()
            XCTFail("This should not pass")
        } catch let error as AsyncPublisherError {
            XCTAssertEqual(error, .finishedWithoutValue)
        }
    }
    
    func testPass() async throws {
        let value = try await CurrentValueSubject<String, Error>("foo").awaitFirstValue()
        XCTAssertEqual(value, "foo")
    }
    
    func testPassDelayed() async throws {
        let value = try await CurrentValueSubject<String, Error>("foo")
            .delay(for: 0.1, scheduler: DispatchQueue.main)
            .awaitFirstValue()
        XCTAssertEqual(value, "foo")
    }
    
}
