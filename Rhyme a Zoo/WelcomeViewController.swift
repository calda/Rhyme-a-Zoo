//
//  SetupViewController.swift
//  Rhyme a Zoo
//
//  Created by Cal on 7/16/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import Foundation
import UIKit

class WelcomeViewController : UIViewController {
    
    @IBOutlet weak var welcome: UILabel!
    @IBOutlet weak var welcomePosition: NSLayoutConstraint!
    @IBOutlet weak var largeAreaContinueButton: UIButton!
    @IBOutlet weak var nextArrow: UIButton!
    var bounceTimer: NSTimer?
    var welcomeTimer: NSTimer?
    @IBOutlet weak var nextArrowPosition: NSLayoutConstraint!
    @IBOutlet weak var teacherButtonPositon: NSLayoutConstraint!
    
    override func viewWillAppear(animated: Bool) {
        //prepare for animations
        welcome.text = "Hello"
        welcome.alpha = 0.0
        welcome.transform = CGAffineTransformMakeScale(0.3, 0.3)
        welcomePosition.constant = 0.0
        nextArrowPosition.constant = -UIScreen.mainScreen().bounds.height * 0.75
        teacherButtonPositon.constant = -100
        self.view.layoutIfNeeded()
        largeAreaContinueButton.enabled = false
    }
    
    override func viewDidAppear(animated: Bool) {
        //play the welcome animation through a timer
        //so it can be invalidated if the view is closed immediately
        welcomeTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "playWelcomeAnimation", userInfo: nil, repeats: false)
    }
    
    func playWelcomeAnimation() {
        //play welcome animation
        UIView.animateWithDuration(1.5, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.0, options: nil, animations: {
            self.welcome.alpha = 1.0
            self.welcome.transform = CGAffineTransformMakeScale(1.0, 1.0)
            }, completion: nil)
        
        UAPlayer().play("welcome", ofType: "m4a", ifConcurrent: .Interrupt)
        
        delay(0.9) { self.welcome.text = "Hey" }
        delay(1.5) { self.welcome.text = "Hi" }
        delay(2.15) { self.welcome.text = "Welcome" }
        
        
        //show buttons
        delay(3.0) {
            
            UIView.animateWithDuration(0.8, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: nil, animations: {
                self.welcomePosition.constant = 45.0
                self.nextArrowPosition.constant = -45.0
                self.teacherButtonPositon.constant = 5.0
                self.view.layoutIfNeeded()
                }, completion: { success in
                    self.largeAreaContinueButton.enabled = true
                    delay(1.0) {
                        self.bounceNextArrow()
                        self.bounceTimer = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: "bounceNextArrow", userInfo: nil, repeats: true)
                    }
            })
            
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        bounceTimer?.invalidate()
        welcomeTimer?.invalidate()
    }
    
    func bounceNextArrow() {
        UIView.animateWithDuration(0.6, delay: 0.0, options: .AllowUserInteraction, animations: {
            self.nextArrow.transform = CGAffineTransformMakeTranslation(75.0, 0.0)
        }, completion: { success in
            UIView.animateWithDuration(0.6, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.AllowUserInteraction, animations: {
                self.nextArrow.transform = CGAffineTransformMakeTranslation(0.0, 0.0)
            }, completion: nil)
        })
    }
    
    @IBAction func launchUserCreation(sender: AnyObject) {
        
    }
    
    @IBAction func launchTeacherView(sender: AnyObject) {
    }
    
}