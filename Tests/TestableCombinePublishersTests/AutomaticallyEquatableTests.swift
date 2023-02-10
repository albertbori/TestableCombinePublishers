//
//  AutomaticallyEquatableTests.swift
//  
//
//  Created by Albert Bori on 9/3/22.
//

import Foundation
import TestableCombinePublishers
import XCTest

final class AutomaticallyEquatableTests: XCTestCase {
    
    func testEnum() {
        XCTAssertEqual(EnumSubject.noAssociatedValue, EnumSubject.noAssociatedValue)
        XCTAssertEqual(EnumSubject.array(nil), EnumSubject.array(nil))
        XCTAssertEqual(EnumSubject.array([]), EnumSubject.array([]))
        XCTAssertEqual(EnumSubject.array(["hi"]), EnumSubject.array(["hi"]))
        XCTAssertEqual(EnumSubject.bool(nil), EnumSubject.bool(nil))
        XCTAssertEqual(EnumSubject.bool(true), EnumSubject.bool(true))
        XCTAssertEqual(EnumSubject.bool(false), EnumSubject.bool(false))
        XCTAssertEqual(EnumSubject.closure(nil), EnumSubject.closure(nil))
        XCTAssertEqual(EnumSubject.closure({ _ in true }), EnumSubject.closure({ _ in true }))
        XCTAssertEqual(EnumSubject.decimal(nil), EnumSubject.decimal(nil))
        XCTAssertEqual(EnumSubject.decimal(.greatestFiniteMagnitude), EnumSubject.decimal(.greatestFiniteMagnitude))
        XCTAssertEqual(EnumSubject.dictionary(nil), EnumSubject.dictionary(nil))
        XCTAssertEqual(EnumSubject.dictionary([:]), EnumSubject.dictionary([:]))
        XCTAssertEqual(EnumSubject.dictionary([1: "Cool"]), EnumSubject.dictionary([1: "Cool"]))
        XCTAssertEqual(EnumSubject.dictionary([1: "Cool", 2: "Neat"]), EnumSubject.dictionary([2: "Neat", 1: "Cool"]))
        XCTAssertEqual(EnumSubject.double(nil), EnumSubject.double(nil))
        XCTAssertEqual(EnumSubject.double(.greatestFiniteMagnitude), EnumSubject.double(.greatestFiniteMagnitude))
        XCTAssertEqual(EnumSubject.float(nil), EnumSubject.float(nil))
        XCTAssertEqual(EnumSubject.float(.greatestFiniteMagnitude), EnumSubject.float(.greatestFiniteMagnitude))
        XCTAssertEqual(EnumSubject.int(nil), EnumSubject.int(nil))
        XCTAssertEqual(EnumSubject.int(.max), EnumSubject.int(.max))
        XCTAssertEqual(EnumSubject.int64(nil), EnumSubject.int64(nil))
        XCTAssertEqual(EnumSubject.int64(.max), EnumSubject.int64(.max))
        XCTAssertEqual(EnumSubject.error(NSError(domain: "foo", code: -1)), EnumSubject.error(NSError(domain: "foo", code: -1)))
        XCTAssertEqual(EnumSubject.nestedEnum(nil), EnumSubject.nestedEnum(nil))
        XCTAssertEqual(EnumSubject.nestedEnum(.bool(true)), EnumSubject.nestedEnum(.bool(true)))
        XCTAssertEqual(EnumSubject.nestedEnum(.nestedEnum(nil)), EnumSubject.nestedEnum(.nestedEnum(nil)))
        XCTAssertEqual(EnumSubject.nestedEnum(.nestedEnum(.bool(false))), EnumSubject.nestedEnum(.nestedEnum(.bool(false))))
        XCTAssertEqual(EnumSubject.string(nil), EnumSubject.string(nil))
        XCTAssertEqual(EnumSubject.string("hi"), EnumSubject.string("hi"))
        XCTAssertEqual(EnumSubject.tuple(1, "hi"), EnumSubject.tuple(1, "hi"))
        XCTAssertEqual(EnumSubject.optionalTuple(nil), EnumSubject.optionalTuple(nil))
        XCTAssertEqual(EnumSubject.optionalTuple((1, "hi")), EnumSubject.optionalTuple((1, "hi")))
        
        XCTAssertEqual(EnumLabelTest.singleFirst(true), EnumLabelTest.singleFirst(true))
        XCTAssertEqual(EnumLabelTest.mixedLabelFirst(true, string: "hi"), EnumLabelTest.mixedLabelFirst(true, string: "hi"))
        XCTAssertEqual(EnumLabelTest.doubleLabelFirst(bool: true, string: "hi"), EnumLabelTest.doubleLabelFirst(bool: true, string: "hi"))
        
        XCTAssertNotEqual(EnumSubject.array(nil), EnumSubject.array([]))
        XCTAssertNotEqual(EnumSubject.array(nil), EnumSubject.array(["hi"]))
        XCTAssertNotEqual(EnumSubject.array(["hi"]), EnumSubject.array([]))
        XCTAssertNotEqual(EnumSubject.array(["hi"]), EnumSubject.array(["hi", "bye"]))
        XCTAssertNotEqual(EnumSubject.closure(nil), EnumSubject.closure({ _ in true }))
        XCTAssertNotEqual(EnumSubject.decimal(nil), EnumSubject.decimal(.greatestFiniteMagnitude))
        XCTAssertNotEqual(EnumSubject.decimal(.leastFiniteMagnitude), EnumSubject.decimal(.greatestFiniteMagnitude))
        XCTAssertNotEqual(EnumSubject.dictionary(nil), EnumSubject.dictionary([:]))
        XCTAssertNotEqual(EnumSubject.dictionary(nil), EnumSubject.dictionary([1: "Cool"]))
        XCTAssertNotEqual(EnumSubject.dictionary([:]), EnumSubject.dictionary([1: "Cool"]))
        XCTAssertNotEqual(EnumSubject.dictionary([1: "Cool"]), EnumSubject.dictionary([1: "Neat"]))
        XCTAssertNotEqual(EnumSubject.dictionary([1: "Cool"]), EnumSubject.dictionary([2: "Cool"]))
        XCTAssertNotEqual(EnumSubject.dictionary([1: "Cool"]), EnumSubject.dictionary([1: "Cool", 2: "Neat"]))
        XCTAssertNotEqual(EnumSubject.dictionary([1: "Cool", 3: "Neat"]), EnumSubject.dictionary([1: "Cool", 2: "Neat"]))
        XCTAssertNotEqual(EnumSubject.double(nil), EnumSubject.double(.greatestFiniteMagnitude))
        XCTAssertNotEqual(EnumSubject.double(.leastNormalMagnitude), EnumSubject.double(.greatestFiniteMagnitude))
        XCTAssertNotEqual(EnumSubject.float(nil), EnumSubject.float(.greatestFiniteMagnitude))
        XCTAssertNotEqual(EnumSubject.float(.leastNormalMagnitude), EnumSubject.float(.greatestFiniteMagnitude))
        XCTAssertNotEqual(EnumSubject.int(nil), EnumSubject.int(.max))
        XCTAssertNotEqual(EnumSubject.int(.min), EnumSubject.int(.max))
        XCTAssertNotEqual(EnumSubject.int64(nil), EnumSubject.int64(.max))
        XCTAssertNotEqual(EnumSubject.int64(.min), EnumSubject.int64(.max))
        XCTAssertNotEqual(EnumSubject.error(NSError(domain: "foo", code: -1)), EnumSubject.error(NSError(domain: "bar", code: -1)))
        XCTAssertNotEqual(EnumSubject.error(NSError(domain: "foo", code: -1)), EnumSubject.error(NSError(domain: "foo", code: -2)))
        XCTAssertNotEqual(EnumSubject.nestedEnum(nil), EnumSubject.nestedEnum(.bool(true)))
        XCTAssertNotEqual(EnumSubject.nestedEnum(.bool(true)), EnumSubject.nestedEnum(.bool(false)))
        XCTAssertNotEqual(EnumSubject.nestedEnum(.nestedEnum(nil)), EnumSubject.nestedEnum(.nestedEnum(.bool(true))))
        XCTAssertNotEqual(EnumSubject.nestedEnum(.nestedEnum(.bool(false))), EnumSubject.nestedEnum(.nestedEnum(.bool(true))))
        XCTAssertNotEqual(EnumSubject.string(nil), EnumSubject.string("hi"))
        XCTAssertNotEqual(EnumSubject.string("hi"), EnumSubject.string("bye"))
        XCTAssertNotEqual(EnumSubject.tuple(1, "hi"), EnumSubject.tuple(2, "hi"))
        XCTAssertNotEqual(EnumSubject.tuple(1, "hi"), EnumSubject.tuple(1, "bye"))
        XCTAssertNotEqual(EnumSubject.optionalTuple(nil), EnumSubject.optionalTuple((1, "hi")))
        XCTAssertNotEqual(EnumSubject.optionalTuple((1, "hi")), EnumSubject.optionalTuple((2, "hi")))
        XCTAssertNotEqual(EnumSubject.optionalTuple((1, "hi")), EnumSubject.optionalTuple((1, "bye")))
        
        XCTAssertNotEqual(EnumSubject.array(["h", "i"]), EnumSubject.string("hi"))
        XCTAssertNotEqual(EnumLabelTest.singleFirst(true), EnumLabelTest.singleSecond(true))
        XCTAssertNotEqual(EnumLabelTest.mixedLabelFirst(true, string: "hi"), EnumLabelTest.mixedLabelSecond(true, string: "hi"))
        XCTAssertNotEqual(EnumLabelTest.doubleLabelFirst(bool: true, string: "hi"), EnumLabelTest.doubleLabelSecond(bool: true, string: "hi"))
    }
    
