//
//  FallingObject.h
//  RainingCubes
//
//  Created by Nick Zitzmann on 8/29/15.
//  Copyright © 2015 Nick Zitzmann. All rights reserved.
//

#import <Foundation/Foundation.h>
@import simd;

@interface FallingObject : NSObject
@property(assign, nonatomic) vector_float4 ambientColor;
@property(assign, nonatomic) vector_float4 diffuseColor;

- (matrix_float4x4)updatedModelViewMatrixWithTimeDelta:(CFTimeInterval)timeDelta viewMatrix:(matrix_float4x4)viewMatrix;
@end
