//
//  ProtobufModel.swift
//  
//
//  Created by Akivili Collindort on 2024/7/7.
//

@attached(peer, names: prefixed(_$))
public macro ProtobufModel() = #externalMacro(module: "ProtobufKitMacros", type: "ProtobufModelMacro")
