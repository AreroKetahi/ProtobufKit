//
//  ProtobufKit.swift
//
//
//  Created by Akivili Collindort on 2024/7/7.
//

import Foundation
import SwiftProtobuf

// The comment below is the macro pre-planning

/* source
 @ProtobufModel
 struct SomeStruct {
    let int32: Int32 // int32
 
    @Detail(.signed)
    let sint32: Int32 // int32
 
    @Detail(.signedFixed)
    let sfixed32: Int32
 
    let uint32: UInt32
 
    @Detail(.fixed)
    let fixed32: UInt32
 }
 */

/*
 struct SomeStruct {
    @Detail(.default)
    @Identifier(1)
    let int32: Int32 // int32
 
    @Detail(.signed)
    @Identifier(2)
    let sint32: Int32 // int32
 
    @Detail(.signedFixed)
    @Identifier(3)
    let sfixed32: Int32
 
    @Detail(.default)
    @Identifier(4)
    let uint32: UInt32
 
    @Detail(.fixed)
    @Identifier(5)
    let fixed32: UInt32
 }
 */
