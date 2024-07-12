//
//  ProtobufModel.swift
//
//
//  Created by Akivili Collindort on 2024/7/7.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftParser

// MARK: Protocol Definition

private let availableType: [String?] = [
    "Int32", "UInt32",
    "Int64", "UInt64",
    "Bool", "Float", "Double", "String", "Data"
]

private let ruleReservedIdentifier = 19_000...19_999

// MARK: - Peer Generater
public struct ProtobufModelMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // expand as structure
        if let decl = declaration.as(StructDeclSyntax.self) {
            return try expandStructure(node, of: decl, in: context)
        }
        
        // expand as class
        if declaration.as(ClassDeclSyntax.self) != nil {
            throw Errors.classUnsupported
        }
        
        // throw an error if this macro does not attached correctly
        // on structure or class.
        return [] // TODO: error throwing
    }
    
    static func expandStructure(
        _ node: AttributeSyntax,
        of declaration: StructDeclSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let members = declaration.memberBlock.members
        
        let resultMembers = try transfromMember(use: members, in: context)
        
        let result = makeTemplate(
            structName: declaration.name,
            members: resultMembers
        )
        
        return try GeneratePBMacro.expansion(of: "@_ProtobufModel", providingPeersOf: result, in: context)
    }
    
    static func makeTemplate(structName: TokenSyntax, members: [VariableDeclSyntax]) -> DeclSyntax {
        var memberBlockParser = Parser("{\(members.map { $0.description }.joined())}")
        let structDecl = StructDeclSyntax(
            modifiers: .init(itemsBuilder: {
                .init(name: .keyword(.private))
            }),
            name: "_$\(raw: structName.text)",
            memberBlock: .parse(from: &memberBlockParser)
        )
        return .init(structDecl)
    }
}

// MARK: - transfromMember
extension ProtobufModelMacro {
    static func transfromMember(
        use members: MemberBlockItemListSyntax,
        in context: some MacroExpansionContext
    ) throws -> [VariableDeclSyntax] {
        // global variables
        var reservedIdentifier: [Int] = []
        var idCounting = 1
        var apparedIds = [Int]()
        // END / global variables
        
        var resultMembers = [VariableDeclSyntax]()
        
        // BEGIN
        for member in members {
            if let member = member.decl.as(VariableDeclSyntax.self) {
                // MARK: Type checking
                guard try checkTypeAvailability(for: member, in: context) else {
                    // throw an error for unavailable type.
                    throw Errors.arbitrary("Unavailable Type") // TODO: error
                }
                // transfrom member
                var transformedMember = member
                
                // add optional mark
                try addOptional(for: &transformedMember, basedOn: member, in: context)
                
                // add identifier if needed
                try addIdentifier(
                    for: &transformedMember,
                    basedOn: member,
                    in: context,
                    reserved: reservedIdentifier,
                    count: &idCounting,
                    usedStack: &apparedIds
                )
                
                // add numeric detail if needed
                try addNumericDetail(for: &transformedMember, basedOn: member, in: context)
                
                resultMembers.append(transformedMember)
            } else if let member = member.decl.as(MacroExpansionDeclSyntax.self) {
                // MARK: Resolve #Reserved macro
                if member.macroName.text == "Reserved" {
                    for argument in member.arguments {
                        guard let token = argument.expression.as(IntegerLiteralExprSyntax.self)?.literal.text else {
                            return [] // TODO: error handling / unexpected type
                        }
                        
                        guard let reservedId = Int(token) else {
                            return [] // TODO: error handling / incorrect parameter
                        }
                        
                        reservedIdentifier.append(reservedId)
                    }
                }
            }
        }
        // END
        
        return resultMembers
    }
    
    static func checkTypeAvailability(
        for member: VariableDeclSyntax,
        in context: some MacroExpansionContext,
        allowDictionaryNesting: Bool = true
    ) throws -> Bool {
        // TODO: check if the type is Array or Dictionary
        
        // array / repeated
        if let binding = member.bindings.first(where: { binding in
            binding.typeAnnotation?.type.as(ArrayTypeSyntax.self) != nil
        }) {
            let type = binding.typeAnnotation?.type.as(ArrayTypeSyntax.self)?.element
            return checkType(for: type)
        } else if let binding = member.bindings.first(where: { binding in
            binding.typeAnnotation?.type.as(IdentifierTypeSyntax.self)?.name.text == "Array"
        }) {
            let type = binding.typeAnnotation?.type.as(IdentifierTypeSyntax.self)?.genericArgumentClause?.arguments.first?.argument
            return checkType(for: type)
        }
        
        // dictionary / map
        if let binding = member.bindings.first(where: { binding in
            binding.typeAnnotation?.type.as(DictionaryTypeSyntax.self) != nil
        }) {
            let annotation = binding.typeAnnotation?.type.as(DictionaryTypeSyntax.self)
            let keyType = annotation?.key
            let valueType = annotation?.value
            
            guard checkType(for: keyType, dictionaryKeyMode: true) else {
                context.addDiagnostics(from: Errors.invalidKeyType(type: keyType!), node: keyType!)
                return false
            }
            return checkType(for: valueType)
        } else if let binding = member.bindings.first(where: { binding in
            binding.typeAnnotation?.type.as(IdentifierTypeSyntax.self)?.name.text == "Dictionary"
        }) {
            let arguments = binding.typeAnnotation?.type.as(IdentifierTypeSyntax.self)?.genericArgumentClause?.arguments.map {
                GenericArgumentSyntax($0)
            }
            
            let keyType = arguments?[0]?.argument
            let valueType = arguments?[1]?.argument
            
            guard checkType(for: keyType, dictionaryKeyMode: true) else {
                context.addDiagnostics(from: Errors.invalidKeyType(type: keyType!), node: keyType!)
                return false
            }
            return checkType(for: valueType)
        }
        
        // Optional
        if let binding = member.bindings.first(where: { binding in
            binding.typeAnnotation?.type.as(OptionalTypeSyntax.self) != nil
        }) {
            let type = binding.typeAnnotation?.type.as(OptionalTypeSyntax.self)?.wrappedType
            return checkType(for: type)
        }
        
        // rawValue
        return member.bindings.contains { binding in
            let type = binding.typeAnnotation?.type
            return checkType(for: type)
        }
    }
    
