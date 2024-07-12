//
//  GeneratePBMacro.swift
//  
//
//  Created by Akivili Collindort on 2024/7/12.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftParser
import Foundation

public struct GeneratePBMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let decl = declaration.as(StructDeclSyntax.self)!
        let name = String(decl.name.text.dropFirst(2))
        let members = decl.memberBlock.members.map {
            $0.decl.as(VariableDeclSyntax.self)!
        }
        return try [] + makeResult(name, for: members, in: context)
    }
    
    static func makeResult(
        _ name: String,
        for members: [VariableDeclSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return try [
            makeBase(name, for: members, in: context)
        ]
    }
    
    static func makeBase(
        _ name: String,
        for members: [VariableDeclSyntax],
        in context: some MacroExpansionContext
    ) throws -> DeclSyntax {
        var memberBlock =  [DeclSyntax]()
        for member in members {
            guard let binding = member.bindings.first else {
                throw Errors.arbitrary("1") // TODO: error
            }
            
            if member.attributes.contains(where: { attribute in
                attribute.as(AttributeSyntax.self)?.attributeName.description == "Optional"
            }) {
                // Optional members
                let name = binding.pattern.description
                guard let type = binding.typeAnnotation?.type.as(OptionalTypeSyntax.self)?.wrappedType.description else {
                    throw Errors.arbitrary("2") // TODO: error
                }
                
                memberBlock.append("""
                var \(raw: name): \(raw: type) {
                    get { self._\(raw: name) ?? .init() }
                    set { self._\(raw: name) = newValue }
                }
                """)
                memberBlock.append("var _\(raw: name): \(raw: type)? = nil")
                let camelName = name.prefix(1).uppercased() + name.dropFirst()
                memberBlock.append("var has\(raw: camelName): Bool { return self._\(raw: name) != nil }")
                memberBlock.append("mutating func clear\(raw: camelName)() { self._\(raw: name) = nil }")
            } else {
                // Regular members
                memberBlock.append("var \(raw: binding.description) = .init()")
            }
            
        }
        memberBlock.append("var unknownFields = SwiftProtobuf.UnknownStorage()")
        memberBlock.append("init() {}")
        memberBlock.append("static let protoMessageName: String = \(literal: name)")
        try memberBlock.append(makeProtobufNameMapDecl(for: members, in: context))
        try memberBlock.append(makeDecodeMessageFunction(for: members, in: context))
        try memberBlock.append(makeTraverseFunction(for: members, in: context))
        try memberBlock.append(makeEuqtableConformance(for: members, in: context))
        let structure = StructDeclSyntax(
            attributes: "@_ProtobufResult",
            name: "PB\(raw: name)",
            inheritanceClause: InheritanceClauseSyntax {
                InheritedTypeSyntax(type: IdentifierTypeSyntax(name: "Sendable"))
            },
            memberBlock: MemberBlockSyntax(
                members: MemberBlockItemListSyntax(
                    memberBlock.map { MemberBlockItemSyntax(decl: $0) }
                )
            )
        )
        return DeclSyntax(structure)
    }
    
    static func makeProtobufNameMapDecl(for members: [VariableDeclSyntax], in context: some MacroExpansionContext) throws -> DeclSyntax {
        var memberBlock = [DictionaryElementSyntax]()
        
        for member in members {
            guard let identifierAttribute = member.attributes.first(where: { attribute in
                attribute.as(AttributeSyntax.self)?.attributeName.description == "Identifier"
            }) else {
                return "" // TODO: error
            }
            
            guard let id = identifierAttribute.as(AttributeSyntax.self)!.arguments?.as(LabeledExprListSyntax.self)?.first?.description else {
                throw Errors.arbitrary("Missing argument.")
            }
            
            let identifier = Int(id)!
            
            guard let name = member.bindings.first?.pattern.description else {
                throw Errors.arbitrary("No identifier in this member.")
            }
            
            // if the name is all lowercased, then use same name,
            // otherwise convert to snake case.
            if StringProcessor.assertAllLowercase(name) {
                memberBlock.append(
                    DictionaryElementSyntax(
                        key: IntegerLiteralExprSyntax(identifier),
                        value: FunctionCallExprSyntax(
                            calledExpression: MemberAccessExprSyntax(
                                declName: DeclReferenceExprSyntax(baseName: "same")
                            ),
                            leftParen: .leftParenToken(),
                            arguments: LabeledExprListSyntax{
                                LabeledExprSyntax(
                                    label: .identifier("proto"),
                                    colon: .colonToken(),
                                    expression: StringLiteralExprSyntax(content: name)
                                )
                            },
                            rightParen: .rightParenToken()
                        ),
                        trailingComma: .commaToken()
                    )
                )
            } else {
                let snakeName = StringProcessor.asSnakeCase(name)
                memberBlock.append(
                    DictionaryElementSyntax(
                        key: IntegerLiteralExprSyntax(identifier),
                        value: FunctionCallExprSyntax(
                            calledExpression: MemberAccessExprSyntax(
                                declName: DeclReferenceExprSyntax(baseName: "standard")
                            ),
                            leftParen: .leftParenToken(),
                            arguments: LabeledExprListSyntax{
                                LabeledExprSyntax(
                                    label: .identifier("proto"),
                                    colon: .colonToken(),
                                    expression: StringLiteralExprSyntax(content: snakeName)
                                )
                            },
                            rightParen: .rightParenToken()
                        ),
                        trailingComma: .commaToken()
                    )
                )
            }
        }
        
        let namemap = VariableDeclSyntax(
            modifiers: DeclModifierListSyntax {
                DeclModifierSyntax(name: .keyword(.static))
            },
            bindingSpecifier: .keyword(.let),
            bindings: PatternBindingListSyntax {
                PatternBindingSyntax(
                    pattern: IdentifierPatternSyntax(
                        identifier: "_protobuf_nameMap"
                    ),
                    typeAnnotation: TypeAnnotationSyntax(
                        type: MemberTypeSyntax(
                            baseType: IdentifierTypeSyntax(name: "SwiftProtobuf"),
                            name: "_NameMap"
                        )
                    ),
                    initializer: InitializerClauseSyntax(
                        value: DictionaryExprSyntax(
                            content: .elements(
                                DictionaryElementListSyntax(
                                    memberBlock.map { member in
                                        member.mutate { syntax in
                                            syntax.leadingTrivia = .newline
                                        }
                                    }
                                )
                            ),
                            rightSquare: .rightSquareToken(leadingTrivia: .newline)
                        )
                    )
                )
            }
        )
        return DeclSyntax(namemap)
    }
    
    static func makeDecodeMessageFunction(for members: [VariableDeclSyntax], in context: some MacroExpansionContext) throws -> DeclSyntax {
        var cases = [SwitchCaseSyntax]()
        
        for member in members {
            guard let identifierAttribute = member.attributes.first(where: { attribute in
                attribute.as(AttributeSyntax.self)?.attributeName.description == "Identifier"
            }) else {
                throw Errors.arbitrary("Missing argument.") // TODO: error
            }
            
            guard let id = identifierAttribute.as(AttributeSyntax.self)!.arguments?.as(LabeledExprListSyntax.self)?.first?.description else {
                throw Errors.arbitrary("Missing argument.")
            }
            
            guard let name = member.bindings.first?.pattern.description else {
                throw Errors.arbitrary("No identifier in this member.")
            }
            
            if member.attributes.contains(where: { attribute in
                attribute.as(AttributeSyntax.self)?.attributeName.description == "Optional"
            }) {
                // optional
                if cases.isEmpty {
                    cases.append("case \(raw: id): try decoder.decodeSingularStringField(value: &self._\(raw: name))")
                } else {
                    cases.append("\ncase \(raw: id): try decoder.decodeSingularStringField(value: &self._\(raw: name))")
                }
            } else {
                // regular
                if cases.isEmpty {
                    cases.append("case \(raw: id): try decoder.decodeSingularStringField(value: &self.\(raw: name))")
                } else {
                    cases.append("\ncase \(raw: id): try decoder.decodeSingularStringField(value: &self.\(raw: name))")
                }
            }
        }
        cases.append("\ndefault: break")
        
        let list = SwitchCaseListSyntax(cases.map { .switchCase($0) })
        
        let body: CodeBlockItemSyntax = """
        while let fieldNumber = try decoder.nextFieldNumber() {
            switch fieldNumber {
                \(list)
            }
        }
        """
        
        // construct function
        let function = FunctionDeclSyntax(
            modifiers: DeclModifierListSyntax {
                DeclModifierSyntax(name: .keyword(.mutating), trailingTrivia: .space)
            },
            funcKeyword: .keyword(.func, trailingTrivia: .space),
            name: "decodeMessage",
            genericParameterClause: GenericParameterClauseSyntax(
                parameters: GenericParameterListSyntax {
                    GenericParameterSyntax(
                        name: "D",
                        colon: .colonToken(),
                        inheritedType: MemberTypeSyntax(baseType: IdentifierTypeSyntax(name: "SwiftProtobuf"), name: "Decoder")
                    )
                }
            ),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax {
                        "decoder: inout D"
                    }
                ),
                effectSpecifiers: FunctionEffectSpecifiersSyntax(
                    throwsSpecifier: .keyword(
                        .throws,
                        leadingTrivia: .space,
                        trailingTrivia: .space
                    )
                )
            ),
            body: CodeBlockSyntax(
                statements: CodeBlockItemListSyntax(
                    arrayLiteral: body.mutate { syntax in
                        syntax.leadingTrivia = .newline
                    }
                )
            )
        )
        return DeclSyntax(function)
    }
    
    static func makeTraverseFunction(for members: [VariableDeclSyntax], in context: some MacroExpansionContext) throws -> DeclSyntax {
        var codes = [CodeBlockItemSyntax]()
        
        for member in members {
            guard let identifierAttribute = member.attributes.first(where: { attribute in
                attribute.as(AttributeSyntax.self)?.attributeName.description == "Identifier"
            }) else {
                throw Errors.arbitrary("Missing argument.") // TODO: error
            }
            
            guard let id = identifierAttribute.as(AttributeSyntax.self)!.arguments?.as(LabeledExprListSyntax.self)?.first?.description else {
                throw Errors.arbitrary("Missing argument.")
            }
            
            guard let name = member.bindings.first?.pattern.description else {
                throw Errors.arbitrary("No identifier in this member.")
            }
            
            if member.attributes.contains(where: { attribute in
                attribute.as(AttributeSyntax.self)?.attributeName.description == "Optional"
            }) {
                // optional
                codes.append(
                    """
                    try{ if let v = self._\(raw: name) {
                        if v != .init() {
                            try visitor.visitSingularStringField(value: v, fieldNumber: \(raw: id))
                        }
                    }}
                    """
                )
                
            } else {
                // regular
                codes.append(
                    """
                    if self.\(raw: name) != .init() {
                        try visitor.visitSingularStringField(value: self.\(raw: name), fieldNumber: \(raw: id))
                    }
                    """
                )
            }
        }
        
        codes.append("try unknownFields.traverse(visitor: &visitor)")
        
        let list = CodeBlockItemListSyntax(codes)
        
        // construct function
        let function = FunctionDeclSyntax(
            name: "traverse",
            genericParameterClause: GenericParameterClauseSyntax(
                parameters: GenericParameterListSyntax {
                    GenericParameterSyntax(
                        name: "V",
                        colon: .colonToken(),
                        inheritedType: MemberTypeSyntax(baseType: IdentifierTypeSyntax(name: "SwiftProtobuf"), name: "Visitor")
                    )
                }
            ),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax {
                        "visitor: inout V"
                    }
                ),
                effectSpecifiers: FunctionEffectSpecifiersSyntax(throwsSpecifier: .keyword(.throws))
            ),
            body: CodeBlockSyntax(
                statements: list
            )
        )
        return DeclSyntax(function)
    }
    
    static func makeEuqtableConformance(for members: [VariableDeclSyntax], in context: some MacroExpansionContext) throws -> DeclSyntax {
        var codes = [CodeBlockItemSyntax]()
        
        for member in members {
            guard let name = member.bindings.first?.pattern.description else {
                throw Errors.arbitrary("No identifier in this member.")
            }
            
            if member.attributes.contains(where: { attribute in
                attribute.as(AttributeSyntax.self)?.attributeName.description == "Optional"
            }) {
                // optional
                codes.append(
                    """
                    if lhs._\(raw: name) != rhs._\(raw: name) { return false }
                    """
                )
                
            } else {
                // regular
                codes.append(
                    """
                    if lhs.\(raw: name) != rhs.\(raw: name) { return false }
                    """
                )
            }
        }
        
        codes.append("if lhs.unknownFields != rhs.unknownFields { return false }")
        codes.append("return true")
        
        let list = CodeBlockItemListSyntax(codes)
        
        // construct function
        let function = FunctionDeclSyntax(
            modifiers: DeclModifierListSyntax {
                DeclModifierSyntax(name: .keyword(.static))
            },
            name: .binaryOperator("=="),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax {
                        "lhs: Self, "
                        "rhs: Self"
                    }
                ),
                returnClause: ReturnClauseSyntax(type: IdentifierTypeSyntax(name: "Bool"))
            ),
            body: CodeBlockSyntax(
                statements: list
            )
        )
        return DeclSyntax(function)
    }
}

