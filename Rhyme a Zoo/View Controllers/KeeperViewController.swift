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
    
    override func viewWillAppear(_ animated: Bool) {
        gender = RZQuizDatabase.getKeeperGender()
        number = RZQuizDatabase.getKeeperNumber()
        keeperUpdated(nil)
        animateGenderButtons(selected: (gender == "boy" ? boyButton : girlButton), other: (gender == "boy" ? girlButton : boyButton), animate: false)
    }
    
    func keeperUpdated(_ transition: String?) {
        let imageName = "zookeeper-\(gender)\(number)"
        let image = UIImage(named: imageName)
        
        bodyImage.image = image
        if let transition = transition {
            playTransitionForView(bodyImage, duration: 0.35, transition: transition)
        }
    }
    
    @IBAction func nextKeeper(_ sender: UIButton) {
        number += 1
        if number == 37 { number = 1 }
        RZQuizDatabase.setKeeperNumber(number)
        keeperUpdated(nil)
    }
    
    @IBAction func previousKeeper(_ sender: UIButton) {
        number -= 1
        if number == 0 { number = 36 }
        RZQuizDatabase.setKeeperNumber(number)
        keeperUpdated(nil)
    }
    
    @IBAction func setBoy(_ sender: UIButton) {
        if gender == "boy" { return }
        gender = "boy"
        RZQuizDatabase.setKeeperGender(gender)
        keeperUpdated("flip")
        animateGenderButtons(selected: boyButton, other: girlButton, animate: true)
    }
    
    @IBAction func setGirl(_ sender: UIButton) {
        if gender == "girl" { return }
        gender = "girl"
        RZQuizDatabase.setKeeperGender(gender)
        keeperUpdated("flip")
        animateGenderButtons(selected: girlButton, other: boyButton, animate: true)
    }
    
    func animateGenderButtons(selected: UIButton, other: UIButton, animate: Bool) {
        let selectedTransform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        let otherTransform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        if !animate {
            selected.transform = selectedTransform
            other.transform = otherTransform
            return
        }
        
        UIView.animate(withDuration: 0.75, delay: 0.0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0.0, options: [], animations: {
            selected.transform = selectedTransform
            other.transform = otherTransform
        }, completion: nil)
    }
    
    @IBAction func goHome(_ sender: AnyObject) {
        RZUserDatabase.saveCurrentUserToLinkedClassroom()
        self.dismiss(animated: true, completion: nil)
    }
    
}
