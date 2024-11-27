import Combine
import Testing

struct ExampleTest {
    
    @Test func fail() async {
        let publisher = CurrentValueSubject<String, Error>("foo")
        await publisher
            .testable()
            .expect("bar")
            .expectSuccess()
            .waitForExpectations(timeout: 1)
    }
    
    @Test func pass() async {
        let publisher = ["baz"].publisher
        await publisher
            .testable()
            .expect("baz")
            .expectSuccess()
            .waitForExpectations(timeout: 1)
    }
}


