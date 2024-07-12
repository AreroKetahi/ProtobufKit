//
//  MemberIdentifier.swift
//  
//
//  Created by Akivili Collindort on 2024/7/8.
//

@attached(peer)
public macro Identifier(_ sort: Int) = #externalMacro(module: "ProtobufKitMacros", type: "EmptyPeerMacro")

@freestanding(expression)
public macro Reserved(_ identifier: Int...) = #externalMacro(module: "ProtobufKitMacros", type: "EmptyExpressionMacro")
