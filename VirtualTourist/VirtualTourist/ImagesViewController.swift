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
	var editButtonIsTapped = false
	var newCollectionBarButtonIsTapped = false
	var mapRegion = MKCoordinateRegion()
	var pin: Pin?
	var selectedImage: Image?
	
	var editButton = UIBarButtonItem()
	
	
	// Storyboard outlets
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var newCollectionBarButton: UIBarButtonItem!
	@IBOutlet weak var bottomToolbar: UIToolbar!
	@IBOutlet weak var notificationLabel: UILabel!
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		//add edit button to navigation controller
		editButton = UIBarButtonItem(title: "Edit", style: .Plain, target: self, action: "editButtonTapped")
		self.navigationItem.rightBarButtonItem = editButton
		
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
		notificationLabel.hidden = true
		
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
	
	// edit bar button is tapped
	func editButtonTapped() {
		if editButtonIsTapped {
			editButtonIsTapped = false
			editButton.title = "Edit"
			bottomToolbar.hidden = false
			notificationLabel.hidden = true
		} else {
			editButtonIsTapped = true
			editButton.title = "Done"
			bottomToolbar.hidden = true
			notificationLabel.hidden = false
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
						
						// update the cell later, on the main thread
						dispatch_async(dispatch_get_main_queue()) {
							image.image = imageFile
							cell.imageView!.image = imageFile
							cell.loadingIndicator.stopAnimating()
						}
					}
				}
			}
		}
	}
	
	
	func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		
		if let selectedImage = fetchedResultsController.objectAtIndexPath(indexPath) as? Image {
			self.selectedImage = selectedImage
			
			if selectedImage.image != nil {
				
				if !editButtonIsTapped {
					performSegueWithIdentifier("toSelectedImageVCSegue", sender: self)
					
				} else {
					ImageCache.sharedInstance().deleteImageWithIdentifier(selectedImage.id)
					sharedContext.deleteObject(selectedImage)
					do {
						try self.sharedContext.save()
					}
					catch {
						print("error saving context")
					}
				}
			}
		}
	}
	
	
	//MARK: prepareForSegue
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "toSelectedImageVCSegue" {
			let selectedImageVC = segue.destinationViewController as! SelectedImageViewController
			selectedImageVC.image = selectedImage!
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
	func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
		
		switch type {
		case .Delete:
			collectionView.deleteItemsAtIndexPaths([indexPath!])
		default:
			break
		}
	}
	
	// MARK: newCollectionBarButtonTapped method
	@IBAction func newCollectionBarButtonTapped(sender: UIBarButtonItem) {
		newCollectionBarButtonIsTapped = true
		
		for image in (fetchedResultsController.fetchedObjects! as! [Image]) {
			
			ImageCache.sharedInstance().deleteImageWithIdentifier(image.id)
			self.sharedContext.deleteObject(image)
			do {
				try self.sharedContext.save()
			} catch {
				print("error saving context")
			}
		}
		
		self.sharedContext.performBlock() {
			Flickr.sharedInstance().getImagesFromPin(self.pin!, completionHandler: { (success, result, errorString) -> Void in
				if success {
					
					self.sharedContext.performBlock() {
						for image in self.pin!.images! {
							
							Flickr.sharedInstance().taskForImage(image.url, completionHandler: { (success, result, errorString) -> Void in
								self.sharedContext.performBlock() {
									print("\(image.id) fetched")
									image.pin = self.pin!
									ImageCache.sharedInstance().storeImage(image.image, withIdentifier: image.id)
								}
							})
							dispatch_async(dispatch_get_main_queue()) {
								self.collectionView.reloadData()
							}
						}
						do {
							try self.fetchedResultsController.performFetch()
						}
						catch {
							print("error fetching new images after refresh")
						}
					}
				}
			})
		}
		
	}
	
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
}
