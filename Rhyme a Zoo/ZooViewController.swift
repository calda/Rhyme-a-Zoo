//
//  ZooViewController.swift
//  Rhyme a Zoo
//
//  Created by Cal on 6/29/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import Foundation
import UIKit

class ZooViewController : ZookeeperGameController {

    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet var buildingButtons: [UIButton]!
    @IBOutlet weak var questionButtonLeading: NSLayoutConstraint!
    
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
    
    //MARK: - Setting Up View
    
    override func viewWillAppear(animated: Bool) {
        //update background to level
        let level = RZQuizDatabase.currentZooLevel()
        backgroundImage.image = UIImage(named: "background\(level).jpg")
        
        for button in buildingButtons {
            if button.tag > level {
                if button.tag == 7 || button.tag == 8 { button.hidden = true }
                button.setImage(UIImage(named: "button-\(button.tag)-dark"), forState: .Normal)
            }
        }
        
        let questionConstant: CGFloat
        switch(level) {
            case 7: questionConstant = 70; break;
            case 8: questionConstant = 130; break;
            case 9: questionConstant = 130; break;
            default: questionConstant = 10; break;
        }
        questionButtonLeading.constant = questionConstant
        self.view.layoutIfNeeded()
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
    
    
    //MARK: - User Interaction
    
    @IBAction func tapDetected(sender: UITapGestureRecognizer) {
        
        if let zookeeperImage = self.zookeeperImage {
            zookeeperGameTap(event: sender)
            return
        }
        
        let touch = sender.locationInView(backgroundImage)
        
        for i in 0 ..< buttonFrames.count {
            let j = buttonFrames.count - (i + 1) //go through frames backwards
            let frame = buttonFrames[j]
            if frame.contains(touch) {
                
                var building = j + 1
                if building == 8 && RZQuizDatabase.currentZooLevel() != 8 {
                    building = 7
                }
                openBuildingIfPossible(building)
                
            }
        }
    }
    
    @IBAction func buildingNumberTapped(sender: UIButton) {
        openBuildingIfPossible(sender.tag)
    }
    
    func openBuildingIfPossible(building: Int) {
        var canOpenBuilding = true
        
        let level = RZQuizDatabase.currentZooLevel()
        if level < 7 && building >= 7 { canOpenBuilding = false }
        
        if canOpenBuilding {
            
            let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("building") as! BuildingViewController
            controller.decorate(building: building, displaySize: self.view.frame.size)
            self.presentViewController(controller, animated: true, completion: nil)
            
        }
        else {
            //user doesn't have building yet
        }
    }
    
    @IBAction func panDetected(sender: UIPanGestureRecognizer) {
        zookeeperGamePan(event: sender)
    }
    
    @IBAction func pinchRecognized(sender: UIPinchGestureRecognizer) {
        zookeeperGamePinch(event: sender)
    }
    
    @IBAction func questionPressed(sender: AnyObject) {
        for i in 0 ..< numberButtonPercentages.count {
            showBuildingIcon(i + 1)
        }
    }
    
    @IBAction func levelButtonPressed(sender: AnyObject) {
        let currentLevel = RZQuizDatabase.currentZooLevel()
        showBuildingIcon(currentLevel)
    }
    
    let numberButtonPercentages = [ //points for building number icons in percentages
        CGPointMake(0.595, 0.291),
        CGPointMake(0.462, 0.206),
        CGPointMake(0.892, 0.530),
        CGPointMake(0.323, 0.329),
        CGPointMake(0.793, 0.368),
        CGPointMake(0.197, 0.482),
        CGPointMake(0.708, 0.072),
        CGPointMake(0.847, 0.089)
    ]
    
    func showBuildingIcon(buildingNumber: Int) {
        let percentagePoint = numberButtonPercentages[buildingNumber - 1]
        
        let level = RZQuizDatabase.currentZooLevel()
        if (buildingNumber == 7 || buildingNumber == 8) && level < 7 {
            return
        }
        
        let x = backgroundImage.frame.width * percentagePoint.x
        let y = backgroundImage.frame.height * percentagePoint.y
        var frame = CGRectMake(x - 20.0, y - 20.0, 40.0, 40.0) //frame inside of backgroundImage
        if iPad() {
            frame = CGRectMake(x - 30.0, y - 30.0, 60.0, 60.0)
        }
        let backgroundOrigin = backgroundImage.frame.origin
        frame.offset(dx: backgroundOrigin.x, dy: backgroundOrigin.y)
        
        let icon = UIImageView(frame: frame)
        let dark = buildingNumber > level ? "-dark" : ""
        icon.image = UIImage(named: "button-\(buildingNumber)\(dark)")!
        icon.alpha = 0.0
        self.view.addSubview(icon)
        
        UIView.animateWithDuration(0.2, animations: {
            icon.alpha = 1.0
            }, completion: { success in
                
                UIView.animateWithDuration(1.0, delay: 3.0, options: nil, animations: {
                    icon.alpha = 0.0
                    }, completion: { success in
                        icon.removeFromSuperview()
                })
                
        })
    }
    
    @IBAction func zookeeperPressed(sender: AnyObject) {
        toggleZookeeper()
    }
    
    @IBAction func homePressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}