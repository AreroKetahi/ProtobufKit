//
//  MemberDetail.swift
//  
//
//  Created by Akivili Collindort on 2024/7/7.
//

@attached(peer)
public macro Detail(_ detail: IntDetail = .default) = #externalMacro(module: "ProtobufKitMacros", type: "ContentDetailMacro")

@attached(peer)
public macro Detail(_ detail: UIntDetail = .default) = #externalMacro(module: "ProtobufKitMacros", type: "ContentDetailMacro")

public enum IntDetail {
    case `default`
    case signed
    case signedFixed
}

public enum UIntDetail {
    case `default`
    case fixed
}
