//
//  SetupViewController.swift
//  Rhyme a Zoo
//
//  Created by Cal on 7/16/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import Foundation
import UIKit

var RZWelcomeAnimationPlayed = false

class WelcomeViewController : UIViewController {
    
    @IBOutlet weak var welcome: UILabel!
    @IBOutlet weak var welcomePosition: NSLayoutConstraint!
    @IBOutlet weak var largeAreaContinueButton: UIButton!
    @IBOutlet weak var nextArrow: UIButton!
    var bounceTimer: Timer?
    var welcomeTimer: Timer?
    @IBOutlet weak var nextArrowPosition: NSLayoutConstraint!
    @IBOutlet weak var teacherButtonPositon: NSLayoutConstraint!
    
    override func viewWillAppear(_ animated: Bool) {
        
        if RZWelcomeAnimationPlayed { return }
        //prepare for animations
        welcome.text = "Hello"
        welcome.alpha = 0.0
        welcome.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        welcomePosition.constant = 0.0
        nextArrowPosition.constant = -UIScreen.main.bounds.height * 0.75
        teacherButtonPositon.constant = -100
        self.view.layoutIfNeeded()
        largeAreaContinueButton.isEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if RZWelcomeAnimationPlayed { return }
        //play the welcome animation through a timer
        //so it can be invalidated if the view is closed immediately
        welcomeTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(WelcomeViewController.playWelcomeAnimation), userInfo: nil, repeats: false)
    }
    
    func playWelcomeAnimation() {
        //play welcome animation
        UIView.animate(withDuration: 1.5, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.0, options: [], animations: {
            self.welcome.alpha = 1.0
            self.welcome.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }, completion: nil)
        
        UAPlayer().play("welcome", ofType: "m4a", ifConcurrent: .interrupt)
        
        delay(0.9) { self.welcome.text = "Hey" }
        delay(1.5) { self.welcome.text = "Hi" }
        delay(2.15) { self.welcome.text = "Welcome" }
        
        
        //show buttons
        delay(3.0) {
            
            RZWelcomeAnimationPlayed = true
            
            UIView.animate(withDuration: 0.8, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: [], animations: {
                self.welcomePosition.constant = 45.0
                self.nextArrowPosition.constant = -45.0
                self.teacherButtonPositon.constant = 5.0
                self.view.layoutIfNeeded()
                }, completion: { success in
                    self.largeAreaContinueButton.isEnabled = true
                    self.bounceTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: "startArrowBounce", userInfo: nil, repeats: false)
            })
            
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        bounceTimer?.invalidate()
        welcomeTimer?.invalidate()
    }
    
    func startArrowBounce() {
        self.bounceNextArrow()
        self.bounceTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(WelcomeViewController.bounceNextArrow), userInfo: nil, repeats: true)
    }
    
    func bounceNextArrow() {
        UIView.animate(withDuration: 0.6, delay: 0.0, options: .allowUserInteraction, animations: {
            self.nextArrow.transform = CGAffineTransform(translationX: 75.0, y: 0.0)
        }, completion: { success in
            UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.allowUserInteraction, animations: {
                self.nextArrow.transform = CGAffineTransform(translationX: 0.0, y: 0.0)
            }, completion: nil)
        })
    }
    
}
