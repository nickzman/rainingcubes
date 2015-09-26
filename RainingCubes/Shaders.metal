//
//  Shaders.metal
//  RainingCubes
//
//  Created by Nick Zitzmann on 8/29/15.
//  Copyright © 2015 Nick Zitzmann. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. The name of the author may not be used to endorse or promote products derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#include <metal_stdlib>
#include <simd/simd.h>
#include "Structs.h"

using namespace metal;

// Variables in constant address space
constant float3 light_position = float3(0.0, 1.0, -1.0);

typedef struct
{
	packed_float3 position;
	packed_float3 normal;
} vertex_t;

typedef struct {
	float4 position [[position]];
	half4  color;
} ColorInOut;

// Vertex shader function
vertex ColorInOut lighting_vertex(device vertex_t* vertex_array [[ buffer(0) ]],
								  constant uniforms_t& uniforms [[ buffer(1) ]],
								  unsigned int vid [[ vertex_id ]])
{
	ColorInOut out;
	float4 in_position = float4(float3(vertex_array[vid].position), 1.0);
	float3 normal = vertex_array[vid].normal;
	float4 eye_normal = normalize(uniforms.normal_matrix * float4(normal, 0.0));
	float n_dot_l = dot(eye_normal.rgb, normalize(light_position));
	
	out.position = uniforms.modelview_projection_matrix * in_position;
	n_dot_l = fmax(0.0, n_dot_l);
	out.color = half4(uniforms.ambient_color + uniforms.diffuse_color * n_dot_l);
	
	return out;
}

// Fragment shader function
fragment half4 lighting_fragment(ColorInOut in [[stage_in]])
{
	return in.color;
}
