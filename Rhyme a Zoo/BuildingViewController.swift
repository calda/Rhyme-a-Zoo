//
//  ZooViewController.swift
//  Rhyme a Zoo
//
//  Created by Cal on 6/29/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import Foundation
import UIKit

class BuildingViewController : UIViewController {
    
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var blurredBackground: UIImageView!
    
    let percentageFrames = [
        "giraffe" : CGRect(origin: CGPointMake(0.637, 0.0493), size: CGSizeMake(0.318, 0.921)),
        "hippo" : CGRect(origin: CGPointMake(0.038, 0.011), size: CGSizeMake(0.378, 0.369)),
        "kangaroo" : CGRect(origin: CGPointMake(0.115, 0.433), size: CGSizeMake(0.450, 0.550)),
        "panda" : CGRect(origin: CGPointMake(0.431, 0.108), size: CGSizeMake(0.312, 0.447)),
        "ostrich" : CGRect(origin: CGPointMake(0.396, 0.192), size: CGSizeMake(0.28, 0.596)),
        "owl" : CGRect(origin: CGPointMake(-0.035, 0.08), size: CGSizeMake(0.288, 0.504)),
        "parrot" : CGRect(origin: CGPointMake(0.675, 0.085), size: CGSizeMake(0.422, 0.896)),
        "flamingo" : CGRect(origin: CGPointMake(0.12, 0.377), size: CGSizeMake(0.265, 0.664)),
        "seal" : CGRect(origin: CGPointMake(0.108, 0.397), size: CGSizeMake(0.52, 0.53)),
        "shark" : CGRect(origin: CGPointMake(0.567, 0.325), size: CGSizeMake(0.381, 0.287)),
        "squid" : CGRect(origin: CGPointMake(0.165, 0.02), size: CGSizeMake(0.302, 0.456)),
        "dolphin" : CGRect(origin: CGPointMake(0.469, 0.087), size: CGSizeMake(0.451, 0.222)),
        "wolf" : CGRect(origin: CGPointMake(0.628, 0.391), size: CGSizeMake(0.316, 0.556)),
        "lion" : CGRect(origin: CGPointMake(0.009, 0.393), size: CGSizeMake(0.527, 0.588)),
        "tiger" : CGRect(origin: CGPointMake(0.015, 0.023), size: CGSizeMake(0.3, 0.373)),
        "jaguar" : CGRect(origin: CGPointMake(0.319, 0.003), size: CGSizeMake(0.419, 0.266)),
        "alligator" : CGRect(origin: CGPointMake(0.055, 0.056), size: CGSizeMake(0.431, 0.479)),
        "iguana" : CGRect(origin: CGPointMake(0.589, 0.444), size: CGSizeMake(0.373, 0.503)),
        "turtle" : CGRect(origin: CGPointMake(0.556, 0.055), size: CGSizeMake(0.396, 0.317)),
        "rattlesnake" : CGRect(origin: CGPointMake(0.021, 0.619), size: CGSizeMake(0.388, 0.264)),
        "baboon" : CGRect(origin: CGPointMake(0.101, 0.008), size: CGSizeMake(0.183, 0.399)),
        "monkey" : CGRect(origin: CGPointMake(0.558, 0.467), size: CGSizeMake(0.315, 0.391)),
        "gorilla" : CGRect(origin: CGPointMake(0.691, 0.009), size: CGSizeMake(0.279, 0.519)),
        "chimp" : CGRect(origin: CGPointMake(0.236, 0.339), size: CGSizeMake(0.279, 0.633)),
        "pterodactyl" : CGRect(origin: CGPointMake(0.758, 0.129), size: CGSizeMake(0.29, 0.316)),
        "stegasaurus" : CGRect(origin: CGPointMake(0.281, 0.417), size: CGSizeMake(0.288, 0.25)),
        "trex" : CGRect(origin: CGPointMake(0.527, 0.197), size: CGSizeMake(0.389, 0.791)),
        "centaur" : CGRect(origin: CGPointMake(0.014, 0.309), size: CGSizeMake(0.217, 0.39)),
        "triceratop" : CGRect(origin: CGPointMake(0.021, 0.315), size: CGSizeMake(0.244, 0.36)),
        
        "dummy" : CGRectZero
    ]
    
    let buildingAnimals = [
        ["hippo", "kangaroo", "panda", "giraffe"],
        ["ostrich", "owl", "parrot", "flamingo"],
        ["shark", "squid", "dolphin", "seal"],
        ["wolf", "lion", "tiger", "jaguar"],
        ["alligator", "iguana", "turtle", "rattlesnake"],
        ["baboon", "chimp", "gorilla", "monkey"],
        ["pterodactyl", "stegasaurus", "triceratop", "trex"],
        []
        
    ]
    
    var buttonFrames: [String : CGRect] = [:]
    var building: Int!
    
    func decorate(#building: Int) {
        self.building = building
    }
    
    override func viewWillAppear(animated: Bool) {
        //update background
        let image = UIImage(named:"building\(building).jpg")
        backgroundImage.image = image
        blurredBackground.image = image
    }
    
    override func viewDidAppear(animated: Bool) {
        //generate frames for animal buttons
        buttonFrames = [:]
        let sceneSize = backgroundImage.frame.size
        
        for animal in buildingAnimals[building - 1] {
            let frame = percentageFrames[animal]!
            let origin = CGPointMake(frame.origin.x * sceneSize.width, frame.origin.y * sceneSize.height)
            let size = CGSizeMake(frame.width * sceneSize.width, frame.height * sceneSize.height)
            let imageFrame = CGRect(origin: origin, size: size)
            buttonFrames.updateValue(imageFrame, forKey: animal)
        }
        
        for animal in buildingAnimals[building - 1] {
            let userOwnsAnimal = building < 1000
            
            let image: UIImage?
            if userOwnsAnimal {
                image = UIImage(named: "\(animal)#color")
            }
            else {
               image = UIImage(named: animal)
            }
            
            let imageView = UIImageView(frame: buttonFrames[animal]!)
            imageView.image = image
            backgroundImage.addSubview(imageView)
        }
        backgroundImage.layer.masksToBounds = true
        backgroundImage.clipsToBounds = true
        
    }
    
    var origin: CGPoint?
    
    @IBAction func tapDetected(sender: UITapGestureRecognizer) {
        let touch = sender.locationInView(backgroundImage)
        let widthUnrounded = touch.x / backgroundImage.frame.width
        let heightUnrounded = touch.y / backgroundImage.frame.height
        let width = CGFloat(round(1000 * widthUnrounded) / 1000)
        let height = CGFloat(round(1000 * heightUnrounded) / 1000)
        
        if origin == nil {
            origin = CGPointMake(width, height)
        }
        else {
            let size = CGSizeMake(width - origin!.x, height - origin!.y)
            println("CGRect(origin: CGPointMake(\(origin!.x), \(origin!.y)), size: CGSizeMake(\(size.width), \(size.height))),")
            origin = nil
        }
    }
    
    @IBAction func homePressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}