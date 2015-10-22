//
//  SelectedImageViewController.swift
//  VirtualTourist
//
//  Created by Omar Albeik on 19/10/15.
//  Copyright © 2015 Omar Albeik. All rights reserved.
//

import UIKit

class SelectedImageViewController: UIViewController {
	
	var image: Image?
	@IBOutlet weak var imageView: UIImageView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if let image = image?.image {
			imageView.image = image
			
			//add edit button to navigation controller
			let editButton = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "shareButtonTapped")
			self.navigationItem.rightBarButtonItem = editButton
			
		}
	}
	
	func shareButtonTapped() {
		let activityVC = UIActivityViewController(activityItems: [image!.image!], applicationActivities: nil)
		presentViewController(activityVC, animated: true, completion: nil)
		activityVC.completionWithItemsHandler = {
			button in
			// check if activity completed:
			if button.1 == true {
				self.dismissViewControllerAnimated(true, completion: nil)
			}
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	
}
