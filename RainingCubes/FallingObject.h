//
//  FallingObject.h
//  RainingCubes
//
//  Created by Nick Zitzmann on 8/29/15.
//  Copyright © 2015 Nick Zitzmann. All rights reserved.
//

#import <Foundation/Foundation.h>
@import simd;
#import "Structs.h"

@interface FallingObject : NSObject
- (id)initWithMinDepth:(float)minDepth maxDepth:(float)maxDepth;

- (void)updateUniforms:(uniforms_t *)uniforms withTimeDelta:(CFTimeInterval)timeDelta projectionMatrix:(matrix_float4x4)projectionMatrix;
@end
