//
//  File.metal
//  ViewWithMetal
//
//  Created by Itsuki on 2025/09/15.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    // raw positions (in a range of -1 to 1 for both X and Y)
    float2 position;
    
    // color of the coordinate, normalized between -1 to 1, ie: MTLPixelFormat.bgra8Unorm
    float4 color;
};

// A type that stores the vertex shader's output and serves as an input to the fragment shader.
struct VertexOut {
    // The `[[position]]` attribute indicates that the position is the vertex's
    // clip-space position.
    float4 position [[position]];
    
    // color of the coordinate, normalized between -1 to 1, ie: MTLPixelFormat.bgra8Unorm
    float4 color;
};


// A vertex shader that converts each input vertex from pixel coordinates to
// clip-space coordinates.
//
// The vertex shader doesn't modify the color values.
vertex VertexOut vertexShader(uint vertexID [[vertex_id]], constant VertexIn *vertexInArray [[buffer(0)]]) {
    VertexOut out;
    // keep the x and y coordinate (within the range of -1.0 to 1.0) of the input as the output, and
    // assigning z to be 0.0, w to be 1.0
    out.position = float4(vertexInArray[vertexID].position, 0.0, 1.0);
    
    out.color = vertexInArray[vertexID].color;
    
    //  Here we map the [-1, 1] range to [0, 1] by doing vertices[vertexID] * 0.5 + 0.5.
//    out.textureCoordinates = in[vertexID].textureCoordinates;

    return out;
}


// A basic fragment shader that returns the color data from the VertexOut without modifying it.
fragment float4 fragmentShader(VertexOut in [[stage_in]]) {
    return in.color;
}
