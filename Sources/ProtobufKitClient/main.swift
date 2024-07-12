import Foundation
import ProtobufKit
import SwiftProtobuf

@ProtobufModel
struct LibraryCard {
    var name: String
    var age: UInt32
    var isMember: Bool
    var uuid: Data?
    var charge: Float
    var borrowedBook: [String]
    var bookNumber: [String: String]
    var registerAge: Int
}
