//
//  FallingObject.m
//  RainingCubes
//
//  Created by Nick Zitzmann on 8/29/15.
//  Copyright © 2015 Nick Zitzmann. All rights reserved.
//

#import "FallingObject.h"
#import "SIMDExtensions.h"

static float gMaxDepth;

@implementation FallingObject
{
	matrix_float4x4 _startLocation;
	matrix_float4x4 _currentLocation;
	float _rotation;
	vector_float3 _rotationConstants;
	float _acceleration;
}

+ (void)initialize
{
	static BOOL alreadyInitialized = NO;
	
	if (alreadyInitialized)
		return;
	// FIXME: Replace 1000.0f with the max # of falling objects later
	gMaxDepth = 10.0f+(1000.0f/80.0f);
}

- (id)init
{
	self = [super init];
	if (self)
	{
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
	float randomZ = RandomFloatBetween(5.0f, gMaxDepth);
	float randomX = RandomFloatBetween(-randomZ, randomZ);
	
	if (firstTime)
	{
		float randomY = RandomFloatBetween(randomZ*-1.0f, randomZ);
		
		_startLocation = matrix_from_translation(randomX, randomY, randomZ);
		_rotation = RandomFloatBetween(0.0f, 1.0f);
		_rotationConstants = (vector_float3){RandomFloatBetween(-2.0f, 2.0f), RandomFloatBetween(-2.0f, 2.0f), RandomFloatBetween(-2.0f, 2.0f)};
		self.ambientColor = (vector_float4){RandomFloatBetween(0.0f, 1.0f), RandomFloatBetween(0.0f, 1.0f), RandomFloatBetween(0.0f, 1.0f), 1.0f};
		self.diffuseColor = (vector_float4){self.ambientColor.x/0.4f, self.ambientColor.y/0.4f, self.ambientColor.z/0.4f, 1.0f};
	}
	else
		_startLocation = matrix_from_translation(randomX, randomZ, randomZ);
	_currentLocation = _startLocation;
	_acceleration = 0.0f;
}


- (matrix_float4x4)updatedModelViewMatrixWithTimeDelta:(CFTimeInterval)timeDelta viewMatrix:(matrix_float4x4)viewMatrix
{
	matrix_float4x4 baseMV;
	matrix_float4x4 modelViewMatrix;
	
	_currentLocation.columns[3].y -= timeDelta*2.0f+_acceleration;
	if (_currentLocation.columns[3].y < _currentLocation.columns[3].z*-1.0f)
		[self reset:NO];
	baseMV = matrix_multiply(viewMatrix, _currentLocation);
	modelViewMatrix = matrix_multiply(baseMV, matrix_from_rotation(_rotation, _rotationConstants.x, _rotationConstants.y, _rotationConstants.z));
	
	_rotation += timeDelta;
	_acceleration += timeDelta*0.15f;
	return modelViewMatrix;
}

@end
