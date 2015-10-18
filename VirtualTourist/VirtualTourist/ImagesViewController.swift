//
//  ImagesViewController.swift
//  VirtualTourist
//
//  Created by Omar Albeik on 18/10/15.
//  Copyright © 2015 Omar Albeik. All rights reserved.
//

import UIKit
import MapKit

class ImagesViewController: UIViewController, MKMapViewDelegate {
    
    // Global variables
    var newCollectionBarButtonIsTapped = false
    var mapRegion = MKCoordinateRegion()
    var pin: Pin?
//    var images = [Image]()
    
    // Storyboard outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionBarButton: UIBarButtonItem!
    @IBOutlet weak var bottomToolbar: UIToolbar!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set mapView delegate
        mapView.delegate = self
        
        mapView.region = mapRegion
        mapView.addAnnotation(pin!)
        mapView.centerCoordinate = (pin?.coordinate)!
        
        collectionView.backgroundColor = UIColor.whiteColor()
        print("\(pin!.locationString) Pin has been passed")

    }
    
    //MARK: mapView Delegate methods
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = UIColor.blueColor()
            
            pinView!.animatesDrop = true
            
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    
    @IBAction func newCollectionBarButtonTapped(sender: UIBarButtonItem) {
        newCollectionBarButtonIsTapped = true
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
