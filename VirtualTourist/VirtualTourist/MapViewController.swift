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
	
	typealias CompletionHandler = (success: Bool, result: AnyObject!, errorString: String?) -> Void
	
	// global variables
	var editButtonIsTapped = false
	
	// The path where map region info will be saved
	var filePath : String {
		let manager = NSFileManager.defaultManager()
		let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
		return url.URLByAppendingPathComponent("mapRegion").path!
	}
	
	// Storyboard outlets
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var editNavButton: UIBarButtonItem!
	@IBOutlet weak var searchBar: UISearchBar!
	@IBOutlet weak var notificationLabel: UILabel!
	@IBOutlet weak var mapLoadingActivityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var loadingView: UIView!
	
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
		
		// restore old map location
		restoreMapRegion(true)
		
		// fetch old pins
		do {
			try fetchedResultsController.performFetch()
		} catch {
			print("error fetching old data")
		}
		
		if let pins = fetchedResultsController.fetchedObjects {
			print("App launched successfully with a total of \(pins.count) pins.")
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
		if !Reachability.isConnectedToNetwork() {
			presentMessage("No Internet", message: "Your device is not connected to the internet, please connect it and try again", action: "OK")
			return
		}
		
		// add the pin only when gesture begins to prevent adding multiple pins when gesture state changes
		if gestureRecognizer.state == .Began {
			
			loadingView.hidden = false
			
			let touchedPoint = gestureRecognizer.locationInView(mapView)
			let touchedPointCoordinate = mapView.convertPoint(touchedPoint, toCoordinateFromView: mapView)
			
			getAddressFromLocation(touchedPointCoordinate, completion: { (success, result, errorString) -> Void in
				
				if !success {
					// add pin to context
					let pin = Pin(lat: touchedPointCoordinate.latitude, long: touchedPointCoordinate.longitude, title: nil, context: self.sharedContext)
					self.mapView.addAnnotation(pin)
					
					print("failed to geoCode")
					self.presentMessage("Error", message: errorString!, action: "OK")
					
					Flickr.sharedInstance().getImagesFromPin(pin, completionHandler: { (success, result, errorString) -> Void in
						for image in  pin.images! {
							
							Flickr.sharedInstance().taskForImage(image.url, completionHandler: { (success, result, errorString) -> Void in
								self.sharedContext.performBlock() {
									print("\(image.id) fetched")
								}
							})
						}
						dispatch_async(dispatch_get_main_queue()) {
							self.loadingView.hidden = true
						}
					})
					
					// save the context
					do {
						try self.sharedContext.save()
					}
					catch {
						print("error saving context")
					}
					
					return
				}
				
				// add pin to context
				let pin = Pin(lat: touchedPointCoordinate.latitude, long: touchedPointCoordinate.longitude, title: result as? String, context: self.sharedContext)
				self.mapView.addAnnotation(pin)
				
				// save the context
				do {
					try self.sharedContext.save()
				}
				catch {
					print("error saving context")
				}
				
				Flickr.sharedInstance().getImagesFromPin(pin, completionHandler: { (success, result, errorString) -> Void in
					if success {
						for image in  pin.images! {
							Flickr.sharedInstance().taskForImage(image.url, completionHandler: { (success, result, errorString) -> Void in
								self.sharedContext.performBlock() {
									print("\(image.id) fetched")
								}
							})
						}
						dispatch_async(dispatch_get_main_queue()) {
							self.loadingView.hidden = true
						}
					}
				})
				
				
				
			})
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
	
	
	// MARK: geoCoding method
	func getAddressFromLocation(coordinates: CLLocationCoordinate2D, completion: CompletionHandler) {
		
		// geoLoacion help: http://stackoverflow.com/questions/27735835/convert-coordinates-to-city-name and http://stackoverflow.com/questions/29219004/clgeocoder-in-swift-unable-to-return-string-when-using-reversegeocodelocation
		
		let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
		
		CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
			
			if let geoCodeError = error {
				completion(success: false, result: nil, errorString: geoCodeError.localizedDescription)
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
					completion(success: false, result: nil, errorString: "Location couldn't be geocoded")
				}
				else {
					completion(success: true, result: locationString, errorString: nil)
				}
			}
		})
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
			sharedContext.deleteObject(view.annotation as! Pin)
			
			if let images = (view.annotation as! Pin).images {
				for image in images {
					ImageCache.sharedInstance().deleteImageWithIdentifier(image.id)
				}
			}
			
			
			mapView.removeAnnotation(view.annotation!)
			
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
			
			if editButtonIsTapped {
				sharedContext.deleteObject(view.annotation as! Pin)
				
				// save the context
				do {
					try self.sharedContext.save()
				}
				catch {
					print("error saving context")
				}
				
				return
			}
			
			dispatch_async(dispatch_get_main_queue(), {
				self.loadingView.hidden = true
				self.performSegueWithIdentifier("toImageVCSegue", sender: self)
			})
		}
	}
	
	func mapViewDidFinishLoadingMap(mapView: MKMapView) {
		loading(status: false)
	}
	
	func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
		saveMapRegion()
	}
	
	// save map region
	func saveMapRegion() {
		
		// Place the "center" and "span" of the map into a dictionary
		// The "span" is the width and height of the map in degrees.
		// It represents the zoom level of the map.
		
		let dictionary = [
			"latitude" : mapView.region.center.latitude,
			"longitude" : mapView.region.center.longitude,
			"latitudeDelta" : mapView.region.span.latitudeDelta,
			"longitudeDelta" : mapView.region.span.longitudeDelta
		]
		
		// Archive the dictionary into the filePath
		NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
	}
	
	// restore map region
	func restoreMapRegion(animated: Bool) {
		
		// if we can unarchive a dictionary, we will use it to set the map back to its
		// previous center and span
		if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
			
			let longitude = regionDictionary["longitude"] as! CLLocationDegrees
			let latitude = regionDictionary["latitude"] as! CLLocationDegrees
			let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
			
			let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
			let latitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
			let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
			
			let savedRegion = MKCoordinateRegion(center: center, span: span)
			mapView.setRegion(savedRegion, animated: animated)
		}else{
			let span = MKCoordinateSpanMake(80, 80)
			let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40.628595, longitude: 22.945351), span: span)
			self.mapView.setRegion(region, animated: true)
		}
	}
	
	
	// MARK: prepareForSegue
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		
		if segue.identifier == "toImageVCSegue" {
			let imagesVC = segue.destinationViewController as! ImagesViewController
			imagesVC.mapRegion = self.mapView.region
			imagesVC.pin = self.mapView.selectedAnnotations.first as? Pin
		}
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
						let span = MKCoordinateSpanMake(0.1, 0.1)
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
	
	
	//MARK: - editNavButonTapped method
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
	
	// didReceiveMemoryWarning method
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}
