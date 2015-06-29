//
//  ZooViewController.swift
//  Rhyme a Zoo
//
//  Created by Cal on 6/29/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import Foundation
import UIKit

let RZCurrentLevelKey = "currentLevel"

class ZooViewController : UIViewController {

    @IBOutlet weak var backgroundImage: UIImageView!
    
    let percentageFrames = [ //in percentages relative to the image view
        CGRect(origin: CGPointMake(0.541, 0.195), size: CGSizeMake(0.175, 0.160)),
        CGRect(origin: CGPointMake(0.356, 0.013), size: CGSizeMake(0.195, 0.278)),
        CGRect(origin: CGPointMake(0.733, 0.423), size: CGSizeMake(0.267, 0.297)),
        CGRect(origin: CGPointMake(0.244, 0.199), size: CGSizeMake(0.131, 0.198)),
        CGRect(origin: CGPointMake(0.686, 0.255), size: CGSizeMake(0.208, 0.202)),
        CGRect(origin: CGPointMake(0.066, 0.249), size: CGSizeMake(0.184, 0.365)),
        CGRect(origin: CGPointMake(0.606, 0.007), size: CGSizeMake(0.322, 0.190)),
        CGRect(origin: CGPointMake(0.606, 0.007), size: CGSizeMake(0.322, 0.190))
    ]
    
    var buttonFrames: [CGRect] = []
    
    override func viewWillAppear(animated: Bool) {
        //update background to level
        var level = data.integerForKey(RZCurrentLevelKey)
        if level == 0  {
            data.setInteger(1, forKey: RZCurrentLevelKey)
            level = 1
        }
        
        backgroundImage.image = UIImage(named: "background\(level).jpg")
    }
    
    override func viewDidAppear(animated: Bool) {
        //generate frames for the building buttons
        buttonFrames = []
        let sceneSize = backgroundImage.frame.size
        
        for frame in percentageFrames {
            let origin = CGPointMake(frame.origin.x * sceneSize.width, frame.origin.y * sceneSize.height)
            let size = CGSizeMake(frame.width * sceneSize.width, frame.height * sceneSize.height)
            buttonFrames.append(CGRect(origin: origin, size: size))
        }
    }
    
    @IBAction func tapDetected(sender: UITapGestureRecognizer) {
        
        let level = data.integerForKey(RZCurrentLevelKey)
        
        let touch = sender.locationInView(backgroundImage)
        for i in 0 ..< buttonFrames.count {
            let j = buttonFrames.count - (i + 1) //go through frames backwards
            let frame = buttonFrames[j]
            if frame.contains(touch) {
                
                let building = j + 1
                if building <= level {
                    
                    let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("building") as! BuildingViewController
                    controller.decorate(building: building)
                    self.presentViewController(controller, animated: true, completion: nil)
                    
                }
                else {
                    //user doesn't have building yet
                }
                
            }
        }
    }
    
    @IBAction func homePressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}