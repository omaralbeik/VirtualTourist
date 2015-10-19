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
    
    @NSManaged var imagePath: String?
    @NSManaged var imageUrl: String?
    @NSManaged var pin: NSManagedObject?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(imageURL: String, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Image", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.imageUrl = imageURL
        
    }
}