public struct GenerationResultMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let decl = declaration.as(StructDeclSyntax.self)!
        let name = decl.name.text
        return try [makeExtension(name, in: context)]
    }
    
    static func makeExtension(
        _ name: String,
        in context: some MacroExpansionContext
    ) throws -> ExtensionDeclSyntax {
        let memberBlock = [DeclSyntax]()
        let extensionDecl = ExtensionDeclSyntax(
            extendedType: IdentifierTypeSyntax(name: .identifier(name)),
            inheritanceClause: InheritanceClauseSyntax(
                inheritedTypes: InheritedTypeListSyntax {
                    InheritedTypeSyntax(
                        type: MemberTypeSyntax(baseType: IdentifierTypeSyntax(name: "SwiftProtobuf"), name: "Message"),
                        trailingComma: .commaToken()
                    )
                    InheritedTypeSyntax(
                        type: MemberTypeSyntax(baseType: IdentifierTypeSyntax(name: "SwiftProtobuf"), name: "_MessageImplementationBase"),
                        trailingComma: .commaToken()
                    )
                    InheritedTypeSyntax(
                        type: MemberTypeSyntax(baseType: IdentifierTypeSyntax(name: "SwiftProtobuf"), name: "_ProtoNameProviding")
                    )
                }
            ),
            memberBlock: MemberBlockSyntax(
                members: MemberBlockItemListSyntax(
                    memberBlock.map { MemberBlockItemSyntax(decl: $0) }
                )
            )
        )
        return extensionDecl
    }
}

extension GeneratePBMacro {
    private struct StringProcessor {
        static func assertAllLowercase(_ string: String) -> Bool {
            for character in string {
                if character.isUppercase { return false }
            }
            return true
        }
        
        static func asSnakeCase(_ string: String) -> String {
            var snakeCaseString = ""
            
            for character in string {
                if character.isUppercase {
                    if !snakeCaseString.isEmpty {
                        snakeCaseString.append("_")
                    }
                    snakeCaseString.append(character.lowercased())
                } else {
                    snakeCaseString.append(character)
                }
            }
            
            return snakeCaseString
        }
    }
}
