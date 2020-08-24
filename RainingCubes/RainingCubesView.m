//
//  RainingCubesView.m
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

#import "RainingCubesView.h"
#import "FallingObject.h"
#import "SIMDExtensions.h"
#import "Structs.h"
#import "RainingCubesConfigureWindowController.h"
@import Metal;
@import QuartzCore;
@import simd;

// The max number of command buffers in flight
static const NSUInteger g_max_inflight_buffers = 3;

float cubeVertexData[216] =
{
	// Data layout for each line below is:
	// positionX, positionY, positionZ,     normalX, normalY, normalZ,
	0.5, -0.5, 0.5,   0.0, -1.0,  0.0,
	-0.5, -0.5, 0.5,   0.0, -1.0, 0.0,
	-0.5, -0.5, -0.5,   0.0, -1.0,  0.0,
	0.5, -0.5, -0.5,  0.0, -1.0,  0.0,
	0.5, -0.5, 0.5,   0.0, -1.0,  0.0,
	-0.5, -0.5, -0.5,   0.0, -1.0,  0.0,
	
	0.5, 0.5, 0.5,    1.0, 0.0,  0.0,
	0.5, -0.5, 0.5,   1.0,  0.0,  0.0,
	0.5, -0.5, -0.5,  1.0,  0.0,  0.0,
	0.5, 0.5, -0.5,   1.0, 0.0,  0.0,
	0.5, 0.5, 0.5,    1.0, 0.0,  0.0,
	0.5, -0.5, -0.5,  1.0,  0.0,  0.0,
	
	-0.5, 0.5, 0.5,    0.0, 1.0,  0.0,
	0.5, 0.5, 0.5,    0.0, 1.0,  0.0,
	0.5, 0.5, -0.5,   0.0, 1.0,  0.0,
	-0.5, 0.5, -0.5,   0.0, 1.0,  0.0,
	-0.5, 0.5, 0.5,    0.0, 1.0,  0.0,
	0.5, 0.5, -0.5,   0.0, 1.0,  0.0,
	
	-0.5, -0.5, 0.5,  -1.0,  0.0, 0.0,
	-0.5, 0.5, 0.5,   -1.0, 0.0,  0.0,
	-0.5, 0.5, -0.5,  -1.0, 0.0,  0.0,
	-0.5, -0.5, -0.5,  -1.0,  0.0,  0.0,
	-0.5, -0.5, 0.5,  -1.0,  0.0, 0.0,
	-0.5, 0.5, -0.5,  -1.0, 0.0,  0.0,
	
	0.5, 0.5,  0.5,  0.0, 0.0,  1.0,
	-0.5, 0.5,  0.5,  0.0, 0.0,  1.0,
	-0.5, -0.5, 0.5,   0.0,  0.0, 1.0,
	-0.5, -0.5, 0.5,   0.0,  0.0, 1.0,
	0.5, -0.5, 0.5,   0.0,  0.0,  1.0,
	0.5, 0.5,  0.5,  0.0, 0.0,  1.0,
	
	0.5, -0.5, -0.5,  0.0,  0.0, -1.0,
	-0.5, -0.5, -0.5,   0.0,  0.0, -1.0,
	-0.5, 0.5, -0.5,  0.0, 0.0, -1.0,
	0.5, 0.5, -0.5,  0.0, 0.0, -1.0,
	0.5, -0.5, -0.5,  0.0,  0.0, -1.0,
	-0.5, 0.5, -0.5,  0.0, 0.0, -1.0
};

@interface RainingCubesView ()
@property(atomic,assign) BOOL layerSizeDidUpdate;
@end

@interface RainingCubesView (Private)
- (void)rc_loadAssets;
- (void)rc_loadUserDefaults;
- (void)rc_render;
- (void)rc_reshape;
- (void)rc_setupMetal:(NSArray *)devices;
- (void)rc_setupRenderPassDescriptorForTexture:(id <MTLTexture>)texture;
@end

