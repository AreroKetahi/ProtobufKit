//
//  EmptyExpressionMacro.swift
//  
//
//  Created by Akivili Collindort on 2024/7/8.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct EmptyExpressionMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        return ""
    }
}
