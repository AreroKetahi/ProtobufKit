//
//  ProtobufName.swift
//  
//
//  Created by Akivili Collindort on 2024/7/7.
//

@attached(peer)
public macro Name(_ names: String) = #externalMacro(module: "ProtobufKitMacros", type: "NameMacro")