@implementation RainingCubesView
{
	// Using internal ivars instead of @properties for the best possible performance.
	// Layer:
	CAMetalLayer *_metalLayer;
	MTLRenderPassDescriptor *_renderPassDescriptor;
	
	// Controller:
	CVDisplayLinkRef _timer;
	dispatch_semaphore_t _inflight_semaphore;
	id <MTLBuffer> _dynamicConstantBuffer[g_max_inflight_buffers];
	uint8_t _constantDataBufferIndex;
	CFTimeInterval _timeSinceLastDrawDelta;
	CFTimeInterval _timeSinceLastDrawPreviousTime;
	BOOL _firstDrawOccurred;
	NSArray *_fallingObjects;
	id <NSObject> _screenChangeObserver;
	
	// Renderer:
	id <MTLDevice> _device;
	id <MTLCommandQueue> _commandQueue;
	id <MTLLibrary> _defaultLibrary;
	id <MTLRenderPipelineState> _pipelineState;
	id <MTLBuffer> _vertexBuffer;
	id <MTLDepthStencilState> _depthState;
	id <MTLTexture> _depthTex;
	id <MTLTexture> _msaaTex;
	NSUInteger _sampleCount;
	BOOL _mainScreenOnly;
	
	// Uniforms:
	matrix_float4x4 _projectionMatrix;
	matrix_float4x4 _viewMatrix;
	uniforms_t _uniform_buffer;
	
	// User defaults GUI:
	RainingCubesConfigureWindowController *_configureController;
}

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
	self = [super initWithFrame:frame isPreview:isPreview];
	if (self)
	{
		[self setAnimationTimeInterval:1/60.0];
		
		// Does the user have OS X 10.11 or later installed?
		if (@available(macOS 11.0, *))
		{
			NSArray *devices = MTLCopyAllDevices();
			
			// Does the user have any Metal devices available? (This should be yes on all Macs made after mid-2012.)
			if (!devices || devices.count == 0)
			{
				NSTextField *noMetalField = [[NSTextField alloc] initWithFrame:CGRectZero];
				
				noMetalField.stringValue = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"No Metal devices could be found.\n%@ requires a GPU that supports\nMetal in order to render.\nThis includes all Macs made since mid-2012.\nAlso, Metal won’t work in a VM.", @"RainingCubes", [NSBundle bundleForClass:self.class], @"Text we display to the user if they try running the screen saver on a computer with no Metal devices available"), [[NSBundle bundleForClass:self.class] objectForInfoDictionaryKey:@"CFBundleName"]];
				noMetalField.font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
				noMetalField.alignment = NSTextAlignmentCenter;
				noMetalField.textColor = [NSColor whiteColor];
				noMetalField.drawsBackground = NO;
				noMetalField.bezeled = NO;
				noMetalField.editable = NO;
				noMetalField.translatesAutoresizingMaskIntoConstraints = NO;
				[self addSubview:noMetalField];
				[self addConstraints:@[[NSLayoutConstraint constraintWithItem:noMetalField attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0], [NSLayoutConstraint constraintWithItem:noMetalField attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]]];
			}
			else
			{
				_constantDataBufferIndex = 0U;
				_inflight_semaphore = dispatch_semaphore_create(g_max_inflight_buffers);
				
				[self rc_setupMetal:devices];	// set up Metal
				[self rc_loadUserDefaults];	// load user defaults; create buffers
				//[self rc_loadAssets];	// load the shaders; create buffers; set up pipeline & depth states
			}
		}
		else
		{
			NSTextField *noMetalField = [[NSTextField alloc] initWithFrame:CGRectZero];
			
			noMetalField.stringValue = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Your version of the OS does not support Metal.\n%@ requires OS X 10.11 or later.", @"RainingCubes", [NSBundle bundleForClass:self.class], @"Text we display to the user if they try running the screen saver on OS X Yosemite or earlier"), [[NSBundle bundleForClass:self.class] objectForInfoDictionaryKey:@"CFBundleName"]];
			noMetalField.font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
			noMetalField.alignment = NSTextAlignmentCenter;
			noMetalField.textColor = [NSColor whiteColor];
			noMetalField.drawsBackground = NO;
			noMetalField.bezeled = NO;
			noMetalField.editable = NO;
			noMetalField.translatesAutoresizingMaskIntoConstraints = NO;
			[self addSubview:noMetalField];
			[self addConstraints:@[[NSLayoutConstraint constraintWithItem:noMetalField attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0], [NSLayoutConstraint constraintWithItem:noMetalField attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]]];
		}
	}
	return self;
}


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)setFrameSize:(NSSize)newSize
{
	[super setFrameSize:newSize];
	_layerSizeDidUpdate = YES;
}


- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
	__weak RainingCubesView *weakSelf = self;
	
	[super viewWillMoveToWindow:newWindow];
	
	// If _mainScreenOnly is on, and this isn't the main screen, then shut down drawing by releasing the device:
	if (_mainScreenOnly && newWindow.screen != [NSScreen mainScreen])
	{
		_device = nil;
		self.layer = [CALayer layer];
		self.layer.backgroundColor = [[NSColor blackColor] CGColor];
	}
	
	// If newWindow changes screens for any reason, then we want to know about that so we can update the layer size if necessary:
	if (_screenChangeObserver)
		[[NSNotificationCenter defaultCenter] removeObserver:_screenChangeObserver];
	_screenChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidChangeBackingPropertiesNotification object:newWindow queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification) {
		weakSelf.layerSizeDidUpdate = YES;
	}];
}


CVReturn DisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp *inNow, const CVTimeStamp *inOutputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *displayLinkContext)
{
	RainingCubesView *theView = (__bridge RainingCubesView *)displayLinkContext;
	
	[theView animateOneFrame];
	return kCVReturnSuccess;
}


- (void)startAnimation
{
	// Metal apparently requires an animation timer that is synchronized with the display's refresh rate. If we use an NSTimer for drawing, which ScreenSaverView does internally, we will get this weird stuttering frame rate problem even though we're feeding a constant 60 FPS to the screen.
	// But if we use the CVDisplayLink API to run the timer, the video doesn't stutter. So because we run our own timer, we can't invoke the superclass here.
	if (!_timer)
	{
		CGDirectDisplayID screensID = [self.window.screen.deviceDescription[@"NSScreenNumber"] unsignedIntValue];
		
		CVDisplayLinkCreateWithCGDisplay(screensID, &_timer);
		CVDisplayLinkSetOutputCallback(_timer, DisplayLinkCallback, (__bridge void *)self);
	}
	[self rc_reshape];
	CVDisplayLinkStart(_timer);
	_firstDrawOccurred = NO;	// reset the draw timer every time the animation restarts
}


- (void)stopAnimation
{
	if (_timer)
	{
		CVDisplayLinkStop(_timer);
	}
}


- (BOOL)isAnimating
{
	if (!_timer)
		return NO;
	return CVDisplayLinkIsRunning(_timer);
}


- (void)animateOneFrame
{
	if (!_device)	// if we never received a Metal device, then we have nothing to draw
		return;
	
	@autoreleasepool	// from what I've read, we need to enforce that drawables be released promptly by the program, and the best way to do this is to wrap rendering in an autorelease pool
	{
		// How much time has passed since the previous frame was drawn?
		if (!_firstDrawOccurred)
		{
			_timeSinceLastDrawDelta = 0.0;
			_timeSinceLastDrawPreviousTime = CACurrentMediaTime();
			_firstDrawOccurred = YES;
		}
		else
		{
			CFTimeInterval now = CACurrentMediaTime();
			
			_timeSinceLastDrawDelta = now-_timeSinceLastDrawPreviousTime;
			_timeSinceLastDrawPreviousTime = now;
		}
		
		// If the frame size changed or we moved to a new screen, then update the drawable size to be appropriate for our bounds size * the screen's scale factor:
		if (self.layerSizeDidUpdate)
		{
			dispatch_sync(dispatch_get_main_queue(), ^{
				CGFloat nativeScale = self.window.screen.backingScaleFactor;
				CGSize drawableSize = self.bounds.size;
				
				drawableSize.width *= nativeScale;
				drawableSize.height *= nativeScale;
				_metalLayer.drawableSize = drawableSize;
				
				[self rc_reshape];
				self.layerSizeDidUpdate = NO;
			});
		}
		
		// Draw!
		[self rc_render];
	}
}


- (BOOL)hasConfigureSheet
{
	return _device != nil;	// if we are going to draw more than an error message, then we also have a configure sheet
}


