//
//  RainingCubesConfigureWindowController.h
//  RainingCubes
//
//  Created by Nick Zitzmann on 9/9/15.
//  Copyright © 2015 Nick Zitzmann. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@import Metal;

@interface RainingCubesConfigureWindowController : NSWindowController
@property(retain) id <MTLDevice> device;

@property(assign) IBOutlet NSPopUpButton *FSAAPopUp;
@property(assign) IBOutlet NSTextField *GPUTxt;
@property(assign) IBOutlet NSButton *mainScreenOnlyButton;
@property(assign) IBOutlet NSSlider *numberOfCubesSlider;
@property(assign) IBOutlet NSTextField *numberOfCubesTxt;
@property(assign) IBOutlet NSButton *preferDiscreteGPUButton;

- (IBAction)FSAAAction:(id)sender;
- (IBAction)mainScreenOnlyAction:(id)sender;
- (IBAction)numberOfCubesAction:(id)sender;
- (IBAction)okayAction:(id)sender;
- (IBAction)preferDiscreteGPUAction:(id)sender;
@end
