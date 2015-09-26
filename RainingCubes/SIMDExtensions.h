//
//  SIMDExtensions.h
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

#ifndef SIMDExtensions_h
#define SIMDExtensions_h

#include <simd/simd.h>
#include <CoreFoundation/CoreFoundation.h>

CF_INLINE matrix_float4x4 matrix_from_perspective_fov_aspectLH(const float fovY, const float aspect, const float nearZ, const float farZ)
{
	float yscale = 1.0f / tanf(fovY * 0.5f); // 1 / tan == cot
	float xscale = yscale / aspect;
	float q = farZ / (farZ - nearZ);
	
	matrix_float4x4 m = {
		.columns[0] = { xscale, 0.0f, 0.0f, 0.0f },
		.columns[1] = { 0.0f, yscale, 0.0f, 0.0f },
		.columns[2] = { 0.0f, 0.0f, q, 1.0f },
		.columns[3] = { 0.0f, 0.0f, q * -nearZ, 0.0f }
	};
	
	return m;
}

CF_INLINE matrix_float4x4 matrix_from_translation(float x, float y, float z)
{
	matrix_float4x4 m = matrix_identity_float4x4;
	m.columns[3] = (vector_float4) { x, y, z, 1.0 };
	return m;
}

CF_INLINE matrix_float4x4 matrix_from_rotation(float radians, float x, float y, float z)
{
	vector_float3 v = vector_normalize(((vector_float3){x, y, z}));
	float cos = cosf(radians);
	float cosp = 1.0f - cos;
	float sin = sinf(radians);
	
	matrix_float4x4 m = {
		.columns[0] = {
			cos + cosp * v.x * v.x,
			cosp * v.x * v.y + v.z * sin,
			cosp * v.x * v.z - v.y * sin,
			0.0f,
		},
		
		.columns[1] = {
			cosp * v.x * v.y - v.z * sin,
			cos + cosp * v.y * v.y,
			cosp * v.y * v.z + v.x * sin,
			0.0f,
		},
		
		.columns[2] = {
			cosp * v.x * v.z + v.y * sin,
			cosp * v.y * v.z - v.x * sin,
			cos + cosp * v.z * v.z,
			0.0f,
		},
		
		.columns[3] = { 0.0f, 0.0f, 0.0f, 1.0f
		}
	};
	return m;
}

#endif /* SIMDExtensions_h */