- (NSWindow *)configureSheet
{
	if (!_configureController)
	{
		_configureController = [[RainingCubesConfigureWindowController alloc] initWithWindowNibName:@"RainingCubesConfigureWindowController"];
		_configureController.device = _device;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDefaultsChanged:) name:@"RCUserDefaultsChangedNotification" object:nil];
	}
	return _configureController.window;
}


- (void)userDefaultsChanged:(NSNotification *)aNotification
{
	[self rc_loadUserDefaults];
	if (self.animating)
	{
		[self stopAnimation];
		[self startAnimation];
	}
}

@end

@implementation RainingCubesView (Private)

- (void)rc_loadAssets
{
	NSParameterAssert(_defaultLibrary);	// sanity check: the library must be set up first
	
	id <MTLFunction> fragmentProgram = [_defaultLibrary newFunctionWithName:@"lighting_fragment"];	// our fragment shader
	id <MTLFunction> vertexProgram = [_defaultLibrary newFunctionWithName:@"lighting_vertex"];	// and our vertex shader
	MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
	MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
	NSError *err = nil;
	
	// Set up the vertex buffers:
	_vertexBuffer = [_device newBufferWithBytes:cubeVertexData length:sizeof(cubeVertexData) options:MTLResourceOptionCPUCacheModeDefault];
	_vertexBuffer.label = @"Vertices";
	
	if (_sampleCount > 1UL && ![_device supportsTextureSampleCount:_sampleCount])
	{
		NSLog(@"Warning: Device %@ does not support a sample count of %lu. Disabling multi-sample support.", _device, (unsigned long)_sampleCount);
		_sampleCount = 1UL;
	}
	
	// Create a reusable pipeline state:
	pipelineStateDescriptor.label = @"RainingCubesPipeline";
	pipelineStateDescriptor.sampleCount = _sampleCount;
	pipelineStateDescriptor.vertexFunction = vertexProgram;
	pipelineStateDescriptor.fragmentFunction = fragmentProgram;
	pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
	pipelineStateDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
	
	_pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&err];
	if (!_pipelineState)
	{
		NSLog(@"Failed to created pipeline state, error %@", err);
	}
	
	// And finally, set up the depth state so that we don't draw objects that are behind something closer to the camera.
	depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
	depthStateDesc.depthWriteEnabled = YES;
	_depthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];
}


- (void)rc_loadUserDefaults
{
	ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:[[NSBundle bundleForClass:self.class] bundleIdentifier]];
	NSInteger i, count;
	NSMutableArray *fallingObjects = [[NSMutableArray alloc] init];
	size_t maxBufferBytesPerFrame;
	NSUInteger newSampleCount;
	float minDepth, maxDepth;
	
	// Set up some default values if none are stored:
	if (![defaults objectForKey:@"RCNumberOfCubes"])
		[defaults setInteger:100L forKey:@"RCNumberOfCubes"];
	if (![defaults objectForKey:@"RCFSAASamples"])
		[defaults setInteger:1L forKey:@"RCFSAASamples"];
	if (![defaults objectForKey:@"RCMainScreenOnly"])
		[defaults setBool:NO forKey:@"RCMainScreenOnly"];
	
	// Set up the array of objects:
	count = [defaults integerForKey:@"RCNumberOfCubes"];
	minDepth = 5.0f+(count/800.0f);
	maxDepth = 10.0f+(count/80.0f);
	for (i = 0L ; i < count ; i++)
	{
		[fallingObjects addObject:[[FallingObject alloc] initWithMinDepth:minDepth maxDepth:maxDepth]];
	}
	_fallingObjects = [fallingObjects copy];
	
	// Set up the constant buffers to be shared with the GPU:
	maxBufferBytesPerFrame = sizeof(uniforms_t)*_fallingObjects.count;
	for (i = 0UL ; i < g_max_inflight_buffers ; i++)
	{
		_dynamicConstantBuffer[i] = [_device newBufferWithLength:maxBufferBytesPerFrame options:0];
		_dynamicConstantBuffer[i].label = [NSString stringWithFormat:@"ConstantBuffer%lu", (unsigned long)i];
	}
	
	// Load in the other preferences:
	newSampleCount = [defaults integerForKey:@"RCFSAASamples"];
	if (newSampleCount != _sampleCount)	// we _must_ build a new pipeline state if the multi-sampling preference changed, or we might hard-lock the window server
	{
		_sampleCount = newSampleCount;
		[self rc_loadAssets];
	}
	_mainScreenOnly = [defaults integerForKey:@"RCMainScreenOnly"];
}


