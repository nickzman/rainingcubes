//
//  ViewController.swift
//  RainingCubesTest
//
//  Created by Nick Zitzmann on 8/23/20.
//  Copyright © 2020 Nick Zitzmann. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
	var rainingCubesView : RainingCubesView!

	override func viewDidAppear() {
		rainingCubesView = RainingCubesView.init(frame: CGRect(x: 0.0, y: 0.0, width: self.view.frame.size.width, height: self.view.frame.size.height), isPreview: false)
		
		super.viewDidAppear()
		rainingCubesView!.translatesAutoresizingMaskIntoConstraints = false
		self.view.addSubview(rainingCubesView!)
		self.view.leadingAnchor.constraint(equalTo: rainingCubesView!.leadingAnchor).isActive = true
		self.view.trailingAnchor.constraint(equalTo: rainingCubesView!.trailingAnchor).isActive = true
		self.view.topAnchor.constraint(equalTo: rainingCubesView!.topAnchor).isActive = true
		self.view.bottomAnchor.constraint(equalTo: rainingCubesView!.bottomAnchor).isActive = true
		rainingCubesView?.startAnimation()
	}

	@IBAction func preferencesAction(sender: NSMenuItem) {
		guard let configureSheet = rainingCubesView.configureSheet else {
			return
		}
		
		self.view.window?.beginSheet(configureSheet, completionHandler: nil)
	}
}

