import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct ProtobufKitPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ProtobufModelMacro.self,
    ]
}
