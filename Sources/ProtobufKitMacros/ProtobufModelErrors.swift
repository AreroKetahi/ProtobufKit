//
//  ProtobufModelErrors.swift
//  
//
//  Created by Akivili Collindort on 2024/7/8.
//

import Foundation
import SwiftSyntax

typealias Errors = ProtobufModelErrors

enum ProtobufModelErrors: Error {
    case arbitrary(String)
    case parameterInsufficiency
    case invalidFieldDetail(type: String, detailToken: String)
    case unsupportedSyntax(SyntaxProtocol, extraInformation: String)
    case invalidKeyType(type: TypeSyntax)
    case classUnsupported
}

extension ProtobufModelErrors: CustomStringConvertible {
    var description: String {
        switch self {
            case .arbitrary(let description):
                description
            case .invalidFieldDetail(let type, let detailToken):
                "Can't apply parameter \"\(detailToken)\" to type \(type)."
            case .parameterInsufficiency:
                "Parameter not found at expected location."
            case .unsupportedSyntax(let syntax, let extra):
                "\"\(syntax.description.trimmingCharacters(in: .whitespacesAndNewlines))\" is not supported. \(extra)"
            case .invalidKeyType(type: let type):
                "\"\(type)\" cannot be used for a dictionary value type."
            case .classUnsupported:
                "Class is unsupported, consider use structure instead."
        }
    }
}
