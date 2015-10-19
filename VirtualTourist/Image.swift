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
    
    @NSManaged var path: String
    @NSManaged var url: String
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(imageURL: String, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Image", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.url = imageURL
        
        if let url = NSURL(string: imageURL) {
            if let urlData = NSData(contentsOfURL: url) {
                if let urlImage = UIImage(data: urlData) {
                    self.image = urlImage
                }
            }
        }
    }
    
    var image: UIImage?
    
//    var image: UIImage? {
//        get {
//            return Flickr.Caches.imageCache.imageWithIdentifier(path)
//        }
//        set {
//            Flickr.Caches.imageCache.storeImage(image, withIdentifier: path)
//        }
//    }
    
}