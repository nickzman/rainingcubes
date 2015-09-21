//
//  FallingObject.m
//  RainingCubes
//
//  Created by Nick Zitzmann on 8/29/15.
//  Copyright © 2015 Nick Zitzmann. All rights reserved.
//

#import "FallingObject.h"
#import "SIMDExtensions.h"

@implementation FallingObject
{
	matrix_float4x4 _startLocation;
	matrix_float4x4 _currentLocation;
	float _rotation;
	vector_float3 _rotationConstants;
	float _acceleration;
	
	float _minDepth;
	float _maxDepth;
	
	vector_float4 _ambientColor;
	vector_float4 _diffuseColor;
}


- (id)initWithMinDepth:(float)minDepth maxDepth:(float)maxDepth
{
	self = [super init];
	if (self)
	{
		_minDepth = minDepth;
		_maxDepth = maxDepth;
		[self reset:YES];
	}
	return self;
}


FOUNDATION_STATIC_INLINE float RandomFloatBetween(float a, float b)
{
	const float randomF = (float)random();
	const float maxRandomF = (float)RAND_MAX;
	
	return a + (b - a) * (randomF / maxRandomF);
}


- (void)reset:(BOOL)firstTime
{
	float randomZ = RandomFloatBetween(_minDepth, _maxDepth);
	float randomX = RandomFloatBetween(-randomZ, randomZ);
	
	if (firstTime)
	{
		float randomY = RandomFloatBetween(randomZ*-1.0f, randomZ);
		
		_startLocation = matrix_from_translation(randomX, randomY, randomZ);
		_rotation = RandomFloatBetween(0.0f, 1.0f);
		_rotationConstants = (vector_float3){RandomFloatBetween(-2.0f, 2.0f), RandomFloatBetween(-2.0f, 2.0f), RandomFloatBetween(-2.0f, 2.0f)};
		_ambientColor = (vector_float4){RandomFloatBetween(0.0f, 2.0f/3.0f), RandomFloatBetween(0.0f, 2.0f/3.0f), RandomFloatBetween(0.0f, 2.0f/3.0f), 1.0f};
		_diffuseColor = (vector_float4){_ambientColor.x/0.4f, _ambientColor.y/0.4f, _ambientColor.z/0.4f, 1.0f};
	}
	else
		_startLocation = matrix_from_translation(randomX, randomZ, randomZ);
	_currentLocation = _startLocation;
	_acceleration = 0.0f;
}


- (void)updateUniforms:(uniforms_t *)uniforms withTimeDelta:(CFTimeInterval)timeDelta projectionMatrix:(matrix_float4x4)projectionMatrix
{
	matrix_float4x4 baseMV;
	matrix_float4x4 modelViewMatrix;
	matrix_float4x4 viewMatrix = matrix_identity_float4x4;
	
	_currentLocation.columns[3].y -= timeDelta*2.0f+_acceleration;	// move the object downward
	if (_currentLocation.columns[3].y < _currentLocation.columns[3].z*-1.0f)	// if we have moved off-screen, then it's time to reset
		[self reset:NO];
	baseMV = matrix_multiply(viewMatrix, _currentLocation);
	modelViewMatrix = matrix_multiply(baseMV, matrix_from_rotation(_rotation, _rotationConstants.x, _rotationConstants.y, _rotationConstants.z));
	
	uniforms->normal_matrix = matrix_invert(matrix_transpose(modelViewMatrix));
	uniforms->modelview_projection_matrix = matrix_multiply(projectionMatrix, modelViewMatrix);
	uniforms->ambient_color = _ambientColor;
	uniforms->diffuse_color = _diffuseColor;
	
	// Update the object's position and rotation for next time...
	_rotation += timeDelta;
	_acceleration += timeDelta*0.15f;
}

@end
