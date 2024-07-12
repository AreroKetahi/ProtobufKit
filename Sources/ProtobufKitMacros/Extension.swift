//
//  Extension.swift
//
//
//  Created by Akivili Collindort on 2024/7/12.
//

import Foundation
import SwiftSyntax

extension SyntaxProtocol {
    func mutate(_ action: (inout Self) -> ()) -> Self {
        var copy = self
        action(&copy)
        return copy
    }
}
