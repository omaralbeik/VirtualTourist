//
//  ImagesViewController.swift
//  VirtualTourist
//
//  Created by Omar Albeik on 18/10/15.
//  Copyright © 2015 Omar Albeik. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class ImagesViewController: UIViewController, NSFetchedResultsControllerDelegate, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
	
	// Global variables
	var newCollectionBarButtonIsTapped = false
	var mapRegion = MKCoordinateRegion()
	var pin: Pin?
	var selectedImage = UIImage()
	
	// Storyboard outlets
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var newCollectionBarButton: UIBarButtonItem!
	@IBOutlet weak var bottomToolbar: UIToolbar!
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// set mapView delegate
		mapView.delegate = self
		
		// set fetchedResultsController delegate
		fetchedResultsController.delegate = self
		
		// set collectionView delegate
		collectionView.delegate = self
		
		// set collectionView data source
		collectionView.dataSource = self
		
		// set region and add the pin to mapView
		mapView.region = mapRegion
		mapView.addAnnotation(pin!)
		mapView.centerCoordinate = pin!.coordinate
		
		collectionView.backgroundColor = UIColor.whiteColor()
				
		// if no images, then hide the collectionView and show the no images label
		if pin!.images!.isEmpty == true {
			collectionView.hidden = true
		}
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		// fetch images
		do {
			try fetchedResultsController.performFetch()
		} catch {
			print("error fetching old data")
		}
	}
	
	
	//MARK: mapView Delegate methods
	func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
		
		let reuseId = "pin"
		var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
		if pinView == nil {
			pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
			pinView!.canShowCallout = false
			pinView!.pinTintColor = UIColor.blueColor()
			
			pinView!.animatesDrop = false
			
		}
		else {
			pinView!.annotation = annotation
		}
		return pinView
	}
	
	
	//    MARK: collectionView Delegate & DataSource
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		let sectionInfo = self.fetchedResultsController.sections![section]
		return sectionInfo.numberOfObjects
	}
	
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		
		let image = fetchedResultsController.objectAtIndexPath(indexPath) as! Image
		
		let imageCell = collectionView.dequeueReusableCellWithReuseIdentifier("imageCollecionViewCell", forIndexPath: indexPath) as! ImageCollectionViewCell
		
		configureCell(imageCell, image: image)
		
		return imageCell
	}
	
	// MARK: - Configure Cell
	func configureCell(cell: ImageCollectionViewCell, image: Image) {
		
		cell.imageView.image = UIImage(named: "imagePlaceHolder")
		cell.loadingIndicator.startAnimating()
		
		// Set the imageView Image
		if image.image != nil {
			cell.imageView.image = image.image
			cell.loadingIndicator.stopAnimating()
			
		} else {
			// This is the interesting case. The image URL ia available, but it is not downloaded yet.
			
			cell.loadingIndicator.startAnimating()
			
			Flickr.sharedInstance().taskForImage(image.url) { (success, result, errorString) -> Void in
				
				if let error = errorString {
					print("Poster download error: \(error)")
				}
				
				if success {
					
					if let data = result {
						// Craete the image
						let imageFile = UIImage(data: data as! NSData)
						
						// update the model, so that the infrmation gets cashed
						image.image = imageFile
						
						// update the cell later, on the main thread
						dispatch_async(dispatch_get_main_queue()) {
							cell.imageView!.image = imageFile
							cell.loadingIndicator.stopAnimating()
						}
					}
				}
			}
		}
	}
	
	func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		let selectedCell = collectionView.cellForItemAtIndexPath(indexPath) as! ImageCollectionViewCell
		selectedImage = selectedCell.imageView.image!
		performSegueWithIdentifier("toSelectedImageVCSegue", sender: self)
	}
	
	
	//MARK: prepareForSegue
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "toSelectedImageVCSegue" {
			let selectedImageVC = segue.destinationViewController as! SelectedImageViewController
			
			//TODO: connect image to selectedImageVC
			selectedImageVC.image = selectedImage
			
			
		}
	}
	
	
	// MARK: - Core Data Convenience
	
	// Shared Context from CoreDataStackManager
	var sharedContext: NSManagedObjectContext {
		return CoreDataStackManager.sharedInstance().managedObjectContext
	}
	
	// Fetched Results Controller
	lazy var fetchedResultsController: NSFetchedResultsController = {
		
		let fetchRequest = NSFetchRequest(entityName: "Image")
		fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin!)
		
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
		
		let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
			managedObjectContext: self.sharedContext,
			sectionNameKeyPath: nil,
			cacheName: nil)
		
		return fetchedResultsController
		}()
	
	// fetchedResultsController delegate methods
	func controllerDidChangeContent(controller: NSFetchedResultsController) {
		print("controller done")
	}
	
	// MARK: newCollectionBarButtonTapped method
	@IBAction func newCollectionBarButtonTapped(sender: UIBarButtonItem) {
		newCollectionBarButtonIsTapped = true
	}
	
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
}