    static func checkType(for type: TypeSyntax?, dictionaryKeyMode: Bool = false) -> Bool {
        let typeIdentifier = type?.as(IdentifierTypeSyntax.self)?.name.text
        if dictionaryKeyMode {
            if ["Data", "Double", "Float"].contains(typeIdentifier) { return false }
        }
        return availableType.contains(typeIdentifier)
    }
}

// MARK: - addOptional
extension ProtobufModelMacro {
    static func addOptional(
        for transformedMember: inout VariableDeclSyntax,
        basedOn member: VariableDeclSyntax,
        in context: some MacroExpansionContext
    ) throws {
        if member.bindings.contains(where: { binding in
            binding.typeAnnotation?.type.as(OptionalTypeSyntax.self) != nil
        }) {
            var markParser = Parser("@Optional")
            var mark = AttributeSyntax.parse(from: &markParser) // parse
            let nestLevel = member.leadingTrivia.first { $0.isSpaceOrTab } ?? .spaces(0)
            mark.leadingTrivia = Trivia(pieces: [.newlines(1), nestLevel]) // add trivia
            transformedMember.attributes.append(.attribute(mark))
        }
    }
}

// MARK: - addIdentifier
extension ProtobufModelMacro {
    static func addIdentifier(
        for transformedMember: inout VariableDeclSyntax,
        basedOn member: VariableDeclSyntax,
        in context: some MacroExpansionContext,
        reserved reservedIdentifier: [Int],
        count idCounting: inout Int,
        usedStack appearedIds: inout [Int]
    ) throws {
        if let attribute = member.attributes.first(where: { attribute in
            guard let attriute = attribute.as(AttributeSyntax.self) else {
                return false
            }
            return attriute.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "Identifier"
        }) {
            // if have identifier, add its identifier to apparedIds
            let attribute = attribute.as(AttributeSyntax.self)
            let argument = attribute?.arguments?.as(LabeledExprListSyntax.self)?.first
            guard let identifier = argument?.expression.as(IntegerLiteralExprSyntax.self)?.literal.text else {
                return // TODO: error handleing / can't find argument
            }
            guard let identifierNumber = Int(identifier) else {
                return // TODO: error handleing / can't find argument
            }
            appearedIds.append(identifierNumber)
        } else {
            while appearedIds.contains(idCounting) || ruleReservedIdentifier.contains(idCounting) || reservedIdentifier.contains(idCounting) {
                idCounting += 1
            }
            appearedIds.append(idCounting)
            
            var identifierParser = Parser("@Identifier(\(idCounting))")
            var identifier = AttributeSyntax.parse(from: &identifierParser) // parse
            let nestLevel = member.leadingTrivia.first { $0.isSpaceOrTab } ?? .spaces(0) // get leading trivia
            identifier.leadingTrivia = Trivia(pieces: [.newlines(1), nestLevel]) // add trivia
            transformedMember.attributes.append(.attribute(identifier))
        }
    }
}

// MARK: - addNumericDetail
extension ProtobufModelMacro {
    static func addNumericDetail(
        for transformedMember: inout VariableDeclSyntax,
        basedOn member: VariableDeclSyntax,
        in context: some MacroExpansionContext
    ) throws {
        var typeName: String?
        
        // if not numeric type, raise an error
        guard member.bindings.contains(where: { binding in
            // locate type
            typeName = binding.typeAnnotation?.type.as(IdentifierTypeSyntax.self)?.name.text
            return ["Int32", "Int64", "UInt32", "UInt64"].contains(typeName)
        }) else {
            return // TODO: add diagnose
        }
        
        // if contains detail, check its usability
        if let detailAttribute = member.attributes.first(where: { attribute in
            attribute.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "Detail"
        }) {
            let detailAttribute = detailAttribute.as(AttributeSyntax.self)!
            let parameter = detailAttribute.arguments?.as(LabeledExprListSyntax.self)?
                .first?.expression.as(MemberAccessExprSyntax.self)
            guard let argument = parameter?.declName.baseName.text else {
                return // TODO: error handling / can't find argument
            }
            let error = Errors.invalidFieldDetail(type: typeName ?? "UNKNOW", detailToken: argument)
            switch argument {
                case "signed", "signedFixed":
                    guard ["Int32", "Int64"].contains(typeName) else {
                        context.addDiagnostics(from: error, node: parameter!)
                        return
                    }
                case "fixed":
                    guard ["UInt32", "UInt64"].contains(typeName) else {
                        context.addDiagnostics(from: error, node: parameter!)
                        return
                    }
                case "default":
                    break
                default:
                    // unknow argument result
                    context.addDiagnostics(from: Errors.parameterInsufficiency, node: detailAttribute)
            }
            return
        }
        
        var detailParser = Parser("@Detail(.default)")
        var detail = AttributeSyntax.parse(from: &detailParser) // parse
        let nestLevel = member.leadingTrivia.first { $0.isSpaceOrTab } ?? .spaces(0)
        detail.leadingTrivia = Trivia(pieces: [.newlines(1), nestLevel]) // add trivia
        transformedMember.attributes.append(.attribute(detail))
    }
}

