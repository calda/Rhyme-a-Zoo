//
//  PasscodeViewController.swift
//  Rhyme a Zoo
//
//  Created by Cal on 7/27/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import Foundation
import UIKit

class PasscodeViewController : UIViewController {
    
    @IBOutlet var inputButtons: [UIImageView]!
    @IBOutlet var outputButtons: [UIImageView]!
    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var displayView: UIView!
    
    var input: NSString = ""
    var correctPasscode: Int = 1234
    var completion: (Bool) -> () = { _ in }
    
    override func viewWillAppear(animated: Bool) {
        sortOutletCollectionByTag(&inputButtons)
        sortOutletCollectionByTag(&outputButtons)
        
        for button in outputButtons {
            button.transform = CGAffineTransformMakeScale(0.5, 0.5)
        }
    }
    
    @IBAction func touchDetected(sender: UITouchGestureRecognizer) {
        
        let touch = sender.locationInView(buttonView)
        if sender.state == .Ended {
            animateButtons(selected: nil)
        }
        
        for button in inputButtons {
            if button.frame.contains(touch) {
                
                if sender.state == .Ended {
                    userTappedButton(button.tag)
                }
                else {
                    animateButtons(selected: button.tag)
                }
            }
        }
        
    }
    
    func animateButtons(#selected: Int?) {
        for button in inputButtons {
            let scale: CGFloat = (selected != nil && selected! == button.tag ? 1.2 : 1.0)
            UIView.animateWithDuration(0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: nil, animations: {
                button.transform = CGAffineTransformMakeScale(scale, scale)
            }, completion: nil)
        }
    }
    
    func userTappedButton(tag: Int) {
        //change the input variable
        if tag == 11 {
            //backspace
            if input.length != 0 {
                input = input.substringToIndex(input.length - 1)
            }
        } else {
            input = "\(input)\(tag)"
        }
        
        //display the new screen
        for button in outputButtons {
            button.alpha = (button.tag <= input.length ? 1.0 : 0.5)
            let scale = button.alpha
            UIView.animateWithDuration(0.3, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: nil, animations: {
                button.transform = CGAffineTransformMakeScale(scale, scale)
            }, completion: nil)
        }
        
        if input.length == 4 {
            if "\(input)".toInt() == correctPasscode {
                self.view.userInteractionEnabled = false
                delay(0.3) {
                    self.completion(true)
                }
            } else {
                shakeView(displayView)
                UIView.animateWithDuration(0.3, animations: {
                    for button in self.outputButtons {
                        button.alpha = 0.5
                        button.transform = CGAffineTransformMakeScale(0.5, 0.5)
                    }
                })
                input = ""
            }
        }
    }

    @IBAction func cancelPasscode(sender: AnyObject) {
        completion(false)
    }
    
}

func requestPasscode(passcode: Int, currentController current: UIViewController, completion: (() -> ())? = nil) {
    let passcode = UIStoryboard(name: "User", bundle: nil).instantiateViewControllerWithIdentifier("passcode") as! PasscodeViewController
    passcode.view.frame = current.view.frame
    current.view.addSubview(passcode.view)

    //animate
    let offscreenOrigin = CGPointMake(0, current.view.frame.height * 1.2)
    passcode.view.frame.origin = offscreenOrigin
    
    UIView.animateWithDuration(0.7, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: nil, animations: {
        passcode.view.frame.origin = CGPointZero
    }, completion: nil)
    
    passcode.completion = { success in
        UIView.animateWithDuration(0.7, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: nil, animations: {
            passcode.view.frame.origin = offscreenOrigin
        }, completion: { _ in
            passcode.view.removeFromSuperview()
            if success {
                completion?()
            }
        })
    }
}




