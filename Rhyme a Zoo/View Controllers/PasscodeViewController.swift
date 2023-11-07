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
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var input: NSString = ""
    var correctPasscode: String = "1234"
    var descriptionString: String = ""
    var completion: (Bool) -> () = { _ in }
    var playAudioPrompts = false
    var mistakeCount = 0
    
    //passcode creation
    var creationMode = false
    var entryOne: String?
    var creationComplation: (String?) -> () = { _ in }
    
    override func viewWillAppear(_ animated: Bool) {
        self.displayView.alpha = 0.0
        descriptionLabel.text = descriptionString
        sortOutletCollectionByTag(&inputButtons)
        sortOutletCollectionByTag(&outputButtons)
        
        for button in outputButtons {
            button.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if playAudioPrompts {
            UAPlayer().play("passcode", ofType: "mp3", ifConcurrent: .interrupt)
        }
    }
    
    func showDescription() {
        delay(0.7) {
            if self.input == "" {
                self.showDescriptionNow()
            }
        }
    }
    
    func showDescriptionNow() {
        UIView.animate(withDuration: 0.5, delay: 0.0, options: [], animations: {
            self.descriptionLabel.alpha = 1.0
            self.displayView.alpha = 0.0
        }, completion: nil)
    }
    
    func hideDescription() {
        UIView.animate(withDuration: 0.2, delay: 0.0, options: [], animations: {
            self.descriptionLabel.alpha = 0.0
            self.displayView.alpha = 1.0
        }, completion: nil)
    }
    
    @IBAction func touchDetected(_ sender: UITouchGestureRecognizer) {
        
        let touch = sender.location(in: buttonView)
        if sender.state == .ended {
            animateButtons(selected: nil)
        }
        
        for button in inputButtons {
            if button.frame.contains(touch) {
                
                if sender.state == .ended {
                    userTappedButton(button.tag)
                }
                else {
                    animateButtons(selected: button.tag)
                }
            }
        }
        
    }
    
    func animateButtons(selected: Int?) {
        for button in inputButtons {
            let scale: CGFloat = (selected != nil && selected! == button.tag ? 1.2 : 1.0)
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: [], animations: {
                button.transform = CGAffineTransform(scaleX: scale, y: scale)
            }, completion: nil)
        }
    }
    
    func userTappedButton(_ tag: Int) {
        //change the input variable
        if tag == 11 {
            //backspace
            if input.length != 0 {
                input = input.substring(to: input.length - 1) as NSString
            }
            if input.length == 0 {
                showDescription()
            }
        } else {
            input = "\(input)\(tag)" as NSString
            hideDescription()
        }
        
        //display the new input in the screen
        for button in outputButtons {
            button.alpha = (button.tag <= input.length ? 1.0 : 0.5)
            let scale = button.alpha
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: [], animations: {
                button.transform = CGAffineTransform(scaleX: scale, y: scale)
            }, completion: nil)
        }
        
        if input.length == 4 {
            
            //creation of a new passcode
            if creationMode {
                //confirmed passcode
                if let entryOne = entryOne {
                    if input as String == entryOne {
                        delay(0.3) {
                            self.creationComplation(self.input as String)
                        }
                        return
                    } else {
                        descriptionLabel.text = "Passcodes did not match. Try again."
                        self.entryOne = nil
                        clearInput(shake: true, waitForDescription: false)
                        return
                    }
                }
                //first entry
                entryOne = input as String
                descriptionLabel.text = "Verify (repeat) your passcode."
                clearInput(shake: false, waitForDescription: false)
                return
            }
            
            if input as String == correctPasscode {
                self.view.isUserInteractionEnabled = false
                delay(0.3) {
                    self.completion(true)
                }
            } else {
                clearInput(shake: true, waitForDescription: true)
                mistakeCount += 1
                if playAudioPrompts && mistakeCount % 2 == 0 {
                    UAPlayer().play("passcode-forgot", ofType: "mp3", ifConcurrent: .interrupt)
                }
            }
        }
    }
    
    func clearInput(shake: Bool, waitForDescription: Bool) {
        if shake { shakeView(displayView) }
        UIView.animate(withDuration: 0.3, animations: {
            for button in self.outputButtons {
                button.alpha = 0.5
                button.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            }
        })
        input = ""
        
        if shake {
            delay(waitForDescription ? 1.0 : 0.0) {
                if waitForDescription {
                    self.showDescription()
                } else {
                    self.showDescriptionNow()
                }
            }
        } else {
            showDescriptionNow()
        }
    }

    @IBAction func cancelPasscode(_ sender: AnyObject) {
        
        if playAudioPrompts {
            UAHaltPlayback()
        }
        
        if creationMode {
            creationComplation(nil)
            return
        }
        
        completion(false)
    }
    
}

func requestPasscode(_ correctPasscode: String, description: String, currentController current: UIViewController, forKids: Bool = false, completion: ((Bool) -> ())? = nil) {
    let passcode = UIStoryboard(name: "User", bundle: nil).instantiateViewController(withIdentifier: "passcode") as! PasscodeViewController
    passcode.correctPasscode = correctPasscode
    passcode.descriptionString = description
    
    passcode.playAudioPrompts = forKids
    passcode.modalPresentationStyle = .overCurrentContext
    current.presentFullScreen(passcode, animated: true, completion: nil)
    
    passcode.completion = { success in
        passcode.dismiss(animated: true, completion: {
            completion?(success)
        })
        
    }
}

func createPasscode(_ description: String, currentController current: UIViewController, completion: @escaping (String?) -> ()) {
    let passcode = UIStoryboard(name: "User", bundle: nil).instantiateViewController(withIdentifier: "passcode") as! PasscodeViewController
    passcode.creationMode = true
    passcode.descriptionString = description
    
    passcode.modalPresentationStyle = .overCurrentContext
    current.presentFullScreen(passcode, animated: true, completion: nil)
    
    passcode.creationComplation = { newPasscode in
        passcode.dismiss(animated: true, completion: {
            completion(newPasscode)
        })
        
    }
}
