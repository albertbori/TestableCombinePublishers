//
//  AutomaticallyEquatable.swift
//  TestableCombinePublishers
//
//  Copyright (c) 2022 Albert Bori

import Foundation

/// Implements `Equatable` for this type and its descendants by using reflection to traverse members or associated values (enums)
///
/// When you have a complex type or type graph that you would like to compare for unit testing purposes, you can use this protocol by extending your type to conform to it.
/// This will drastically reduce the volume of code required to make unit test equality assertions on custom types.
/// It also negates the need to rely on custom `Equatable` implementations.
/// (Custom `Equatable` implementations come with the risk that future changes to the type may invalidate the equatable implementation without warning.)
///
/// **Important Disclosures**
///
/// This is an imperfect and assuming implementation of `Equatable`. It should not be used without understanding the following concepts.
///
/// The implementation:
///
/// - Cannot anticipate the consequences of observing a calculated property. (ie, code that changes the state of data when a property is observed).
/// - Cannot respect custom `Equatable` implementations of the values being compared or any of the subsequent members. It will use its own comparison logic instead.
/// - Skips over members that cannot be reasonably compared, such as closures. These are assumed to be equal.
/// - Does not support recursive evaluation of reflexive types (it will crash if a property on a type references itself)
///
/// ## Usage
///
/// You can conform to the protocol with a single line of code:
///
/// ```swift
/// enum MyCustomType {
///     case foo
///     case bar(Baz)
/// }
///
/// extension MyCustomType: AutomaticallyEquatable { /*no-op*/ }
/// ```
///
/// Then, you can compare two of `MyCustomType` using `==` or an XCTest framework equality assertion.
///
/// ```swift
/// XCTAssertEqual(output, MyCustomType.bar(Baz(answer: 42))
/// ```
///
/// If you would like to observe the comparison information, you can invoke the following directly to get a detailed result object:
///
/// ```swift
/// switch MyCustomType.compare(foo, bar) {
/// case .equal:
///     break
/// case .unequal(let difference):
///     print(difference.debugDescription)
/// }
/// ```
public protocol AutomaticallyEquatable: Equatable { }

public extension AutomaticallyEquatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        compare(lhs: lhs, rhs: rhs).isEqual
    }
    
    static func compare(lhs: Self?, rhs: Self?) -> RecursiveComparatorResult {
        RecursiveComparator.compare(lhs: lhs, rhs: rhs)
    }
}

public enum RecursiveComparator {
    public static func compare<Value>(lhs: Value?, rhs: Value?) -> RecursiveComparatorResult {
        // Get underlying non-optional root type for debug description
        let rootType: Any.Type = lhs.map({ type(of: $0) }) ?? type(of: lhs)
        let members: [String] = ["\(rootType)"]
        return compare(lhs: lhs, rhs: rhs, members: members)
    }
    
    private static func compare(lhs: Any?, rhs: Any?, members: [String]) -> RecursiveComparatorResult {
        // check each core value type
        if let lhs = lhs as? AnyHashable, let rhs = rhs as? AnyHashable {
            return lhs == rhs ? .equal : .unequal(.init(members: members, lhs: lhs, rhs: rhs))
        }
        
        // try dictionary
        if let lhs = lhs as? Dictionary<AnyHashable, Any>, let rhs = rhs as? Dictionary<AnyHashable, Any> {
            return compareDictionaries(lhs: lhs, rhs: rhs, members: members)
        }
        
        // try array
        if let lhs = lhs as? Array<Any>, let rhs = rhs as? Array<Any> {
            return compareCollections(lhs: lhs, rhs: rhs, members: members)
        }
        
        // try set
        if let lhs = lhs as? Set<AnyHashable>, let rhs = rhs as? Set<AnyHashable> {
            return compareCollections(lhs: lhs, rhs: rhs, members: members)
        }
        
        // if we get here, compare by recursive mirror
        return compareMembers(lhs: lhs, rhs: rhs, members: members)
    }
    
