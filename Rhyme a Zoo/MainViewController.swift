//
//  ViewController.swift
//  Rhyme a Zoo
//
//  Created by Cal on 6/28/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import UIKit
import SQLite

let data = NSUserDefaults.standardUserDefaults()
let RZMainMenuTouchDownNotification = "com.hearatale.raz.main-menu-touch-down"

class MainViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var buttonsSuperview: UIView!
    var buttonFrames: [UIButton : CGRect] = [:]
    @IBOutlet var panGestureRecognizer: UIPanGestureRecognizer!
    
    override func viewWillAppear(animated: Bool) {
        //set gradient
        let gradient = CAGradientLayer()
        gradient.frame = UIScreen.mainScreen().bounds
        gradient.colors = [
            UIColor(red: 35.0 / 255.0, green: 77.0 / 255.0, blue: 164.0 / 255.0, alpha: 1.0).CGColor,
            UIColor(red: 63.0 / 255.0, green: 175.0 / 255.0, blue: 245.0 / 255.0, alpha: 1.0).CGColor
        ]
        self.view.layer.insertSublayer(gradient, atIndex: 0)
        self.view.backgroundColor = UIColor.clearColor()
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
                    button.transform = CGAffineTransformMakeScale(1.1, 1.1)
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
    
}

class TouchView: UIImageView {

    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        //gesture recognizers can't handle touch down on their own
        let touch = touches.first as! UITouch
        NSNotificationCenter.defaultCenter().postNotificationName(RZMainMenuTouchDownNotification, object: touch, userInfo: nil)
    }

}
