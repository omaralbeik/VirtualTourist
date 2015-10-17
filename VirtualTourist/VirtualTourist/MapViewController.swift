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

class MapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate, UISearchBarDelegate, UIGestureRecognizerDelegate {
    
    // global variables
    var editButtonIsTapped = false
    
    // Storyboard outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editNavButton: UIBarButtonItem!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var notificationLabel: UILabel!
    @IBOutlet weak var mapLoadingActivityIndicator: UIActivityIndicatorView!
    
    // View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set mapView delegate
        mapView.delegate = self
        
        // set the fetchedResultsController delegate
        fetchedResultsController.delegate = self
        
        // set the searchBar delegate
        searchBar.delegate = self
        
        // set initial view for mapView and loading activity indicator ..
        loading(status: true)
        
        // fetch old pins
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("error fetching old data")
        }
        
        if let pins = fetchedResultsController.fetchedObjects {
            print(pins.count)
            mapView.addAnnotations(pins as! [MKPointAnnotation])
        }
        
        // handle long tap gestures
        handleLongTap()
    }
    
    
    //MARK: handle long tap gesture
    func handleLongTap() {
        let longTap = UILongPressGestureRecognizer(target: self, action: "addPin:")
        longTap.delegate = self
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
                
                getAddressFromLocation(lat: touchedPointCoordinate.latitude, long: touchedPointCoordinate.longitude, completion: { (success, locationString, error) -> Void in
                    if success {
                        // add pin to context
                        _ = Pin(lat: touchedPointCoordinate.latitude, long: touchedPointCoordinate.longitude, title: locationString!, context: self.sharedContext)
                        
                        // save the context
                        do {
                            try self.sharedContext.save()
                        }
                        catch {
                            print("error saving context")
                        }
                        
                        
                    } else {
                        
                        // add pin to context
                        _ = Pin(lat: touchedPointCoordinate.latitude, long: touchedPointCoordinate.longitude, title: nil, context: self.sharedContext)
                        
                        print("failed to geoCode")
                        self.presentMessage("Error", message: error!, action: "OK")
                        
                        // save the context
                        do {
                            try self.sharedContext.save()
                        }
                        catch {
                            print("error saving context")
                        }
                    }
                })
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
            pinView!.animatesDrop = false
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if editButtonIsTapped {
            print("tap tapped in edit mode, tap should be deleted")
            sharedContext.deleteObject(view.annotation as! Pin)
            
            // save the context
            do {
                try self.sharedContext.save()
            }
            catch {
                print("error saving context")
            }
        }
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            print("pin tapped, shoud move to pinVC")
        }
    }
    
    func mapViewDidFinishLoadingMap(mapView: MKMapView) {
        loading(status: false)
        //        print("map loaded successfully")
    }
    
    
    // MARK: - geoCoding method
    func getAddressFromLocation(lat lat: Double, long: Double, completion: (success: Bool, locationString: String?, error: String?) -> Void) {
        
        // geoLoacion help: http://stackoverflow.com/questions/27735835/convert-coordinates-to-city-name and http://stackoverflow.com/questions/29219004/clgeocoder-in-swift-unable-to-return-string-when-using-reversegeocodelocation
        
        let coordinates = CLLocation(latitude: lat, longitude: long)
        
        CLGeocoder().reverseGeocodeLocation(coordinates, completionHandler: {(placemarks, error) -> Void in
            
            if let geoCodeError = error {
                completion(success: false, locationString: nil, error: geoCodeError.localizedDescription)
            }
            
            if let placeArray = placemarks as [CLPlacemark]! {
                // Place details
                var placeMark: CLPlacemark!
                placeMark = placeArray.first
                
                var locationString = ""
                
                // Street address
                if let street = placeMark.addressDictionary?["Thoroughfare"] as? NSString
                {
                    locationString += "\(street as String) ,"
                }
                
                // City
                if let city = placeMark.addressDictionary?["City"] as? NSString
                {
                    locationString += "\(city as String) ,"
                }
                
                // Country
                if let country = placeMark.addressDictionary?["Country"] as? NSString
                {
                    locationString += country as String
                }
                
                if locationString.isEmpty {
                    completion(success: false, locationString: nil, error: "Location couldn't be geocoded")
                }
                else {
                    completion(success: true, locationString: locationString, error: nil)
                }
            }
        })
    }
    
    
    //MARK: - searchBar delegate method:
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        //        print("search tapped")
        
        if let address = searchBar.text{
            let geocoder = CLGeocoder()
            loading(status: true)
            
            geocoder.geocodeAddressString(address, completionHandler: {(placemarks, error) -> Void in
                if let _ = error {
                    
                    self.presentMessage("Location Not Found!", message: "Couldn't find the location, Please check the address.", action: "OK")
                    self.loading(status: false)
                    
                } else {
                    if let placemark = placemarks?.first {
                        //Center the map
                        let placemark = MKPlacemark(placemark: placemark)
                        let span = MKCoordinateSpanMake(1, 1)
                        let region = MKCoordinateRegion(center: placemark.location!.coordinate, span: span)
                        self.mapView.setRegion(region, animated: true)
                    }
                }
                self.loading(status: false)
            })
        }
    }
    
    func searchBarShouldEndEditing(searchBar: UISearchBar) -> Bool {
        return true
    }
    
    // dismiss keyboard if display touched
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if searchBar.isFirstResponder() {
            searchBar.resignFirstResponder()
        }
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
    
    // Fetched Results Controller Delegate methods
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        // print("fetchedResultController changed")
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject pinObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
        case .Insert:
            // print("pin inserted")
            refreshPins()
            break
        case .Delete:
            print("pin deleted")
            refreshPins()
            break
        case .Update:
            print("pin updated")
            break
        case .Move:
            print("pin moved")
            break
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
    
    // loading indicator helper method
    func loading(status status: Bool) {
        if status {
            mapView.alpha = 0.5
            mapLoadingActivityIndicator.startAnimating()
        } else {
            mapView.alpha = 1
            mapLoadingActivityIndicator.stopAnimating()
        }
    }
    
    // refreshPins helper method
    func refreshPins() {
        if let pins = fetchedResultsController.fetchedObjects {
            let annotations = mapView.annotations
            mapView.removeAnnotations(annotations)
            mapView.addAnnotations(pins as! [MKPointAnnotation])
        } else {
            print("Error refreshing map")
        }
    }
    
    // didReceiveMemoryWarning method
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
