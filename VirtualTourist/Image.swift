//
//  Image.swift
//  VirtualTourist
//
//  Created by Omar Albeik on 16/10/15.
//  Copyright © 2015 Omar Albeik. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class Image: NSManagedObject {
	
	@NSManaged var url: String
	@NSManaged var id: String
	@NSManaged var path: String?
	@NSManaged var pin: Pin
	
	override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
		super.init(entity: entity, insertIntoManagedObjectContext: context)
	}
	
	init(url: String, id: String, context: NSManagedObjectContext) {
		let entity = NSEntityDescription.entityForName("Image", inManagedObjectContext: context)!
		super.init(entity: entity, insertIntoManagedObjectContext: context)
		
		self.url = url
		self.id = id
		
		path = ImageCache.Caches.imageCache.pathForIdentifier(id)
	}
	
	var image: UIImage? {
		get { return ImageCache.Caches.imageCache.imageWithIdentifier(id) }
		set { ImageCache.Caches.imageCache.storeImage(newValue, withIdentifier: id) }
	}
	
}