    func testClass() {
        XCTAssertEqual(EmptyClassSubject(), EmptyClassSubject())
        let left = ClassSubject()
        let right = ClassSubject()
        
        XCTAssertEqual(left, right)
        left.array = ["hi"]
        XCTAssertNotEqual(left, right)
        right.array = ["hi", "bye"]
        XCTAssertNotEqual(left, right)
        right.array = ["hi"]
        XCTAssertEqual(left, right)
        
        left.bool = true
        XCTAssertNotEqual(left, right)
        right.bool = false
        XCTAssertNotEqual(left, right)
        right.bool = true
        XCTAssertEqual(left, right)
        
        left.closure = { _ in true }
        XCTAssertNotEqual(left, right)
        right.closure = { _ in true }
        XCTAssertEqual(left, right)
        
        left.decimal = .greatestFiniteMagnitude
        XCTAssertNotEqual(left, right)
        right.decimal = .leastNormalMagnitude
        XCTAssertNotEqual(left, right)
        right.decimal = .greatestFiniteMagnitude
        XCTAssertEqual(left, right)
        
        left.dictionary = [1: "hi", 2: "bye"]
        XCTAssertNotEqual(left, right)
        right.dictionary = [:]
        XCTAssertNotEqual(left, right)
        right.dictionary = [1: "bye"]
        XCTAssertNotEqual(left, right)
        right.dictionary = [2: "hi"]
        XCTAssertNotEqual(left, right)
        right.dictionary = [2: "hi", 1: "hi"]
        XCTAssertNotEqual(left, right)
        right.dictionary = [2: "bye", 1: "hi"]
        XCTAssertEqual(left, right)
        
        left.double = .greatestFiniteMagnitude
        XCTAssertNotEqual(left, right)
        right.double = .leastNormalMagnitude
        XCTAssertNotEqual(left, right)
        right.double = .greatestFiniteMagnitude
        XCTAssertEqual(left, right)
        
        left.float = .greatestFiniteMagnitude
        XCTAssertNotEqual(left, right)
        right.float = .leastNormalMagnitude
        XCTAssertNotEqual(left, right)
        right.float = .greatestFiniteMagnitude
        XCTAssertEqual(left, right)
        
        left.int = .max
        XCTAssertNotEqual(left, right)
        right.int = .min
        XCTAssertNotEqual(left, right)
        right.int = .max
        XCTAssertEqual(left, right)
        
        left.int64 = .max
        XCTAssertNotEqual(left, right)
        right.int64 = .min
        XCTAssertNotEqual(left, right)
        right.int64 = .max
        XCTAssertEqual(left, right)
        
        left.error = NSError(domain: "foo", code: -1)
        XCTAssertNotEqual(left, right)
        right.error = NSError(domain: "bar", code: -1)
        XCTAssertNotEqual(left, right)
        right.error = NSError(domain: "foo", code: -1)
        XCTAssertEqual(left, right)
                
        left.nestedClass = .init()
        left.nestedClass?.string = "hi"
        XCTAssertNotEqual(left, right)
        right.nestedClass = .init()
        XCTAssertNotEqual(left, right)
        right.nestedClass?.string = "bye"
        XCTAssertNotEqual(left, right)
        right.nestedClass?.string = "hi"
        XCTAssertEqual(left, right)
        
        left.nestedEnum = .string("hi")
        XCTAssertNotEqual(left, right)
        right.nestedEnum = .string(nil)
        XCTAssertNotEqual(left, right)
        right.nestedEnum = .string("bye")
        XCTAssertNotEqual(left, right)
        right.nestedEnum = .string("hi")
        XCTAssertEqual(left, right)
        
        left.nestedStruct = .init(string: "hi")
        XCTAssertNotEqual(left, right)
        right.nestedStruct = .init()
        XCTAssertNotEqual(left, right)
        right.nestedStruct?.string = "bye"
        XCTAssertNotEqual(left, right)
        right.nestedStruct?.string = "hi"
        XCTAssertEqual(left, right)
        
        left.string = "hi"
        XCTAssertNotEqual(left, right)
        right.string = "bye"
        XCTAssertNotEqual(left, right)
        right.string = "hi"
        XCTAssertEqual(left, right)
        
        left.tuple = (1, "hi")
        XCTAssertNotEqual(left, right)
        right.tuple = (1, "bye")
        XCTAssertNotEqual(left, right)
        right.tuple = (2, "hi")
        XCTAssertNotEqual(left, right)
        right.tuple = (1, "hi")
        XCTAssertEqual(left, right)
    }
    
