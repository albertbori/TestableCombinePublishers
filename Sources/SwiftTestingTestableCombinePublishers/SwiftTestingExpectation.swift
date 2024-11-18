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
    
    func fulfill() {
        actualFulfillmentCountLock.withLock {
            actualFulfillmentCount += 1
        }
    }
    
    var isFulfilled: Bool {
        actualFulfillmentCountLock.withLock {
            return actualFulfillmentCount >= expectedFulfillmentCount
        }
    }
}
