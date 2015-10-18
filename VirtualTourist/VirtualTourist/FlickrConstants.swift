//
//  FlickrConstants.swift
//  VirtualTourist
//
//  Created by Omar Albeik on 18/10/15.
//  Copyright © 2015 Omar Albeik. All rights reserved.
//

import Foundation

extension Flickr{
    
    struct Constants { //Basic Constants
        // MARK: - URLs
        static let BASE_URL = "https://api.flickr.com/services/rest/"
        static let METHOD_NAME = "flickr.photos.search"
        static let API_KEY = "af3a2fcc27a79472e3e795655835e4bd"
        static let EXTRAS = "url_m"
        static let DATA_FORMAT = "json"
        static let SAFE_SEARCH = "1"
        static let MAXIMUM_PER_PAGE = "250"
        static let NO_JSON_CALLBACK = "1"
        
        static let boxSideLength = 0.05 //The side in latitude,longtitude units of the square to search for photos
        static let maxNumberOfImagesToDisplay = 24 // I put a cap http://discussions.udacity.com/t/clarifications-about-the-photo-album-section-in-the-specifications/15719
    }
    
    struct MethodArguments{ //Parameter names for Method
        static let method = "method"
        static let apiKey = "api_key"
        static let bbox = "bbox"
        static let safeSearch = "safe_search"
        static let extras = "extras"
        static let format = "format"
        static let noJsonCallBack = "nojsoncallback"
        static let perPage = "per_page"
        static let page = "page"
    }
    
    struct JsonResponse{ // Json Response tags
        static let photo = "photo"
        static let photos = "photos"
        static let pages = "pages"
        static let title = "title"
        static let imageType = "url_m"
    }
    
}