    func testSubclass() {
        let left = SubClassSubject()
        let right = SubClassSubject()
        XCTAssertEqual(left, right)
        left.subclass = true
        left.string = "hi"
        XCTAssertNotEqual(left, right)
        right.subclass = false
        XCTAssertNotEqual(left, right)
        right.subclass = true
        XCTAssertNotEqual(left, right)
        right.string = "bye"
        XCTAssertNotEqual(left, right)
        right.string = "hi"
        XCTAssertEqual(left, right)
    }
    
    func testStruct() {
        XCTAssertEqual(EmptyStructSubject(), EmptyStructSubject())
        var left = StructSubject()
        var right = StructSubject()
        
        XCTAssertEqual(left, right)
        left.array = ["hi"]
        XCTAssertNotEqual(left, right)
        right.array = ["hi", "bye"]
        XCTAssertNotEqual(left, right)
        right.array = ["hi"]
        XCTAssertEqual(left, right)
        
        left.bool = true
        XCTAssertNotEqual(left, right)
        right.bool = false
        XCTAssertNotEqual(left, right)
        right.bool = true
        XCTAssertEqual(left, right)
        
        left.closure = { _ in true }
        XCTAssertNotEqual(left, right)
        right.closure = { _ in true }
        XCTAssertEqual(left, right)
        
        left.decimal = .greatestFiniteMagnitude
        XCTAssertNotEqual(left, right)
        right.decimal = .leastNormalMagnitude
        XCTAssertNotEqual(left, right)
        right.decimal = .greatestFiniteMagnitude
        XCTAssertEqual(left, right)
        
        left.dictionary = [1: "hi", 2: "bye"]
        XCTAssertNotEqual(left, right)
        right.dictionary = [:]
        XCTAssertNotEqual(left, right)
        right.dictionary = [1: "bye"]
        XCTAssertNotEqual(left, right)
        right.dictionary = [2: "hi"]
        XCTAssertNotEqual(left, right)
        right.dictionary = [2: "hi", 1: "hi"]
        XCTAssertNotEqual(left, right)
        right.dictionary = [2: "bye", 1: "hi"]
        XCTAssertEqual(left, right)
        
        left.double = .greatestFiniteMagnitude
        XCTAssertNotEqual(left, right)
        right.double = .leastNormalMagnitude
        XCTAssertNotEqual(left, right)
        right.double = .greatestFiniteMagnitude
        XCTAssertEqual(left, right)
        
        left.float = .greatestFiniteMagnitude
        XCTAssertNotEqual(left, right)
        right.float = .leastNormalMagnitude
        XCTAssertNotEqual(left, right)
        right.float = .greatestFiniteMagnitude
        XCTAssertEqual(left, right)
        
        left.int = .max
        XCTAssertNotEqual(left, right)
        right.int = .min
        XCTAssertNotEqual(left, right)
        right.int = .max
        XCTAssertEqual(left, right)
        
        left.int64 = .max
        XCTAssertNotEqual(left, right)
        right.int64 = .min
        XCTAssertNotEqual(left, right)
        right.int64 = .max
        XCTAssertEqual(left, right)
        
        left.error = NSError(domain: "foo", code: -1)
        XCTAssertNotEqual(left, right)
        right.error = NSError(domain: "bar", code: -1)
        XCTAssertNotEqual(left, right)
        right.error = NSError(domain: "foo", code: -1)
        XCTAssertEqual(left, right)
                
        left.nestedClass = .init()
        left.nestedClass?.string = "hi"
        XCTAssertNotEqual(left, right)
        right.nestedClass = .init()
        XCTAssertNotEqual(left, right)
        right.nestedClass?.string = "bye"
        XCTAssertNotEqual(left, right)
        right.nestedClass?.string = "hi"
        XCTAssertEqual(left, right)
        
        left.nestedEnum = .string("hi")
        XCTAssertNotEqual(left, right)
        right.nestedEnum = .string(nil)
        XCTAssertNotEqual(left, right)
        right.nestedEnum = .string("bye")
        XCTAssertNotEqual(left, right)
        right.nestedEnum = .string("hi")
        XCTAssertEqual(left, right)
        
        left.nestedStruct = .init(bool: true)
        XCTAssertNotEqual(left, right)
        right.nestedStruct = .init()
        XCTAssertNotEqual(left, right)
        right.nestedStruct?.bool = false
        XCTAssertNotEqual(left, right)
        right.nestedStruct?.bool = true
        XCTAssertEqual(left, right)
        
        left.string = "hi"
        XCTAssertNotEqual(left, right)
        right.string = "bye"
        XCTAssertNotEqual(left, right)
        right.string = "hi"
        XCTAssertEqual(left, right)
        
        left.tuple = (1, "hi")
        XCTAssertNotEqual(left, right)
        right.tuple = (1, "bye")
        XCTAssertNotEqual(left, right)
        right.tuple = (2, "hi")
        XCTAssertNotEqual(left, right)
        right.tuple = (1, "hi")
        XCTAssertEqual(left, right)
    }
    
