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
        
        // set fetchedResultsController delegate
        fetchedResultsController.delegate = self
        
        print(pin?.images?.count)
        
        // set collectionView delegate
        collectionView.delegate = self
        
        // set collectionView data source
        collectionView.dataSource = self
        
        // set region and add the pin to mapView
        mapView.region = mapRegion
        mapView.addAnnotation(pin!)
        mapView.centerCoordinate = (pin?.coordinate)!
        
        collectionView.backgroundColor = UIColor.whiteColor()
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
    
    
    //    MARK: collectionView Delegate & DataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return pin!.images!.count
        
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        // Here is how to replace the actors array using objectAtIndexPath
        
        let imageCell = collectionView.dequeueReusableCellWithReuseIdentifier("imageCollecionViewCell", forIndexPath: indexPath) as! ImageCollectionViewCell
        
        dispatch_async(dispatch_get_main_queue(), {
            imageCell.imageView!.image = self.pin!.images![indexPath.row].image
        })
        
        
        return imageCell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("toSelectedImageVCSegue", sender: self)
    }
    
    
    //MARK: prepareForSegue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toSelectedImageVCSegue" {
            let selectedImageVC = segue.destinationViewController as! SelectedImageViewController
            
            //TODO: connect image to selectedImageVC
            selectedImageVC.image = self.pin!.images![collectionView.indexPathsForSelectedItems()!.first!.row].image!
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
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        }()
    
    // fetchedResultsController delegate methods
    
    
    // MARK: newCollectionBarButtonTapped method
    @IBAction func newCollectionBarButtonTapped(sender: UIBarButtonItem) {
        newCollectionBarButtonIsTapped = true
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
