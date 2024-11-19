//
//  SwiftTestingExpectation.swift
//  TestableCombinePublishers
//
//  Created by Ethan van Heerden on 11/15/24.
//

import Foundation
import Testing

/// The Swift Testing version of an `XCTestExpectation`.
final class SwiftTestingExpectation {
    let id: UUID
    let description: String
    private let expectedFulfillmentCount: Int
    let isInverted: Bool
    let sourceLocation: SourceLocation
    private var actualFulfillmentCount: Int = 0
    private let actualFulfillmentCountLock = NSLock()
    
    init(id: UUID = UUID(),
         description: String,
         expectedFulfillmentCount: Int = 1,
         isInverted: Bool = false,
         sourceLocation: SourceLocation) {
        self.id = id
        self.description = description
        self.expectedFulfillmentCount = expectedFulfillmentCount
        self.isInverted = isInverted
        self.sourceLocation = sourceLocation
    }
    
    /// Fulfills this expectation by increasing the `actualFulfillmentCount`.
    func fulfill() {
        actualFulfillmentCountLock.withLock {
            actualFulfillmentCount += 1
        }
    }
    
    /// Determines if this expectation is considered fully fulfilled.
    /// An expectation is considered fulfilled when the `actualFulfillmentCount` is greater than or equal to
    /// the `expectedFulfillmentCount`
    var isFulfilled: Bool {
        actualFulfillmentCountLock.withLock {
            return actualFulfillmentCount >= expectedFulfillmentCount
        }
    }
}