    func testEquatableConflict() {
        XCTAssertNotEqual(EquatableConflictSubject(), EquatableConflictSubject())
        
        // This is an example of why this can be dangerous. It cannot know if a child is equatable, since Mirror doesn't support reflecting static functions yet, and Equatable is generic (associated types)
        XCTExpectFailure("The following fails because static functions are not supported with mirroring")
        XCTAssertNotEqual(NestedEquatableConflict(conflict: EquatableConflictSubject()), NestedEquatableConflict(conflict: EquatableConflictSubject()))
    }

    func testEnumDebugDescription() {
        XCTAssertEqual(EnumSubject.compare(lhs: nil, rhs: .array(["hi"])).debugDescription, "Optional<EnumSubject>: nil is not equal to array(Optional([\"hi\"]))")
        XCTAssertEqual(EnumSubject.compare(lhs: .array(nil), rhs: .array(["hi"])).debugDescription, "EnumSubject.array: nil is not equal to [\"hi\"]")
        XCTAssertEqual(EnumSubject.compare(lhs: .nestedEnum(.double(1.0)), rhs: .array(["hi"])).debugDescription, "EnumSubject: nestedEnum is not equal to array")
        XCTAssertEqual(EnumSubject.compare(lhs: .nestedEnum(.double(1.0)), rhs: .nestedEnum(.double(2.0))).debugDescription, "EnumSubject.nestedEnum.double: 1.0 is not equal to 2.0")
        
        // Testing debug descriptions with non-optional types
        enum Foo: AutomaticallyEquatable {
            case bar
            case baz(qux: String)
        }
        XCTAssertEqual(Foo.compare(lhs: .bar, rhs: .baz(qux: "quux")).debugDescription, "Foo: bar is not equal to baz(qux: \"quux\")")
        XCTAssertEqual(Foo.compare(lhs: .baz(qux: "corge"), rhs: .baz(qux: "quux")).debugDescription, "Foo.baz.qux: corge is not equal to quux")
    }
    
