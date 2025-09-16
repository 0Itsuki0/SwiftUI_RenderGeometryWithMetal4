//
//  LineDataIn.swift
//  ViewWithMetal
//
//  Created by Itsuki on 2025/09/16.
//

import Foundation

// A list of VertexIn to pass into the vertex shader, as well as drawPrimitives with
// - Property name does not matter
// - order does matter because when we call drawPrimitives(primitiveType:, vertexStart: 0, vertexCount:), vertexStart and vertexCount is calculated based on the order (we can think of it as the index to an array)
// - We can also simply declare it as an array of VertexIn instead of creating a custom structure
struct LineDataIn {
    var start: VertexIn
    var end: VertexIn
}
