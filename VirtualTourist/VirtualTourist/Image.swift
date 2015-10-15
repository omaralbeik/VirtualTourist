//
//  Image.swift
//  VirtualTourist
//
//  Created by Omar Albeik on 15/10/15.
//  Copyright © 2015 Omar Albeik. All rights reserved.
//

import UIKit
import CoreData

@objc(Image)

class Image: NSManagedObject {
    
    @NSManaged var imageUrl: String
    @NSManaged var imageData: NSData?
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(imageURL: String, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Image", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.imageUrl = imageURL
        
        if let url = NSURL(string: imageURL) {
            if let data = NSData(contentsOfURL: url) {
                self.imageData = data
            }
        }
    }
}
