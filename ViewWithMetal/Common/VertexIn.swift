//
//  VertexIn.swift
//  ViewWithMetal
//
//  Created by Itsuki on 2025/09/16.
//


import Foundation

// The same structure as the Metal VertexIn
struct VertexIn {
    // raw positions (in a range of -1 to 1 for both X and Y)
    var position: SIMD2<Float>
    
    // color of the coordinate
    var color: SIMD4<Float>
}
