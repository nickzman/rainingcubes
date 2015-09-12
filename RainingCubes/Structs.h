//
//  Structs.h
//  RainingCubes
//
//  Created by Nick Zitzmann on 8/29/15.
//  Copyright © 2015 Nick Zitzmann. All rights reserved.
//

#ifndef Structs_h
#define Structs_h

#include <simd/simd.h>

typedef struct
{
	matrix_float4x4 modelview_projection_matrix;
	matrix_float4x4 normal_matrix;
	vector_float4 ambient_color;
	vector_float4 diffuse_color;
	char padding_so_this_struct_is_256_bytes_wide[96];	// NVIDIA's GPUs require the uniform buffer to be a multiple of 256 bytes, whereas Apple's and Intel's GPUs apparently don't care about the size
} uniforms_t;

#endif /* Structs_h */
