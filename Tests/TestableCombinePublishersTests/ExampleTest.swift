import Combine
import XCTest

class ExampleTest: XCTestCase {
    
    func testFail() {
        let publisher = CurrentValueSubject<String, Error>("foo")
        publisher
            .expect("bar")
            .expectSuccess()
            .waitForExpectations(timeout: 1)
    }
    
    func testPass() {
        let publisher = ["baz"].publisher
        publisher
            .expect("baz")
            .expectSuccess()
            .waitForExpectations(timeout: 1)
    }

}
