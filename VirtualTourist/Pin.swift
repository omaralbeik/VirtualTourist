//
//  Pin.swift
//  VirtualTourist
//
//  Created by Omar Albeik on 16/10/15.
//  Copyright © 2015 Omar Albeik. All rights reserved.
//

import Foundation
import CoreData
import MapKit

class Pin: NSManagedObject, MKAnnotation {
    
    struct Keys {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
        static let locationString = "locationString"
    }
    
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var locationString: String
    @NSManaged var images: [Image]?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(lat: Double, long: Double, title: String?, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.latitude = lat
        self.longitude = long

        if let titleString = title {
            locationString = titleString
        } else {
            locationString = "Pin"
        }
    }
    
    
    // Computed property that returns a coordinate from two string values
    var coordinate: CLLocationCoordinate2D {
        
        get {
            return CLLocationCoordinate2D(latitude: latitude.doubleValue , longitude: longitude.doubleValue)
        }
        set {
            self.latitude = newValue.latitude
            self.longitude = newValue.longitude
        }
    }
    
    // Annotation title and subtitle
    var title: String? {
        return locationString
    }
    
}
