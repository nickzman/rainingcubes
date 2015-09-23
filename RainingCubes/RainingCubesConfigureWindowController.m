//
//  RainingCubesConfigureWindowController.m
//  RainingCubes
//
//  Created by Nick Zitzmann on 9/9/15.
//  Copyright © 2015 Nick Zitzmann. All rights reserved.
//

#import "RainingCubesConfigureWindowController.h"
@import ScreenSaver;

@interface RainingCubesConfigureWindowController ()

@end

@implementation RainingCubesConfigureWindowController

- (void)windowDidLoad
{
	NSBundle *bundle = [NSBundle bundleForClass:self.class];
	ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:[bundle bundleIdentifier]];
	NSUInteger i = 2UL;
	
	[super windowDidLoad];
	
	[self.FSAAPopUp removeAllItems];
	[self.FSAAPopUp addItemWithTitle:NSLocalizedStringFromTableInBundle(@"None", @"RainingCubes", bundle, @"FSAA pop-up: No FSAA")];
	self.FSAAPopUp.lastItem.tag = 1L;
	for (i = 2UL ; i <= 16UL ; i++)	// 16x multi-sampling is about as high as it gets
	{
		if ([self.device supportsTextureSampleCount:i])
		{
			[self.FSAAPopUp addItemWithTitle:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%lux", @"RainingCubes", bundle, @"FSAA pop-up: FSAA sample count supported by the GPU, where %lu is substituted for the number of samples. In English, the number is followed by an 'x', which means 'times'"), i]];
			self.FSAAPopUp.lastItem.tag = i;
		}
	}
	[self.FSAAPopUp selectItemWithTag:[defaults integerForKey:@"RCFSAASamples"]];
	
	self.numberOfCubesSlider.integerValue = [defaults integerForKey:@"RCNumberOfCubes"];
	self.numberOfCubesTxt.integerValue = self.numberOfCubesSlider.integerValue;
	self.GPUTxt.stringValue = self.device.name;
	self.preferDiscreteGPUButton.state = [defaults boolForKey:@"RCPreferDiscreteGPU"] ? NSOnState : NSOffState;
	self.preferDiscreteGPUButton.enabled = MTLCopyAllDevices().count > 1UL;	// disable the preferDiscreteGPUButton if there's only one GPU (since there's no point to the preference if there's more than one)
	self.mainScreenOnlyButton.state = [defaults boolForKey:@"RCMainScreenOnly"] ? NSOnState : NSOffState;
	
	self.versionAndCopyrightTxt.stringValue = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Version %@, %@", @"RainingCubes", bundle, @"Template text used in the version/copyright label"), [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [bundle objectForInfoDictionaryKey:@"NSHumanReadableCopyright"]];
}


- (IBAction)numberOfCubesAction:(id)sender
{
	ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:[[NSBundle bundleForClass:self.class] bundleIdentifier]];
	
	[defaults setInteger:[sender integerValue] forKey:@"RCNumberOfCubes"];
	self.numberOfCubesTxt.integerValue = self.numberOfCubesSlider.integerValue;
}


- (IBAction)FSAAAction:(id)sender
{
	ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:[[NSBundle bundleForClass:self.class] bundleIdentifier]];
	
	[defaults setInteger:[sender selectedTag] forKey:@"RCFSAASamples"];
}


- (IBAction)preferDiscreteGPUAction:(id)sender
{
	ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:[[NSBundle bundleForClass:self.class] bundleIdentifier]];
	
	[defaults setBool:[sender state] == NSOnState forKey:@"RCPreferDiscreteGPU"];
}


- (IBAction)mainScreenOnlyAction:(id)sender
{
	ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:[[NSBundle bundleForClass:self.class] bundleIdentifier]];
	
	[defaults setBool:[sender state] == NSOnState forKey:@"RCMainScreenOnly"];
}


- (IBAction)okayAction:(id)sender
{
	ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:[[NSBundle bundleForClass:self.class] bundleIdentifier]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"RCUserDefaultsChangedNotification" object:nil];
	[defaults synchronize];
	[NSApp endSheet:self.window];
}


- (IBAction)restoreDefaults:(id)sender
{
	ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:[[NSBundle bundleForClass:self.class] bundleIdentifier]];
	
	[defaults setInteger:100L forKey:@"RCNumberOfCubes"];
	[defaults setInteger:1L forKey:@"RCFSAASamples"];
	[defaults setBool:NO forKey:@"RCPreferDiscreteGPU"];
	[defaults setBool:NO forKey:@"RCMainScreenOnly"];
	[self windowDidLoad];
}

@end
