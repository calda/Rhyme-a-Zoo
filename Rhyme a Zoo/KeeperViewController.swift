//
//  ZookeeperViewController.swift
//  Rhyme a Zoo
//
//  Created by Cal on 7/15/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import Foundation
import UIKit

class KeeperViewController : UIViewController {
    
    @IBOutlet weak var bodyImage: UIImageView!
    var gender = "boy"
    var number = 0
    @IBOutlet weak var girlButton: UIButton!
    @IBOutlet weak var boyButton: UIButton!
    
    override func viewWillAppear(animated: Bool) {
        gender = RZQuizDatabase.getKeeperGender()
        number = RZQuizDatabase.getKeeperNumber()
        keeperUpdated(nil)
        animateGenderButtons(selected: (gender == "boy" ? boyButton : girlButton), other: (gender == "boy" ? girlButton : boyButton), animate: false)
    }
    
    func keeperUpdated(transition: String?) {
        let imageName = "zookeeper-\(gender)\(number)"
        let image = UIImage(named: imageName)
        
        bodyImage.image = image
        if let transition = transition {
            playTransitionForView(bodyImage, duration: 0.35, transition: transition)
        }
    }
    
    @IBAction func nextKeeper(sender: UIButton) {
        number += 1
        if number == 17 { number = 1 }
        RZQuizDatabase.setKeeperNumber(number)
        keeperUpdated(nil)
    }
    
    @IBAction func previousKeeper(sender: UIButton) {
        number -= 1
        if number == 0 { number = 16 }
        RZQuizDatabase.setKeeperNumber(number)
        keeperUpdated(nil)
    }
    
    @IBAction func setBoy(sender: UIButton) {
        if gender == "boy" { return }
        gender = "boy"
        RZQuizDatabase.setKeeperGender(gender)
        keeperUpdated("flip")
        animateGenderButtons(selected: boyButton, other: girlButton, animate: true)
    }
    
    @IBAction func setGirl(sender: UIButton) {
        if gender == "girl" { return }
        gender = "girl"
        RZQuizDatabase.setKeeperGender(gender)
        keeperUpdated("flip")
        animateGenderButtons(selected: girlButton, other: boyButton, animate: true)
    }
    
    func animateGenderButtons(#selected: UIButton, other: UIButton, animate: Bool) {
        let selectedTransform = CGAffineTransformMakeScale(1.0, 1.0)
        let otherTransform = CGAffineTransformMakeScale(0.75, 0.75)
        if !animate {
            selected.transform = selectedTransform
            other.transform = otherTransform
            return
        }
        
        UIView.animateWithDuration(0.75, delay: 0.0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0.0, options: nil, animations: {
            selected.transform = selectedTransform
            other.transform = otherTransform
        }, completion: nil)
    }
    
    @IBAction func goHome(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}