- (void)rc_render
{
	id <CAMetalDrawable> drawable;
	id <MTLCommandBuffer> commandBuffer;
	id <MTLRenderCommandEncoder> renderEncoder;
	__block dispatch_semaphore_t block_sema = _inflight_semaphore;
	
	// We only have enough buffer space to render g_max_inflight_bufer frames. Block here if we're getting ahead of the GPU.
	dispatch_semaphore_wait(_inflight_semaphore, DISPATCH_TIME_FOREVER);
	
	// The documentation says we should prepare for rendering before we ask the layer for a drawable:
	[_fallingObjects enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(FallingObject *object, NSUInteger i, BOOL *stop) {
		uniforms_t *constantBufferArray = (uniforms_t *)[_dynamicConstantBuffer[_constantDataBufferIndex] contents];
		uniforms_t constantBuffer;
		
		bzero(&constantBuffer, sizeof(uniforms_t));
		[object updateUniforms:&constantBuffer withTimeDelta:0.015 projectionMatrix:_projectionMatrix];
		memcpy(&constantBufferArray[i], &constantBuffer, sizeof(uniforms_t));
	}];
	
	// Create a new command buffer for each renderpass to the current drawable:
	commandBuffer = [_commandQueue commandBuffer];
	commandBuffer.label = @"MyCommand";
	
	// Obtain a drawable texture for this render pass and set up the renderpass descriptor for the command encoder to render into:
	drawable = [_metalLayer nextDrawable];
	if (!drawable)	// if we can't get a drawable, we'll throw an exception setting up the render pass descriptor, so skip the frame entirely
	{
		dispatch_semaphore_signal(block_sema);
		return;
	}
	[self rc_setupRenderPassDescriptorForTexture:drawable.texture];
	
	// Create a render command encoder so we can render into something:
	renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:_renderPassDescriptor];
	renderEncoder.label = @"MyRenderEncoder";
	[renderEncoder setDepthStencilState:_depthState];
	
	// Set context state:
	[renderEncoder pushDebugGroup:@"DrawCubes"];
	[renderEncoder setRenderPipelineState:_pipelineState];
	[renderEncoder setVertexBuffer:_vertexBuffer offset:0UL atIndex:0UL];
	[_fallingObjects enumerateObjectsUsingBlock:^(FallingObject *object, NSUInteger i, BOOL *stop) {
		[renderEncoder setVertexBuffer:_dynamicConstantBuffer[_constantDataBufferIndex] offset:i*sizeof(uniforms_t) atIndex:1UL];
		[renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0UL vertexCount:36UL];
	}];
	[renderEncoder popDebugGroup];
	
	// All done:
	[renderEncoder endEncoding];
	
	// Add a completion handler that will increment _inflight_semaphore so the next frame can begin:
	[commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
		dispatch_semaphore_signal(block_sema);
	}];
	
	// Increment _constantDataBufferIndex for the next frame. Assume what we just rendered won't be touched until we cycle back around:
	_constantDataBufferIndex = (_constantDataBufferIndex + 1) % g_max_inflight_buffers;
	
	// Schedule the drawable to be presented:
	[commandBuffer presentDrawable:drawable];
	
	// Finalize rendering & push the command buffer to the GPU:
	[commandBuffer commit];
}


- (void)rc_reshape
{
	// The view size or screen depth must have changed, so update the projection matrix:
	float aspect = fabs(self.bounds.size.width / self.bounds.size.height);
	_projectionMatrix = matrix_from_perspective_fov_aspectLH(65.0f * (M_PI / 180.0f), aspect, 0.1f, 100.0f);
	
	_viewMatrix = matrix_identity_float4x4;
}


