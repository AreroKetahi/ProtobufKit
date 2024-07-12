//
//  GenerationTests.swift
//  
//
//  Created by Akivili Collindort on 2024/7/12.
//

import SwiftSyntax
import ProtobufKitMacros
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class GenerationTests: XCTestCase {
    func testSecondaryGeneration() throws {
        assertMacroExpansion(
            """
            @_ProtobufModel private struct _$LibraryCard {
                @Identifier(1)
                var name: String
                @Identifier(2)
                @Detail(.default)
                var age: UInt32
                @Identifier(3)
                var isMember: Bool
                @Optional
                @Identifier(4)
                var uuid: Data?
                @Identifier(5)
                var charge: Float
                @Identifier(6)
                var borrowedBook: [String]
                @Identifier(7)
                var bookNumber: [String: String]
            }
            """,
            expandedSource: """
            private struct _$LibraryCard {
                @Identifier(1)
                var name: String
                @Identifier(2)
                @Detail(.default)
                var age: UInt32
                @Identifier(3)
                var isMember: Bool
                @Optional
                @Identifier(4)
                var uuid: Data?
                @Identifier(5)
                var charge: Float
                @Identifier(6)
                var borrowedBook: [String]
                @Identifier(7)
                var bookNumber: [String: String]
            }
            
            struct PBLibraryCard: Sendable {
                var name: String = .init()
                var age: UInt32 = .init()
                var isMember: Bool = .init()
                var uuid: Data {
                    get {
                        self._uuid ?? .init()
                    }
                    set {
                        self._uuid = newValue
                    }
                }
                var _uuid: Data? = nil
                var hasUuid: Bool {
                    return self._uuid != nil
                }
                mutating func clearUuid() {
                    self._uuid = nil
                }
                var charge: Float = .init()
                var borrowedBook: [String] = .init()
                var bookNumber: [String: String] = .init()
                var unknownFields = SwiftProtobuf.UnknownStorage()
                init() {
                }
                static let protoMessageName: String = "LibraryCard"
                static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
                    1: .same(proto: "name"),
                    2: .same(proto: "age"),
                    3: .standard(proto: "is_member"),
                    4: .same(proto: "uuid"),
                    5: .same(proto: "charge"),
                    6: .standard(proto: "borrowed_book"),
                    7: .standard(proto: "book_number"),
                ]
                mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
                    while let fieldNumber = try decoder.nextFieldNumber() {
                        switch fieldNumber {
                            case 1:
                            try decoder.decodeSingularStringField(value: &self.name)
                            case 2:
                            try decoder.decodeSingularStringField(value: &self.age)
                            case 3:
                            try decoder.decodeSingularStringField(value: &self.isMember)
                            case 4:
                            try decoder.decodeSingularStringField(value: &self._uuid)
                            case 5:
                            try decoder.decodeSingularStringField(value: &self.charge)
                            case 6:
                            try decoder.decodeSingularStringField(value: &self.borrowedBook)
                            case 7:
                            try decoder.decodeSingularStringField(value: &self.bookNumber)
                            default:
                            break
                        }
                    }
                }
                func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
                    if self.name != .init() {
                        try visitor.visitSingularStringField(value: self.name, fieldNumber: 1)
                    }
                    if self.age != .init() {
                        try visitor.visitSingularStringField(value: self.age, fieldNumber: 2)
                    }
                    if self.isMember != .init() {
                        try visitor.visitSingularStringField(value: self.isMember, fieldNumber: 3)
                    }
                    try {
                        if let v = self._uuid {
                            if v != .init() {
                                try visitor.visitSingularStringField(value: v, fieldNumber: 4)
                            }
                        }
                    }
                    if self.charge != .init() {
                        try visitor.visitSingularStringField(value: self.charge, fieldNumber: 5)
                    }
                    if self.borrowedBook != .init() {
                        try visitor.visitSingularStringField(value: self.borrowedBook, fieldNumber: 6)
                    }
                    if self.bookNumber != .init() {
                        try visitor.visitSingularStringField(value: self.bookNumber, fieldNumber: 7)
                    }
                    try unknownFields.traverse(visitor: &visitor)
                }
                static func == (lhs: Self, rhs: Self) -> Bool {
                    if lhs.name != rhs.name {
                        return false
                    }
                    if lhs.age != rhs.age {
                        return false
                    }
                    if lhs.isMember != rhs.isMember {
                        return false
                    }
                    if lhs._uuid != rhs._uuid {
                        return false
                    }
                    if lhs.charge != rhs.charge {
                        return false
                    }
                    if lhs.borrowedBook != rhs.borrowedBook {
                        return false
                    }
                    if lhs.bookNumber != rhs.bookNumber {
                        return false
                    }
                    if lhs.unknownFields != rhs.unknownFields {
                        return false
                    }
                    return true
                }
            }
            
            extension PBLibraryCard: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
            }
            """,
            macros: [
                "_ProtobufModel": GeneratePBMacro.self,
                "_ProtobufResult": GenerationResultMacro.self,
            ]
        )
    }
}
