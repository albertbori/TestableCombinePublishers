# Testable Combine Publishers

An easy, declarative way to unit test Combine Publishers in Swift. Available for both XCTest and Swift Testing.

**XCTest**:

![Example Combine Unit Test - XCTest](example_xctest.png)

**Swift Testing**:

![Example Combine Unit Test - Swift Testing](example_swift_testing.png)

## About

Combine Publishers are [notoriously verbose to unit test](https://mokacoding.com/blog/testing-combine-publisher-cheatsheet/#how-to-test-publisher-publishes-one-value-then-finishes). They require you to write complex Combine chains in Swift for each test, keeping track of `AnyCancellable`s, and interweaving `XCTestExpectation`s, fulfillment requirements, and timeouts.

This Swift Package aims to simplify writing unit tests for Combine `Publisher`s by providing a natural spelling of `.expect(...)` for chaining expectations on the `Publisher` subject. The resulting `PublisherExpectation` or `SwiftTestingPublisherExpectation` type collects the various expectations and then provides a way to assert that the expectations are fulfilled by calling `.waitForExpectations(timeout: 1)`

Under the hood, `PublisherExpectation` is utilizing standard XCTest/Swift Testing framework APIs and forwarding those assertion results to the corresponding lines of code that declared the expectation. This allows you to quickly see which specific expectation, in a chain of expectations, is failing in your unit tests, both in Xcode and in the console output.

## Usage

In an `XCTestCase` or a Swift Testing suite, add a new unit test function, as normal, preparing the `Publisher` test subject to be tested. Utilize any combination of the examples below to validate the behavior of any `Publisher` in your unit tests.

### A Note on Swift Testing

This library provides different targets, `TestableCombinePublishers` and `SwiftTestingTestableCombinePublishers`, which enable utilizing the convenience expectation testing functions in both an XCTest and Swift Testing test suite, respectively. In an effort to keep the call-site expectation function names the same across both targets, you need to add an additional `.testable()` call on your Publisher _before_ you can utilize any of the testing functions. Otherwise, the compiler will not know which library you are referring:

```swift
// Swift Testing only:
@Test func myPublisherTest() async {
    await somePublisher
        .testable() // Not needed in an XCTest suite
        .expect(someEquatableValue)
        // <other testing functions>
        .waitForExpectations(timeout: 1)
}
```

### Examples

For a `Publisher` that is expected to emit a single value and complete with `.finished`

**XCTest**:
```swift
func testSingleValueCompletingPublisher() {
    somePublisher
        .expect(someEquatableValue)
        .expectSuccess()
        .waitForExpectations(timeout: 1)
}
```

**Swift Testing**:
```swift
@Test func singleValueCompletingPublisher() async {
    await somePublisher
        .testable()
        .expect(someEquatableValue)
        .expectSuccess()
        .waitForExpectations(timeout: 1)
}
```

For a `Publisher` that is expected to emit multiple values, but is expected to not complete

**XCTest**:
```swift
func testMultipleValuePersistentPublisher() {
    somePublisher
        .collect(someCount)
        .expect(someEquatableValueArray)
        .expectNoCompletion()
        .waitForExpectations(timeout: 1)
}
```

**Swift Testing**:
```swift
@Test func multipleValuePersistentPublisher() async {
    await somePublisher
        .collect(someCount)
        .testable()
        .expect(someEquatableValueArray)
        .expectNoCompletion()
        .waitForExpectations(timeout: 1)
}
```

For a `Publisher` that is expected to fail

**XCTest**:
```swift
func testPublisherFailure() {
    somePublisher
        .expectFailure()
        .waitForExpectations(timeout: 1)
}
```

**Swift Testing**:
```swift
@Test func publisherFailure() async {
    await somePublisher
        .testable()
        .expectFailure()
        .waitForExpectations(timeout: 1)
}
```

For a `Publisher` that is expected to emit a value after being acted upon externally

**XCTest**:
```swift
func testLoadablePublisher() {
    let test = someDataSource.publisher
        .expect(someEquatableValue)
    someDataSource.load()
    test.waitForExpectations(timeout: 1)
}
```

**Swift Testing**:
```swift
@Test func loadablePublisher() async {
    let test = someDataSource.publisher
        .testable()
        .expect(someEquatableValue)
    someDataSource.load()
    await test.waitForExpectations(timeout: 1)
}
```

For a `Publisher` expected to emit a single value whose `Output` is not `Equatable`

**XCTest**:
```swift
func testNonEquatableSingleValue() {
    somePublisher
        .expect({ value in
            if case .loaded(let model) = value, !model.rows.isEmpty { } else {
                XCTFail("Expected loaded and populated model")
            }
        })
        .waitForExpectations(timeout: 1)
}
```

**Swift Testing**:
```swift
@Test func nonEquatableSingleValue() async {
    await somePublisher
        .testable()
        .expect({ value in
            if case .loaded(let model) = value, !model.rows.isEmpty { } else {
                Issue.record("Expected loaded and populated model")
            }
        })
        .waitForExpectations(timeout: 1)
}
```

For a `Publisher` that should emit a specific non-`Equatable` `Error`

**XCTest**:
```swift
func testNonEquatableFailure() {
    somePublisher
        .expectFailure({ failure in 
            switch failure {
            case .noInternet, .airPlaneMode:
                break
            default:
                XCTFail("Expected connectivity error")
            }
        })
        .waitForExpectations(timeout: 1)
}
```

**Swift Testing**:
```swift
@Test func nonEquatableFailure() async {
    await somePublisher
        .testable()
        .expectFailure({ failure in 
            switch failure {
            case .noInternet, .airPlaneMode:
                break
            default:
                Issue.record("Expected connectivity error")
            }
        })
        .waitForExpectations(timeout: 1)
}
```

## Available Expectations

### Value Expectations

- `expect(_ expected: Output)` - Asserts that the provided `Equatable` value will be emitted by the `Publisher`
- `expectNot(_ expected: Output)` - Asserts that a value will be emitted by the `Publisher` and that it does NOT match the provided `Equatable`
- `expect(_ assertion: (Output) -> Void)` - Invokes the provided assertion closure on every value emitted by the `Publisher`. Useful for calling `XCTAssert`/`#expect` variants where custom evaluation is required

### Success Expectations

- `expectSuccess()` - Asserts that the `Publisher` data stream completes with a success status (`.finished`)

### Failure Expectations

- `expectFailure()` - Asserts that the `Publisher` data stream completes with a failure status (`.failure(Failure)`)
- `expectFailure(_ failure: Failure)` - Asserts that the provided `Equatable` `Failure` type is returned when the `Publisher` completes
- `expectNotFailure(_ failure: Failure)` - Asserts that the `Publisher` completes with a `Failure` type which does NOT match the provided `Equatable` `Failure`
- `expectFailure(_ assertion: (Failure) -> Void)` - Invokes the provided assertion closure on the `Failure` result's associated `Error` value  of the `Publisher`. Useful for calling `XCTAssert`/`#expect` variants where custom evaluation is required

### Completion Expectations

- `expectCompletion()` - Asserts that the `Publisher` data stream completes, indifferent of the returned success/failure status
- `expectNoCompletion()` - Asserts that the `Publisher` data stream does NOT complete. ⚠️ This will wait for the full timeout in `waitForExpectations(timeout:)`
- `expectCompletion(_ assertion: (Completion<Failure>) -> Void)` - Invokes the provided assertion closure on the `recieveCompletion` handler of the `Publisher`. Useful for calling `XCTAssert`/`#expect` variants where custom evaluation is required

## Upcoming Features

- Support for working with `Scheduler`s to avoid relying on timeouts

## AutomaticallyEquatable

When you have a complex type or type graph that you would like to compare for unit testing purposes, you can use this protocol by extending your type to conform to it.
This will drastically reduce the volume of code required to make unit test equality assertions on custom types.
It also negates the need to rely on custom `Equatable` implementations.
(Custom `Equatable` implementations come with the risk that future changes to the type may invalidate the equatable implementation without warning.)

**Important Disclosures**

- This is an imperfect and assuming implementation of `Equatable`. It should not be used without understanding the following concepts.
- `AutomaticallyEquatable` is available in the `TestableCombinePublishersUtility` target

The implementation:

- Is subject to the consequences of observing a calculated property. (ie, code that changes the state of data when a property is observed).
- Cannot respect custom `Equatable` implementations of the values being compared or any of the subsequent members. It will use its own comparison logic instead.
- Skips over members that cannot be reasonably compared, such as closures. These are assumed to be equal.

## Usage

You can conform to the protocol with a single line of code:

```swift
class Baz {
    let answer: Int
    init(answer: Init) {
        self.answer = answer
    }
}

enum MyCustomType {
    case foo
    case bar(Baz)
}

extension MyCustomType: AutomaticallyEquatable { /*no-op*/ }
```

Then, you can compare two of `MyCustomType` using `expect(...)`, `==`, or an XCTest/Swift Testing framework equality assertion.

```swift
// XCTest
somePublisher
    .expect(MyCustomType.bar(Baz(answer: 42)))
    .waitForExpectations(timeout: 1)

// Swift Testing
await somePublisher
    .testable()
    .expect(MyCustomType.bar(Baz(answer: 42)))
    .waitForExpectations(timeout: 1)

// or

XCTAssertEqual(output, MyCustomType.bar(Baz(answer: 42))) // If using XCTest
#expect(output == MyCustomType.bar(Baz(answer: 42))) // If using Swift Testing

// or

print(output == MyCustomType.bar(Baz(answer: 42)))
```

If you would like to see the comparison result, you can invoke the following directly to get a detailed result object:

```swift
switch MyCustomType.compare(foo, bar) {
case .equal:
    break
case .unequal(let difference):
    print(difference.debugDescription)
}
```
