//
//  ThreadSafeArray.swift
//  TestableCombinePublishers
//
//  Created by Ethan van Heerden on 11/18/24.
//

/// Thread-safe implementation of an array which wraps array logic inside of an actor.
/// Note: This does not encapsulate all array functionality - just that which is needed for `SwiftTestingPublisherExpectation`.
public final actor ThreadSafeArray<Element> {
    private(set) var items: Array<Element>
    
    public init(items: Array<Element> = []) {
        self.items = items
    }
    
    public var isEmpty: Bool {
        return items.isEmpty
    }
    
    public func append(_ newElement: Element) {
        items.append(newElement)
    }
    
    public func removeFirst() -> Element? {
        guard !items.isEmpty else { return nil }
        return items.removeFirst()
    }
    
    public subscript(index: Int) -> Element? {
        get {
            guard index >= 0, index < items.count else { return nil }
            return items[index]
        }
    }
}
