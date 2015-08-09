//
//  ViewController.swift
//  Rhyme a Zoo
//
//  Created by Cal on 6/28/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import UIKit
import SQLite
import CoreLocation

var data = NSUserDefaults.standardUserDefaults()
let RZMainMenuTouchDownNotification = "com.hearatale.raz.main-menu-touch-down"

class MainViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var buttonsSuperview: UIView!
    var buttonFrames: [UIButton : CGRect] = [:]
    @IBOutlet var cards: [UIButton] = []
    @IBOutlet var panGestureRecognizer: UIPanGestureRecognizer!
    @IBOutlet weak var userIcon: UIButton!
    @IBOutlet weak var userName: UIButton!
    
    @IBOutlet weak var zookeeperButton: UIButton!
    var currentZookeeper: String?
    
    override func viewWillAppear(animated: Bool) {
        if self.presentedViewController == nil {
            
            var delay = 0.0
            
            for card in cards {
                let origin = card.frame.origin
                card.frame.offset(dx: 0.0, dy: 500.0)
                
                UIView.animateWithDuration(0.7, delay: delay, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.AllowUserInteraction, animations: {
                    card.frame.origin = origin
                }, completion: nil)
                
                delay += 0.05
            }
        }
        userIcon.setImage(RZCurrentUser.icon, forState: .Normal)
        decorateUserIcon(userIcon)
        userName.setTitle(RZCurrentUser.name, forState: .Normal)
        
        RZUserDatabase.refreshUser(RZCurrentUser)
        
        if currentZookeeper != RZQuizDatabase.getKeeperString() {
            createImageForZookeeper()
        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
        //test the database because I'm dumb and deleted the Unit Tests
        /*    ALL OF THESE TESTS PASSED ON JUNE 30, 2015   */
        
        /*println(RZQuizDatabase)
        println(RZQuizDatabase.getQuiz(0).questions[0].options[0].word)
        
        for i in 0 ..< RZQuizDatabase.count {
            let quiz = RZQuizDatabase.getQuiz(i)
            for question in quiz.questions {
                let options = question.options
                let words = options.map{ return $0.word }
                let success = contains(words, question.answer)
                if !success {
                    println("A question's options array does not contain the question's answer.")
                }
            }
        }
        
        for i in 0 ..< 10 {
            println(RZQuizDatabase.getQuiz(i))
        }
        println(RZQuizDatabase.quizesForLevel(1))
        println(RZQuizDatabase.quizesForLevel(2))
        println(RZQuizDatabase.quizesForLevel(3))

        for level in 1...RZQuizDatabase.levelCount {
            let quizes = RZQuizDatabase.quizesForLevel(level)
            if quizes.count != 5 {
                println("\(level) does not have 5 quizes.")
            }
        }*/
        
        buttonFrames = [:]
        //prepare dictionary of original button frames
        for subview in buttonsSuperview.subviews {
            if let button = subview as? UIButton {
                buttonFrames.updateValue(button.frame, forKey: button)
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "touchDownNotificationRecieved:", name: RZMainMenuTouchDownNotification, object: nil)
        
        dispatch_async(RZAsyncQueue, {
            //replace icon image with aliased version
            let newSize = self.userIcon.frame.size
            let screenScale = UIScreen.mainScreen().scale
            let scaleSize = CGSizeMake(newSize.width * screenScale, newSize.height * screenScale)
            
            if let original = RZCurrentUser.icon where original.size.width > scaleSize.width {
                UIGraphicsBeginImageContext(scaleSize)
                let context = UIGraphicsGetCurrentContext()
                CGContextSetInterpolationQuality(context, kCGInterpolationHigh)
                CGContextSetShouldAntialias(context, true)
                original.drawInRect(CGRect(origin: CGPointZero, size: scaleSize))
                let newImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                dispatch_async(dispatch_get_main_queue(), {
                    self.userIcon.setImage(newImage, forState: .Normal)
                })
            }
        })
        
    }
    
    func touchDownNotificationRecieved(notification: NSNotification) {
        if let touch = notification.object as? UITouch {
            processTouchAtLocation(touch.locationInView(buttonsSuperview), state: .Began)
        }
    }
    
    @IBAction func touchRecognized(sender: UIGestureRecognizer) {
        processTouchAtLocation(sender.locationInView(buttonsSuperview), state: sender.state)
    }
    
    func processTouchAtLocation(touch: CGPoint, state: UIGestureRecognizerState) {
        //figure out which button this touch is in
        for (button, frame) in buttonFrames {
            if frame.contains(touch) {
                UIView.animateWithDuration(0.2, animations: {
                    button.transform = CGAffineTransformMakeScale(1.07, 1.07)
                })
            } else {
                UIView.animateWithDuration(0.2, animations: {
                    button.transform = CGAffineTransformMakeScale(1.0, 1.0)
                })
            }
        }
        
        //if the touch is lifted
        if state == .Ended {
            
            for (button, frame) in buttonFrames {
                UIView.animateWithDuration(0.2, animations: {
                    button.transform = CGAffineTransformMakeScale(1.0, 1.0)
                })
                
                if frame.contains(touch) {
                    if let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier(button.restorationIdentifier!) as? UIViewController {
                        if let controller = controller as? CatalogViewController {
                            controller.animatingFromHome = true
                        }
                        self.presentViewController(controller, animated: true, completion: nil)
                    }
                }
                
            }
        }
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @IBAction func editUser(sender: UIButton) {
        let editUserController = UIStoryboard(name: "User", bundle: nil).instantiateViewControllerWithIdentifier("newUser") as! NewUserViewController
        editUserController.openInEditModeForUser(RZCurrentUser)
        self.presentViewController(editUserController, animated: true, completion: nil)
    }
    
    func createImageForZookeeper() {
        async() {
            let gender = RZQuizDatabase.getKeeperGender()
            let number = RZQuizDatabase.getKeeperNumber()
            let imageName = "zookeeper-\(gender)\(number)"
            
            let foreground = UIImage(named: "home-zookeeper-foreground" + (iPad() ? "-large" : ""))!
            let zookeeper = UIImage(named: imageName)!
            let background = UIImage(named: "home-zookeeper-background" + (iPad() ? "-large" : ""))!
            
            UIGraphicsBeginImageContextWithOptions(background.size, false, 1)
            background.drawAtPoint(CGPointZero)
            
            //draw zookeeper in center
            var origin = CGPointMake(159, 422)
            var size = CGSizeMake(720, 1250)
            
            if !iPad() {
                origin = CGPointMake(origin.x / 2, origin.y / 2)
                size = CGSizeMake(size.width / 2, size.height / 2)
            }
            
            zookeeper.drawInRect(CGRect(origin: origin, size: size))
            
            foreground.drawAtPoint(CGPointZero)
            
            let composite = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            self.zookeeperButton.setImage(composite, forState: .Normal)
            self.currentZookeeper = RZQuizDatabase.getKeeperString()
        }
    }
    
}

class TouchView: UIImageView {

    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        //gesture recognizers can't handle touch down on their own
        let touch = touches.first as! UITouch
        NSNotificationCenter.defaultCenter().postNotificationName(RZMainMenuTouchDownNotification, object: touch, userInfo: nil)
    }

}