    private static func compareMembers(
        lhs: Any?,
        lhsMirror: Mirror? = nil,
        rhs: Any?,
        rhsMirror: Mirror? = nil,
        members: [String]
    ) -> RecursiveComparatorResult {
        // short-circuit optional type traversal
        guard let lhs = lhs, let rhs = rhs else {
            if lhs == nil && rhs == nil {
                return .equal
            }
            return .unequal(.init(members: members, lhs: lhs, rhs: rhs))
        }

        let lhsMirror = lhsMirror ?? Mirror(reflecting: lhs)
        let rhsMirror = rhsMirror ?? Mirror(reflecting: rhs)
        
        // recursively compare superclass members
        if let lhsSuperMirror = lhsMirror.superclassMirror, let rhsSuperMirror = rhsMirror.superclassMirror {
            let superclassResult = compareMembers(
                lhs: lhs,
                lhsMirror: lhsSuperMirror,
                rhs: rhs,
                rhsMirror: rhsSuperMirror,
                members: members)
            if !superclassResult.isEqual {
                return superclassResult
            }
        }
        
        // compare members
        guard lhsMirror.children.count == rhsMirror.children.count else {
            if lhsMirror.displayStyle == .collection {
                return .unequal(.init(members: members + ["count"], lhs: lhsMirror.children.count, rhs: rhsMirror.children.count))
            }
            return .unequal(.init(members: members, lhs: lhs, rhs: rhs))
        }
        for (index, (lhsChild, rhsChild)) in zip(lhsMirror.children, rhsMirror.children).enumerated() {
            // if enum, compare cases (when mirrored, enum case names manifest as labels, not values)
            guard lhsChild.label == rhsChild.label else {
                return .unequal(.init(members: members, lhs: lhsChild.label, rhs: rhsChild.label))
            }
            var members = members
            if let childLabel = lhsChild.label, lhsMirror.displayStyle != .optional {
                members.append(childLabel)
            }
            let memberResult = compare(lhs: lhsChild.value, rhs: rhsChild.value, members: members)
            if case .unequal(var difference) = memberResult {
                if lhsMirror.displayStyle == .collection {
                    difference.members.append("\(index)")
                    return .unequal(difference)
                }
                return memberResult
            }
        }
        
        // if members can't be compared, or no members are unequal, default to equal
        return .equal
    }
    
    private static func compareCollections<SomeCollection: Collection>(lhs: SomeCollection, rhs: SomeCollection, members: [String]) -> RecursiveComparatorResult {
        var lhsIndex = lhs.startIndex
        var rhsIndex = rhs.startIndex
        while lhsIndex < lhs.endIndex || rhsIndex < rhs.endIndex {
            let index = max(lhsIndex, rhsIndex)
            let result = compare(lhs: lhs[safe: index], rhs: rhs[safe: index], members: members + ["\(index)"])
            if !result.isEqual {
                return result
            }
            lhsIndex = lhs.index(lhsIndex, offsetBy: 1)
            rhsIndex = rhs.index(rhsIndex, offsetBy: 1)
        }
        return .equal
    }
    
    private static func compareDictionaries<Key: Hashable, Value>(lhs: Dictionary<Key, Value>, rhs: Dictionary<Key, Value>, members: [String]) -> RecursiveComparatorResult {
        // check rhs values against lhs values
        for key in lhs.keys {
            let result = compare(lhs: lhs[key], rhs: rhs[key], members: members + ["\(key)"])
            if !result.isEqual {
                return result
            }
        }
        // check rhs keys against lhs keys
        if let lhsMissingKey = rhs.keys.first(where: { !lhs.keys.contains($0) }) {
            return .unequal(.init(members: members + ["\(lhsMissingKey)"], lhs: lhs[lhsMissingKey], rhs: rhs[lhsMissingKey]))
        }
        return .equal
    }
}

public enum RecursiveComparatorResult {
    case equal
    case unequal(Difference)
    
    public struct Difference {
        var members: [String]
        var lhs: Any?
        var rhs: Any?
    }
}

public extension RecursiveComparatorResult {
    var isEqual: Bool {
        switch self {
        case .equal:
            return true
        case .unequal:
            return false
        }
    }
    
    var debugDescription: String {
        switch self {
        case .equal:
            return "Values are equal"
        case .unequal(let difference):
            return difference.debugDescription
        }
    }
}

public extension RecursiveComparatorResult.Difference {
    var debugDescription: String {
        var location = ""
        if !members.isEmpty {
            location = "\(members.joined(separator: ".")): "
        }
        return "\(location)\(lhs ?? "nil") is not equal to \(rhs ?? "nil")"
    }
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