- (void)rc_setupMetal:(NSArray *)devices
{
	NSError *err = nil;
	ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:[[NSBundle bundleForClass:self.class] bundleIdentifier]];
	BOOL preferDiscreteDevice = [defaults boolForKey:@"RCPreferDiscreteGPU"];
	
	if (preferDiscreteDevice)
		_device = MTLCreateSystemDefaultDevice();
	else
	{
		// Prefer a low-power device (e.g. an integrated GPU) if we can find it. Otherwise, just use what's available.
		[devices enumerateObjectsUsingBlock:^(id <MTLDevice> prospectiveDevice, NSUInteger i, BOOL *stop) {
			if (prospectiveDevice.lowPower)
			{
				_device = prospectiveDevice;
				*stop = YES;
			}
			_device = prospectiveDevice;
		}];
	}
	_commandQueue = [_device newCommandQueue];
	_defaultLibrary = [_device newLibraryWithFile:[[NSBundle bundleForClass:self.class] pathForResource:@"default" ofType:@"metallib"] error:&err];	// can't use -newDefaultLibrary in a bundle
	
	// Set up the Metal layer:
	_metalLayer = [CAMetalLayer layer];
	_metalLayer.device = _device;
	_metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
	self.layer = _metalLayer;
	self.wantsLayer = YES;
}


- (void)rc_setupRenderPassDescriptorForTexture:(id <MTLTexture>)texture
{
	MTLRenderPassColorAttachmentDescriptor *colorAttachment;
	
	if (_renderPassDescriptor == nil)
		_renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
	colorAttachment = _renderPassDescriptor.colorAttachments[0];
	
	colorAttachment.texture = texture;
	colorAttachment.loadAction = MTLLoadActionClear;	// clear every frame for best performance
	colorAttachment.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);	// black background
	
	if (_sampleCount > 1UL && ![_device supportsTextureSampleCount:_sampleCount])
	{
		NSLog(@"Warning: Device %@ does not support a sample count of %lu. Disabling multi-sample support.", _device, (unsigned long)_sampleCount);
		_sampleCount = 1UL;
	}
	
	if (_sampleCount > 1UL)	// MSAA - render into an MSAA texture we create while resolving into the drawable's texture
	{
		if (!_msaaTex || (_msaaTex.width != texture.width || _msaaTex.height != texture.height || _msaaTex.sampleCount != _sampleCount))
		{
			// If we need an MSAA texture and don't have one, or if the MSAA texture we have is the wrong size, then allocate one of the proper size:
			MTLTextureDescriptor *msaaTextureDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:texture.width height:texture.height mipmapped:NO];
			
			msaaTextureDesc.textureType = MTLTextureType2DMultisample;
			msaaTextureDesc.sampleCount = _sampleCount;
			msaaTextureDesc.resourceOptions = MTLResourceStorageModePrivate;	// multi-sample textures aren't allowed to be shared
			msaaTextureDesc.usage = MTLTextureUsageRenderTarget;	// yes, this texture is for rendering
			_msaaTex = [_device newTextureWithDescriptor:msaaTextureDesc];
			_msaaTex.label = @"MSAA Texture";
		}
		colorAttachment.texture = _msaaTex;
		colorAttachment.resolveTexture = texture;
		colorAttachment.storeAction = MTLStoreActionMultisampleResolve;
	}
	else	// no MSAA - store attachments that will be presented to the screen
		colorAttachment.storeAction = MTLStoreActionStore;
	
	if (!_depthTex || (_depthTex && (_depthTex.width != texture.width || _depthTex.height != texture.height || _depthTex.sampleCount != _sampleCount)))
	{
		// If we need a depth texture and don't have one, or if the depth texture we have is the wrong size, then allocate one of the proper size:
		MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float width:texture.width height:texture.height mipmapped:NO];
		
		desc.textureType = (_sampleCount > 1) ? MTLTextureType2DMultisample : MTLTextureType2D;
		desc.sampleCount = _sampleCount;
		desc.resourceOptions = MTLResourceStorageModePrivate;	// Metal requires depth textures to use GPU memory exclusively
		desc.usage = MTLTextureUsageRenderTarget;	// depth attachment textures are used to render the target
		_depthTex = [_device newTextureWithDescriptor:desc];
		_depthTex.label = @"Depth";
		
		_renderPassDescriptor.depthAttachment.texture = _depthTex;
		_renderPassDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
		_renderPassDescriptor.depthAttachment.clearDepth = 1.0;
		_renderPassDescriptor.depthAttachment.storeAction = MTLStoreActionDontCare;
	}
}

@end