    func testStructCollectionDebugDescription() {
        // Count mismatch
        let person1 = PersonStruct(name: "Foo", relationships: [])
        let person2 = PersonStruct(name: "Bar", relationships: [])
        let person3 = PersonStruct(name: "Baz", relationships: [.father(person1), .mother(person2)])
        let person4 = PersonStruct(name: "Baz", relationships: [.father(person1)])
        
        // control
        XCTAssertEqual(person3, person3)
        
        // Collection count mismatch
        XCTAssertEqual(PersonStruct.compare(lhs: person3, rhs: person4).debugDescription, "PersonStruct.relationships.1: mother(TestableCombinePublishersTests.PersonStruct(name: \"Bar\", relationships: [])) is not equal to nil")
        
        // Collection count mismatch reverse
        XCTAssertEqual(PersonStruct.compare(lhs: person4, rhs: person3).debugDescription, "PersonStruct.relationships.1: nil is not equal to mother(TestableCombinePublishersTests.PersonStruct(name: \"Bar\", relationships: []))")
        
        // Collection item mismatch
        let person5 = PersonStruct(name: "Baz", relationships: [.father(person1), .father(person1)])
        XCTAssertEqual(PersonStruct.compare(lhs: person3, rhs: person5).debugDescription, "PersonStruct.relationships.1: mother is not equal to father")
    }
    
