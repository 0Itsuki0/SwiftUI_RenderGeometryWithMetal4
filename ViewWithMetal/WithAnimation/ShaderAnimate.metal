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
vertex VertexOut vertexShaderAnimate(uint vertexID [[vertex_id]], constant VertexIn *vertexInArray [[buffer(0)]], constant float *angleDegree [[buffer(1)]]) {
    VertexOut out;

    float posTempX = vertexInArray[vertexID].position[0];
    float posTempY = vertexInArray[vertexID].position[1];
    
    // using 0 instead of vertex_id, because we are expecting a single value instead of an array of angles
    float theta = angleDegree[0] * (M_PI_F / 180);

    float cosine = cos(theta);
    float sine = sin(theta);

    float x = posTempX * cosine - posTempY * sine;
    float y = posTempX * sine + posTempY * cosine;    
    
    out.position = float4(x, y, 0.0, 1.0);

    out.color = vertexInArray[vertexID].color;

    return out;
}


// A basic fragment shader that returns the color data from the VertexOut without modifying it.
fragment float4 fragmentShaderAnimate(VertexOut in [[stage_in]]) {
    return in.color;
}
