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

@property(assign) IBOutlet NSSlider *numberOfCubesSlider;
@property(assign) IBOutlet NSPopUpButton *FSAAPopUp;
@property(assign) IBOutlet NSButton *mainScreenOnlyButton;

- (IBAction)numberOfCubesAction:(id)sender;
- (IBAction)FSAAAction:(id)sender;
- (IBAction)mainScreenOnlyAction:(id)sender;
- (IBAction)okayAction:(id)sender;
@end
