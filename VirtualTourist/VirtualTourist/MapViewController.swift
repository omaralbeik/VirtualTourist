//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Omar Albeik on 15/10/15.
//  Copyright © 2015 Omar Albeik. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    // global variables
    var editButtonIsTapped = false
    
    // Storyboard outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editNavButton: UIBarButtonItem!
    @IBOutlet weak var notificationLabel: UILabel!
    @IBOutlet weak var mapLoadingActivityIndicator: UIActivityIndicatorView!
    
    // View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set mapView delegate
        mapView.delegate = self
        
        // set the fetchedResultsController delegate
        fetchedResultsController.delegate = self
        
        // set initial view for mapView and loading activity indicator ..
        mapView.alpha = 0.5
        mapLoadingActivityIndicator.startAnimating()
        
        // handle long tap gestures
        handleLongTap()
        
    }
    
    //MARK: handle long tap gesture
    func handleLongTap() {
        let longTap = UILongPressGestureRecognizer(target: self, action: "addPin:")
        longTap.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longTap)
    }
    
    func addPin(gestureRecognizer:UIGestureRecognizer) {
        
        // first things first, check if device is connected to internet:
        if Reachability.isConnectedToNetwork() {
            // add the pin only when gesture begins to prevent adding multiple pins
            if gestureRecognizer.state == .Began {
                let touchedPoint = gestureRecognizer.locationInView(mapView)
                let touchedPointCoordinate = mapView.convertPoint(touchedPoint, toCoordinateFromView: mapView)
                
                // geoLoacion source: http://stackoverflow.com/questions/27735835/convert-coordinates-to-city-name
                
                let location = CLLocation(latitude: touchedPointCoordinate.latitude, longitude: touchedPointCoordinate.longitude)
                let geoCoder = CLGeocoder()
                
                var locationString = ""
                
                geoCoder.reverseGeocodeLocation(location) {
                    (placemarks, error) -> Void in
                    
                    if let geoCodeError = error {
                        print(geoCodeError)
                        self.presentMessage("Error", message: "\(geoCodeError.localizedDescription)", action: "OK")
                        return
                    }
                    
                    if let placeArray = placemarks as [CLPlacemark]! {
                        // Place details
                        var placeMark: CLPlacemark!
                        placeMark = placeArray.first
                        
                        // Street address
                        if let street = placeMark.addressDictionary?["Thoroughfare"] as? NSString
                        {
                            // print(street)
                            locationString += "\(street as String) ,"
                        }
                        
                        // City
                        if let city = placeMark.addressDictionary?["City"] as? NSString
                        {
                            // print(city)
                            locationString += "\(city as String) ,"
                        }
                        
                        // Country
                        if let country = placeMark.addressDictionary?["Country"] as? NSString
                        {
                            // print(country)
                            locationString += country as String
                        }
                        print(locationString)
                        //TODO: pin object should be added to context and to the mapView
                    }
                }
            }
        }
        else {
            presentMessage("No Internet", message: "Your device is not connected to the internet, please connect and try again", action: "OK")
        }
    }
    
    
    //MARK: mapView Delegate methods
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = UIColor.blueColor()
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
            pinView!.animatesDrop = true
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if editButtonIsTapped {
            print("tap tapped in edit mode, tap should be deleted")
        }
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            print("pin tapped, shoud move to pinVC")
        }
    }
    
    func mapViewDidFinishLoadingMap(mapView: MKMapView) {
        mapView.alpha = 1
        mapLoadingActivityIndicator.stopAnimating()
        print("map loaded successfully")
    }
    
    
    // MARK: - Core Data Convenience
    
    // Shared Context from CoreDataStackManager
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    // Fetched Results Controller
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
        }()
    
    // Fetched Results Controller Delegate
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        print("fetchedResultController changed")
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject pinObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
        case .Insert:
            print("pin inserted")
        case .Delete:
            print("pin deleted")
        case .Update:
            print("pin updated")
        case .Move:
            print("oin moved")
        }
    }
    
    
    //MARK: - EditButtonTapped method
    
    @IBAction func editNavButonTapped(sender: UIBarButtonItem) {
        if editButtonIsTapped {
            editButtonIsTapped = false
            notificationLabel.hidden = true
            editNavButton.title = "Edit"
        } else {
            editButtonIsTapped = true
            notificationLabel.hidden = false
            editNavButton.title = "Done"
        }
    }
    
    //MARK: Present a message helper method:
    func presentMessage(title: String, message: String, action: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: action, style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // didReceiveMemoryWarning method
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
