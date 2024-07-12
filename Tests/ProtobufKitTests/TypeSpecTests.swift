//
//  TypeTests.swift
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

final class ProtobufKitTypeSpecTests: XCTestCase {
    func testInt32() throws {
        assertMacroExpansion(
            """
            @ProtobufModel
            struct Test {
                var int32: Int32
            }
            """,
            expandedSource: """
            struct Test {
                var int32: Int32
            }
            
            @_ProtobufModel private struct _$Test {
                @Identifier(1)
                @Detail(.default)
                var int32: Int32
            }
            """,
            macros: ["ProtobufModel": ProtobufModelMacro.self]
        )
    }
    
    func testInt32WithDetail() throws {
        assertMacroExpansion(
            """
            @ProtobufModel
            struct Test {
                @Detail(.signed)
                var int32: Int32
            }
            """,
            expandedSource: """
            struct Test {
                @Detail(.signed)
                var int32: Int32
            }
            
            @_ProtobufModel private struct _$Test {
                @Detail(.signed)
                @Identifier(1)
                var int32: Int32
            }
            """,
            macros: ["ProtobufModel": ProtobufModelMacro.self]
        )
    }
    
    func testInt32WithInvalidDetail() throws {
        assertMacroExpansion(
            """
            @ProtobufModel
            struct Test {
                @Detail(.fixed)
                var int32: Int32
            }
            """,
            expandedSource: """
            struct Test {
                @Detail(.fixed)
                var int32: Int32
            }
            
            @_ProtobufModel private struct _$Test {
                @Detail(.fixed)
                @Identifier(1)
                var int32: Int32
            }
            """,
            diagnostics: [
                .init(message: "Can't apply parameter \"fixed\" to type Int32.", line: 3, column: 13),
            ],
            macros: ["ProtobufModel": ProtobufModelMacro.self]
        )
    }
    
    func testUInt32WithDetail() throws {
        assertMacroExpansion(
            """
            @ProtobufModel
            struct Test {
                @Detail(.fixed)
                var uint32: UInt32
            }
            """,
            expandedSource: """
            struct Test {
                @Detail(.fixed)
                var uint32: UInt32
            }
            
            @_ProtobufModel private struct _$Test {
                @Detail(.fixed)
                @Identifier(1)
                var uint32: UInt32
            }
            """,
            macros: ["ProtobufModel": ProtobufModelMacro.self]
        )
    }
    
    func testUInt32WithInvalidDetail() throws {
        assertMacroExpansion(
            """
            @ProtobufModel
            struct Test {
                @Detail(.signed)
                var uint32: UInt32
            }
            """,
            expandedSource: """
            struct Test {
                @Detail(.signed)
                var uint32: UInt32
            }
            
            @_ProtobufModel private struct _$Test {
                @Detail(.signed)
                @Identifier(1)
                var uint32: UInt32
            }
            """,
            diagnostics: [
                .init(message: "Can't apply parameter \"signed\" to type UInt32.", line: 3, column: 13),
            ],
            macros: ["ProtobufModel": ProtobufModelMacro.self]
        )
    }
    
    func testArray() throws {
        assertMacroExpansion(
            """
            @ProtobufModel
            struct Test {
                var array: [String]
            }
            """,
            expandedSource: """
            struct Test {
                var array: [String]
            }
            
            @_ProtobufModel private struct _$Test {
                @Identifier(1)
                var array: [String]
            }
            """,
            macros: ["ProtobufModel": ProtobufModelMacro.self]
        )
    }
    
    func testArrayRaw() throws {
        assertMacroExpansion(
            """
            @ProtobufModel
            struct Test {
                var arrayRaw: Array<String>
            }
            """,
            expandedSource: """
            struct Test {
                var arrayRaw: Array<String>
            }
            
            @_ProtobufModel private struct _$Test {
                @Identifier(1)
                var arrayRaw: Array<String>
            }
            """,
            macros: ["ProtobufModel": ProtobufModelMacro.self]
        )
    }
    
    func testDictionary() throws {
        assertMacroExpansion(
            """
            @ProtobufModel
            struct Test {
                var dict: [Int32: String]
            }
            """,
            expandedSource: """
            struct Test {
                var dict: [Int32: String]
            }
            
            @_ProtobufModel private struct _$Test {
                @Identifier(1)
                var dict: [Int32: String]
            }
            """,
            macros: ["ProtobufModel": ProtobufModelMacro.self]
        )
    }
    
    func testDictionaryWithUnavailableKey() throws {
        assertMacroExpansion(
            """
            @ProtobufModel
            struct Test {
                var dict: [Data: String]
            }
            """,
            expandedSource: """
            struct Test {
                var dict: [Data: String]
            }
            
            @_ProtobufModel private struct _$Test {
            }
            """,
            diagnostics: [
                .init(message: "\"Data\" cannot be used for a dictionary value type.", line: 3, column: 16)
            ],
            macros: ["ProtobufModel": ProtobufModelMacro.self]
        )
    }
    
    func testDictionaryRaw() throws {
        assertMacroExpansion(
            """
            @ProtobufModel
            struct Test {
                var dictRaw: Dictionary<Int32, String>
            }
            """,
            expandedSource: """
            struct Test {
                var dictRaw: Dictionary<Int32, String>
            }
            
            @_ProtobufModel private struct _$Test {
                @Identifier(1)
                var dictRaw: Dictionary<Int32, String>
            }
            """,
            macros: ["ProtobufModel": ProtobufModelMacro.self]
        )
    }
    
    func testOptional() throws {
        assertMacroExpansion(
            """
            @ProtobufModel
            struct Test {
                var optional: String?
            }
            """,
            expandedSource: """
            struct Test {
                var optional: String?
            }
            
            @_ProtobufModel private struct _$Test {
                @Optional
                @Identifier(1)
                var optional: String?
            }
            """,
            macros: ["ProtobufModel": ProtobufModelMacro.self]
        )
    }
}
