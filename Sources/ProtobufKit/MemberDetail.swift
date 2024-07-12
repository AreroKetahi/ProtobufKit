//
//  MemberDetail.swift
//  
//
//  Created by Akivili Collindort on 2024/7/7.
//

@attached(peer)
public macro Detail(_ detail: IntegerDetail = .default) = #externalMacro(module: "ProtobufKitMacros", type: "ContentDetailMacro")

public enum IntegerDetail {
    /// Default use
    case `default`
    
    /// Available when type is `Int32` and `Int64`
    case signed
    
    /// Available when type is `Int32` and `Int64`
    case signedFixed
    
    /// Available when type is `UInt32` and `UInt64`
    case fixed
}
