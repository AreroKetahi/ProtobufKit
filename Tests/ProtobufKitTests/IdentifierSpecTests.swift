//
//  IdentifierSpecTests.swift
//
//
//  Created by Akivili Collindort on 2024/7/8.
//

import SwiftSyntax
import ProtobufKitMacros
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class ProtobufKitIdentifierSpecTests: XCTestCase {
    func testReservedMacro() throws {
        assertMacroExpansion(
            """
            @ProtobufModel
            struct Test {
                #Reserved(1, 2, 3, 4, 7, 10)
                var string: String
            }
            """,
            expandedSource: """
            struct Test {
                #Reserved(1, 2, 3, 4, 7, 10)
                var string: String
            }
            
            @_ProtobufModel private struct _$Test {
                @Identifier(5)
                var string: String
            }
            """,
            macros: ["ProtobufModel": ProtobufModelMacro.self]
        )
    }
    
    func testMacroInDifferentStruct() throws {
        assertMacroExpansion(
            """
            @ProtobufModel
            struct Test1 {
                var string: String
            }
            
            @ProtobufModel
            struct Test2 {
                var string: String
            }
            """,
            expandedSource: """
            struct Test1 {
                var string: String
            }
            
            @_ProtobufModel private struct _$Test1 {
                @Identifier(1)
                var string: String
            }
            struct Test2 {
                var string: String
            }
            
            @_ProtobufModel private struct _$Test2 {
                @Identifier(1)
                var string: String
            }
            """,
            macros: ["ProtobufModel": ProtobufModelMacro.self]
        )
    }
    
    func testReservedMacroInDifferentStruct() throws {
        assertMacroExpansion(
            """
            @ProtobufModel
            struct Test1 {
                #Reserved(1, 2, 3, 4, 7, 10)
                var string: String
            }
            @ProtobufModel
            struct Test2 {
                #Reserved(1, 3, 5, 7, 9)
                var string: String
            }
            """,
            expandedSource: """
            struct Test1 {
                #Reserved(1, 2, 3, 4, 7, 10)
                var string: String
            }
            
            @_ProtobufModel private struct _$Test1 {
                @Identifier(5)
                var string: String
            }
            struct Test2 {
                #Reserved(1, 3, 5, 7, 9)
                var string: String
            }
            
            @_ProtobufModel private struct _$Test2 {
                @Identifier(2)
                var string: String
            }
            """,
            macros: ["ProtobufModel": ProtobufModelMacro.self]
        )
    }
}