    func testClassDictionaryDebugDescription() {
        let person1 = PersonClass(name: "Foo", relationships: [:])
        let person2 = PersonClass(name: "Bar", relationships: [:])
        let person3 = PersonClass(name: "Baz", relationships: ["father": person1, "mother": person2])

        // control
        let person4 = PersonClass(name: "Baz", relationships: ["father": person1, "mother": person2])
        XCTAssertEqual(person3, person4)

        // Dictionary count mismatch
        let person5 = PersonClass(name: "Baz", relationships: ["father": person1])
        XCTAssertEqual(PersonClass.compare(lhs: person3, rhs: person5).debugDescription, "PersonClass.relationships.mother: TestableCombinePublishersTests.PersonClass is not equal to nil")
        
        // Dictionary count mismatch reverse
        XCTAssertEqual(PersonClass.compare(lhs: person5, rhs: person3).debugDescription, "PersonClass.relationships.mother: nil is not equal to TestableCombinePublishersTests.PersonClass")

        // Dictionary key mismatch
        let person6 = PersonClass(name: "Baz", relationships: ["father": person1, "sister": person2])
        XCTAssertEqual(PersonClass.compare(lhs: person3, rhs: person6).debugDescription, "PersonClass.relationships.mother: TestableCombinePublishersTests.PersonClass is not equal to nil")

        // Dictionary value mismatch
        let person7 = PersonClass(name: "Baz", relationships: ["father": person1, "mother": person1])
        XCTAssertEqual(PersonClass.compare(lhs: person3, rhs: person7).debugDescription, "PersonClass.relationships.mother.name: Bar is not equal to Foo")
    }
    
    func testDirectlyRecursiveObjects() {
        let selfReferencePerson = RecursivePerson(name: "Foo")
        selfReferencePerson.parent = selfReferencePerson
        XCTAssertEqual(selfReferencePerson, selfReferencePerson)
    }
    
