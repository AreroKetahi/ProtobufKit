import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct ProtobufKitPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ProtobufModelMacro.self,
        ContentDetailMacro.self,
        NameMacro.self,
        EmptyPeerMacro.self,
        EmptyExpressionMacro.self,
        GeneratePBMacro.self,
        GenerationResultMacro.self,
    ]
}
