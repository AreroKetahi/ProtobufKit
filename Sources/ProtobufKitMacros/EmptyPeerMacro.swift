//
//  EmptyPeerMacro.swift
//  
//
//  Created by Akivili Collindort on 2024/7/8.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct EmptyPeerMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}
