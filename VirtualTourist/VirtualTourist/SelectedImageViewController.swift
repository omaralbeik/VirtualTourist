//
//  SelectedImageViewController.swift
//  VirtualTourist
//
//  Created by Omar Albeik on 19/10/15.
//  Copyright © 2015 Omar Albeik. All rights reserved.
//

import UIKit

class SelectedImageViewController: UIViewController {
    
    var image = UIImage()
    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.image = image

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
