//
//  Flickr.swift
//  VirtualTourist
//
//  Created by Omar Albeik on 18/10/15.
//  Copyright © 2015 Omar Albeik. All rights reserved.
//

import UIKit

class Flickr: NSObject {
	
	// Global variables
	var session : NSURLSession
	var totalPages : Int?
	
	typealias CompletionHandler = (success: Bool, result: AnyObject!, errorString: String?) -> Void
	
	// sharedContext
	var sharedContext = {
		CoreDataStackManager.sharedInstance().managedObjectContext
		}()
	
	
	// Shared session
	override init() {
		session = NSURLSession.sharedSession()
		super.init()
	}
	
	
	// Get the number of pages of results for our Flickr search location
	func getImagesFromPin(pin: Pin, completionHandler: CompletionHandler) {
		
		// Compile necessary info, create our url, and create the request
		
		let methodArguments = [
			MethodArguments.method: Constants.METHOD_NAME,
			MethodArguments.apiKey: Constants.API_KEY,
			MethodArguments.bbox: createBoundingBoxString(pin),
			MethodArguments.safeSearch: Constants.SAFE_SEARCH,
			MethodArguments.extras: Constants.EXTRAS,
			MethodArguments.format: Constants.DATA_FORMAT,
			MethodArguments.perPage: Constants.MAXIMUM_PER_PAGE,
			MethodArguments.noJsonCallBack: Constants.NO_JSON_CALLBACK
		]
		
		let urlString = Constants.BASE_URL + escapedParameters(methodArguments)
		let url = NSURL(string: urlString)!
		let request = NSURLRequest(URL: url)
		
		let task = session.dataTaskWithRequest(request) { (data, response, error) in
			
			/* GUARD: Was there an error? */
			guard (error == nil) else {
				print("There was an error with your request: \(error)")
				completionHandler(success: false, result: nil, errorString: error?.localizedDescription)
				return
			}
			
			/* GUARD: Did we get a successful 2XX response? */
			guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
				if let response = response as? NSHTTPURLResponse {
					
					print("Your request returned an invalid response! Status code: \(response.statusCode)!")
					completionHandler(success: false, result: nil, errorString: "Your request returned an invalid response! Status code: \(response.statusCode)!")
					
				}
				else if let response = response {
					
					print("Your request returned an invalid response! Response: \(response)!")
					completionHandler(success: false, result: nil, errorString: "Your request returned an invalid response!: \(response)!")
					
				}
				else {
					
					print("Your request returned an invalid response!")
					completionHandler(success: false, result: nil, errorString: "Your request returned an invalid response!")
					
				}
				return
			}
			
			/* GUARD: Was there any data returned? */
			guard let data = data else {
				print("No data was returned by the request!")
				completionHandler(success: false, result: nil, errorString: "No data was returned by the request!")
				return
			}
			
			/* Parse the data! */
			let parsedResult: AnyObject!
			do {
				parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
			} catch {
				parsedResult = nil
				print("Could not parse the data as JSON: '\(data)'")
				completionHandler(success: false, result: nil, errorString: "Could not parse the data")
				return
			}
			
			/* GUARD: Did Flickr return an error? */
			guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
				print("Flickr API returned an error. See error code and message in \(parsedResult)")
				completionHandler(success: false, result: nil, errorString: "Flicke error")
				
				return
			}
			
			/* GUARD: Is "photos" key in our result? */
			guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
				print("Cannot find keys 'photos' in \(parsedResult)")
				completionHandler(success: false, result: nil, errorString: "Cannot find photos")
				return
			}
			
			/* GUARD: Is "photo" key in the photosDictionary? */
			guard let photos = photosDictionary["photo"] as? NSArray else {
				print("Cannot find key 'photo' in \(photosDictionary)")
				completionHandler(success: false, result: nil, errorString: "Cannot find photos")
				return
			}
			
			for photo in photos {
				let id = photo["id"] as! String
				let url = photo["url_m"] as! String
				
				let image = Image(url: url, id: id, context: self.sharedContext)
				image.pin = pin
			}
			
			do {
				try self.sharedContext.save()
			}
			catch {
				print("error saving context")
			}
			
			completionHandler(success: true, result: pin.images, errorString: nil)
		}
		task.resume()
	}
	
	// MARK: - All purpose task method for images
	func taskForImage(url: String, completionHandler: CompletionHandler) -> NSURLSessionDataTask {
		let url = NSURL(string: url)
		
		let task = session.dataTaskWithURL(url!) { (data, response, downloadError) -> Void in
			
			if let error = downloadError {
				completionHandler(success: false, result: nil, errorString: error.localizedDescription)
			} else {
				completionHandler(success: true, result: data, errorString: nil)
			}
		}
		task.resume()
		return task
	}
	
	
	// MARK: Escape HTML Parameters
	func escapedParameters(parameters: [String : AnyObject]) -> String {
		
		var urlVars = [String]()
		
		for (key, value) in parameters {
			
			/* Make sure that it is a string value */
			let stringValue = "\(value)"
			
			/* Escape it */
			let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
			
			/* Append it */
			urlVars += [key + "=" + "\(escapedValue!)"]
			
		}
		return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
	}
	
	// MARK: Lat/Lon Manipulation
	func createBoundingBoxString(pin: Pin) -> String {
		
		let latitude = (pin.latitude).doubleValue
		let longitude = (pin.longitude).doubleValue
		
		/* Fix added to ensure box is bounded by minimum and maximums */
		let bottom_left_lon = max(longitude - Constants.BOUNDING_BOX_HALF_WIDTH, Constants.LON_MIN)
		let bottom_left_lat = max(latitude - Constants.BOUNDING_BOX_HALF_HEIGHT, Constants.LAT_MIN)
		let top_right_lon = min(longitude + Constants.BOUNDING_BOX_HALF_HEIGHT, Constants.LON_MAX)
		let top_right_lat = min(latitude + Constants.BOUNDING_BOX_HALF_HEIGHT, Constants.LAT_MAX)
		
		return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
	}
	
	// Create global instance of Flickr to use throughout the app
	class func sharedInstance() -> Flickr {
		struct Singleton {
			static var sharedInstance = Flickr()
		}
		return Singleton.sharedInstance
	}
}