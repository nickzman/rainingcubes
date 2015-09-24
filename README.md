# RainingCubes! A Metal tech demo & screen saver for OS X

RainingCubes is a screen saver for OS X that animates anywhere from one to thousands of multi-colored cubes doing what cubes do when they have no surface beneath them, and the force of gravity is applied to them.

That might not be too interesting on its own, but RainingCubes is the first screen saver for OS X that does its drawing using the new Metal 3D drawing API in OS X 10.11 (El Capitan). RainingCubes draws at a constant 60 FPS, supports Retina displays, supports optional FSAA (full-screen anti-aliasing), and by default draws using your Mac’s low-power GPU (if present) in order to conserve energy.

RainingCubes requires OS X 10.11 (El Capitan) or later, as well as a computer that supports the Metal API. That ought to include all Macs made in mid-2012 and later.

RainingCubes is licensed to you under the terms of the Modified BSD License. Source code is available on Github. You can use it as a template to make your own screen savers that use Metal if you wish. Patches, foreign language localizations, etc. are welcome.

## How to Install

Download the binary, then Control-click on it and choose “Open.” This will open System Preferences, which can install the screen saver for you. If you choose to install it for all users, then you will be prompted to authenticate with an administrator’s account & password in order to complete the installation (this is normal).

## How to Remove

1. Go to the Finder.
2. Press Shift-Command-G. If you chose to install it for yourself, type “~/Library/Screen Savers” (without the quotes). If you chose to install it for all users, type “/Library/Screen Savers” (also without the quotes) instead.
3. Find “RainingCubes.saver” in the list.
4. Drag its icon to the trash.

## How to Configure

The **Metal device** is the computer hardware device that will be used to render the screen saver. This device does not have to be the Mac’s “current” GPU on multi-GPU Macs. For example, on MacBook Pro models equipped with two GPUs, Metal supports rendering using the integrated GPU while the discrete GPU has been activated.

Increasing the **# of Cubes** will impress your cat(s), but will also increase the rendering burden of the CPU and GPU, possibly causing the frame rate to drop if you get too ambitious. Still, go ahead and play around with it until you find a pleasing value that doesn’t affect the frame rate (too much).

Turning on **FSAA** will make drawing smoother, at a cost to GPU performance. FSAA goes from as little as 2x to as much as 16x, depending on the multi-sample support advertised by the current Metal device.

Check **Main Screen Only** to prevent running the screen saver on screens other than the main screen. When this is enabled, other screens will just stay blank while the screen saver is running.

Check **Prefer the Discrete GPU** to force the screen saver to draw with your computer’s “default” Metal device, which corresponds to the discrete GPU on multi-GPU Macs. This will significantly improve drawing performance on a multi-GPU Mac, at the cost of additional power consumption leading to lower battery life. Changes to this setting take place the next time either System Preferences or the screen saver engine is started. This check box is not enabled if your computer has only one Metal device available.

And finally, clicking on the **Default values** button will reset all settings to their factory default values.