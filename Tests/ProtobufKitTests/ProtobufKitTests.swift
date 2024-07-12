//
//  ProtobufKitTests.swift
//
//
//  Created by Akivili Collindort on 2024/7/7.
//

import SwiftSyntax
import ProtobufKitMacros
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class ProtobufKitTests: XCTestCase {
    func testDefault() throws {
        assertMacroExpansion(
            """
            @ProtobufModel
            struct LibraryCard {
                var name: String
                var age: UInt32
                var isMember: Bool
                var uuid: Data
                var charge: Float
                var borrowedBook: [String]
                var bookNumber: [String: String]
            }
            """,
            expandedSource: """
            struct LibraryCard {
                var name: String
                var age: UInt32
                var isMember: Bool
                var uuid: Data
                var charge: Float
                var borrowedBook: [String]
                var bookNumber: [String: String]
            }
            
            @_ProtobufModel private struct _$LibraryCard {
                @Identifier(1)
                var name: String
                @Identifier(2)
                @Detail(.default)
                var age: UInt32
                @Identifier(3)
                var isMember: Bool
                @Identifier(4)
                var uuid: Data
                @Identifier(5)
                var charge: Float
                @Identifier(6)
                var borrowedBook: [String]
                @Identifier(7)
                var bookNumber: [String: String]
            }
            """,
            macros: [
                "ProtobufModel": ProtobufModelMacro.self
            ]
        )
    }
}
