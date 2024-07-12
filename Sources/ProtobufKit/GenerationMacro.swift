//
//  GenerationMacro.swift
//
//
//  Created by Akivili Collindort on 2024/7/12.
//

@attached(peer, names: arbitrary)
public macro _ProtobufModel() = #externalMacro(module: "ProtobufKitMacros", type: "GeneratePBMacro")

@attached(extension, names: named(Message), named(_MessageImplementationBase), named(_ProtoNameProviding))
public macro _ProtobufResult() = #externalMacro(module: "ProtobufKitMacros", type: "GenerationResultMacro")
