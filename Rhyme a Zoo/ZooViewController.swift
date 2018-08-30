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
        CGRect(origin: CGPoint(x: 0.541, y: 0.195), size: CGSize(width: 0.175, height: 0.160)),
        CGRect(origin: CGPoint(x: 0.356, y: 0.013), size: CGSize(width: 0.195, height: 0.278)),
        CGRect(origin: CGPoint(x: 0.733, y: 0.423), size: CGSize(width: 0.267, height: 0.297)),
        CGRect(origin: CGPoint(x: 0.244, y: 0.199), size: CGSize(width: 0.131, height: 0.198)),
        CGRect(origin: CGPoint(x: 0.686, y: 0.255), size: CGSize(width: 0.208, height: 0.202)),
        CGRect(origin: CGPoint(x: 0.066, y: 0.249), size: CGSize(width: 0.184, height: 0.365)),
        CGRect(origin: CGPoint(x: 0.606, y: 0.007), size: CGSize(width: 0.322, height: 0.190)),
        CGRect(origin: CGPoint(x: 0.606, y: 0.007), size: CGSize(width: 0.322, height: 0.190))
    ]
    
    var buttonFrames: [CGRect] = []
    
    //MARK: - Setting Up View
    
    override func viewWillAppear(_ animated: Bool) {
        //update background to level
        let level = RZQuizDatabase.currentZooLevel()
        backgroundImage.image = UIImage(named: "background\(level).jpg")
        
        for button in buildingButtons {
            if button.tag > level {
                if button.tag == 7 || button.tag == 8 { button.isHidden = true }
                button.setImage(UIImage(named: "button-\(button.tag)-dark"), for: UIControlState())
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
    
    override func viewDidAppear(_ animated: Bool) {
        //generate frames for the building buttons
        buttonFrames = []
        let sceneSize = backgroundImage.frame.size
        
        for frame in percentageFrames {
            let origin = CGPoint(x: frame.origin.x * sceneSize.width, y: frame.origin.y * sceneSize.height)
            let size = CGSize(width: frame.width * sceneSize.width, height: frame.height * sceneSize.height)
            buttonFrames.append(CGRect(origin: origin, size: size))
        }
    }
    
    
    //MARK: - User Interaction
    
    @IBAction func tapDetected(_ sender: UITapGestureRecognizer) {
        
        if self.zookeeperImage != nil {
            zookeeperGameTap(event: sender)
            return
        }
        
        let touch = sender.location(in: backgroundImage)
        
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
    
    @IBAction func buildingNumberTapped(_ sender: UIButton) {
        openBuildingIfPossible(sender.tag)
    }
    
    func openBuildingIfPossible(_ building: Int) {
        var canOpenBuilding = true
        
        let level = RZQuizDatabase.currentZooLevel()
        if level < 7 && building >= 7 { canOpenBuilding = false }
        
        if canOpenBuilding {
            
            let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "building") as! BuildingViewController
            controller.decorate(building: building, displaySize: self.view.frame.size)
            self.present(controller, animated: true, completion: nil)
            
        }
        else {
            //user doesn't have building yet
        }
    }
    
    @IBAction func panDetected(_ sender: UIPanGestureRecognizer) {
        zookeeperGamePan(event: sender)
    }
    
    @IBAction func pinchRecognized(_ sender: UIPinchGestureRecognizer) {
        zookeeperGamePinch(event: sender)
    }
    
    @IBAction func questionPressed(_ sender: AnyObject) {
        for i in 0 ..< numberButtonPercentages.count {
            showBuildingIcon(i + 1)
        }
    }
    
    @IBAction func levelButtonPressed(_ sender: AnyObject) {
        let currentLevel = RZQuizDatabase.currentZooLevel()
        showBuildingIcon(currentLevel)
    }
    
    let numberButtonPercentages = [ //points for building number icons in percentages
        CGPoint(x: 0.595, y: 0.291),
        CGPoint(x: 0.462, y: 0.206),
        CGPoint(x: 0.892, y: 0.530),
        CGPoint(x: 0.323, y: 0.329),
        CGPoint(x: 0.793, y: 0.368),
        CGPoint(x: 0.197, y: 0.482),
        CGPoint(x: 0.708, y: 0.072),
        CGPoint(x: 0.847, y: 0.089)
    ]
    
    func showBuildingIcon(_ buildingNumber: Int) {
        let percentagePoint = numberButtonPercentages[buildingNumber - 1]
        
        let level = RZQuizDatabase.currentZooLevel()
        if (buildingNumber == 7 || buildingNumber == 8) && level < 7 {
            return
        }
        
        let x = backgroundImage.frame.width * percentagePoint.x
        let y = backgroundImage.frame.height * percentagePoint.y
        var frame = CGRect(x: x - 20.0, y: y - 20.0, width: 40.0, height: 40.0) //frame inside of backgroundImage
        if iPad() {
            frame = CGRect(x: x - 30.0, y: y - 30.0, width: 60.0, height: 60.0)
        }
        let backgroundOrigin = backgroundImage.frame.origin
        frame = frame.offsetBy(dx: backgroundOrigin.x, dy: backgroundOrigin.y)
        
        let icon = UIImageView(frame: frame)
        let dark = buildingNumber > level ? "-dark" : ""
        icon.image = UIImage(named: "button-\(buildingNumber)\(dark)")!
        icon.alpha = 0.0
        self.view.addSubview(icon)
        
        UIView.animate(withDuration: 0.2, animations: {
            icon.alpha = 1.0
            }, completion: { success in
                
                UIView.animate(withDuration: 1.0, delay: 3.0, options: [], animations: {
                    icon.alpha = 0.0
                    }, completion: { success in
                        icon.removeFromSuperview()
                })
                
        })
    }
    
    @IBAction func zookeeperPressed(_ sender: AnyObject) {
        toggleZookeeper()
    }
    
    @IBAction func homePressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