    func testIndirectlyRecursiveObjects() {
        let parent = RecursivePerson(name: "Foo")
        let child = RecursivePerson(name: "Bar", parent: parent)
        parent.child = child
        XCTAssertEqual(parent, parent)
        XCTAssertNotEqual(parent, child)
    }
    
    func testNestedIndirectlyRecursiveObjects() {
        let parent = RecursivePerson(name: "Foo")
        let child = RecursivePerson(name: "Bar", parent: parent)
        parent.child = child
        let container1 = RecursivePersonContainer(person1: parent, person2: child)
        var container2 = RecursivePersonContainer(person1: parent, person2: child)
        XCTAssertEqual(container1, container2)
        container2 = RecursivePersonContainer(person1: parent, person2: parent)
        XCTAssertNotEqual(container1, container2)
    }
}

struct NestedEquatableConflict: AutomaticallyEquatable {
    var conflict: EquatableConflictSubject?
}

final class EquatableConflictSubject: Equatable {
    static func == (lhs: EquatableConflictSubject, rhs: EquatableConflictSubject) -> Bool {
        return false
    }
}
extension EquatableConflictSubject: AutomaticallyEquatable { }

indirect enum EnumSubject: AutomaticallyEquatable {
    case noAssociatedValue
    case bool(Bool?)
    case string(String?)
    case int(Int?)
    case int64(Int64?)
    case error(Error)
    case float(Float?)
    case double(Double?)
    case decimal(Decimal?)
    case array([String]?)
    case dictionary([Int: String]?)
    case nestedEnum(EnumSubject?)
    case tuple(Int, String)
    case optionalTuple((Int, String)?)
    case closure(((String) -> Bool)?)
}

struct EmptyStructSubject: AutomaticallyEquatable { }

struct StructSubject: AutomaticallyEquatable {
    var bool: Bool?
    var string: String?
    var int: Int?
    var int64: Int64?
    var float: Float?
    var double: Double?
    var decimal: Decimal?
    var array: [String]?
    var dictionary: [Int: String]?
    var nestedEnum: EnumSubject?
    var nestedClass: ClassSubject?
    var nestedStruct: InnerStruct?
    var tuple: (Int, String)?
    var closure: ((String) -> Bool)?
    var error: Error?
    
    struct InnerStruct {
        var bool: Bool?
    }
}

final class EmptyClassSubject: AutomaticallyEquatable { }

open class ClassSubject: AutomaticallyEquatable {
    var bool: Bool?
    var string: String?
    var int: Int?
    var int64: Int64?
    var float: Float?
    var double: Double?
    var decimal: Decimal?
    var array: [String]?
    var dictionary: [Int: String]?
    var nestedEnum: EnumSubject?
    var nestedClass: ClassSubject?
    var nestedStruct: StructSubject?
    var tuple: (Int, String)?
    var closure: ((String) -> Bool)?
    var error: Error?
}

final class SubClassSubject: ClassSubject {
    var subclass: Bool?
}

enum EnumLabelTest: AutomaticallyEquatable {
    case singleFirst(Bool)
    case singleSecond(Bool)
    case mixedLabelFirst(Bool, string: String)
    case mixedLabelSecond(Bool, string: String)
    case doubleLabelFirst(bool: Bool, string: String)
    case doubleLabelSecond(bool: Bool, string: String)
}


class PersonClass: AutomaticallyEquatable {
    var name: String
    var relationships: [String: PersonClass]
    
    internal init(name: String, relationships: [String : PersonClass]) {
        self.name = name
        self.relationships = relationships
    }
}

struct PersonStruct: AutomaticallyEquatable {
    var name: String
    var relationships: [Relationship]
    
    enum Relationship: AutomaticallyEquatable {
        case mother(PersonStruct)
        case father(PersonStruct)
    }
}

class RecursivePerson: AutomaticallyEquatable {
    var name: String
    var parent: RecursivePerson?
    var child: RecursivePerson?
    
    init(name: String, parent: RecursivePerson? = nil, child: RecursivePerson? = nil) {
        self.name = name
        self.parent = parent
        self.child = child
    }
}
struct RecursivePersonContainer: AutomaticallyEquatable {
    var person1: RecursivePerson
    var person2: RecursivePerson
}
