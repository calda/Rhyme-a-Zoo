//
//  ZooViewController.swift
//  Rhyme a Zoo
//
//  Created by Cal on 6/29/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import Foundation
import UIKit
import UIKit.UIGestureRecognizerSubclass

func RZUserOwnsAnimalKey(animal: String) -> String {
    return "userOwnsAnimal:\(animal)"
}

class BuildingViewController : UIViewController {
    
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var blurredBackground: UIImageView!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var buildingButton: UIButton!
    
    let percentageFrames = [ //each point is a percentage of the total width/height of the background image
        "giraffe" : CGRect(origin: CGPointMake(0.637, 0.0493), size: CGSizeMake(0.318, 0.921)),
        "hippo" : CGRect(origin: CGPointMake(0.038, 0.011), size: CGSizeMake(0.378, 0.369)),
        "kangaroo" : CGRect(origin: CGPointMake(0.115, 0.433), size: CGSizeMake(0.450, 0.550)),
        "panda" : CGRect(origin: CGPointMake(0.431, 0.108), size: CGSizeMake(0.312, 0.447)),
        "ostrich" : CGRect(origin: CGPointMake(0.396, 0.192), size: CGSizeMake(0.28, 0.596)),
        "owl" : CGRect(origin: CGPointMake(-0.035, 0.08), size: CGSizeMake(0.288, 0.504)),
        "parrot" : CGRect(origin: CGPointMake(0.675, 0.085), size: CGSizeMake(0.422, 0.896)),
        "flamingo" : CGRect(origin: CGPointMake(0.12, 0.377), size: CGSizeMake(0.265, 0.664)),
        "seal" : CGRect(origin: CGPointMake(0.108, 0.397), size: CGSizeMake(0.52, 0.53)),
        "shark" : CGRect(origin: CGPointMake(0.567, 0.325), size: CGSizeMake(0.381, 0.287)),
        "squid" : CGRect(origin: CGPointMake(0.165, 0.02), size: CGSizeMake(0.302, 0.456)),
        "dolphin" : CGRect(origin: CGPointMake(0.469, 0.087), size: CGSizeMake(0.451, 0.222)),
        "wolf" : CGRect(origin: CGPointMake(0.628, 0.391), size: CGSizeMake(0.316, 0.556)),
        "lion" : CGRect(origin: CGPointMake(0.009, 0.393), size: CGSizeMake(0.527, 0.588)),
        "tiger" : CGRect(origin: CGPointMake(0.015, 0.023), size: CGSizeMake(0.3, 0.373)),
        "jaguar" : CGRect(origin: CGPointMake(0.319, 0.003), size: CGSizeMake(0.419, 0.266)),
        "alligator" : CGRect(origin: CGPointMake(0.055, 0.056), size: CGSizeMake(0.431, 0.479)),
        "iguana" : CGRect(origin: CGPointMake(0.589, 0.444), size: CGSizeMake(0.373, 0.503)),
        "turtle" : CGRect(origin: CGPointMake(0.556, 0.055), size: CGSizeMake(0.396, 0.317)),
        "rattlesnake" : CGRect(origin: CGPointMake(0.021, 0.619), size: CGSizeMake(0.388, 0.264)),
        "baboon" : CGRect(origin: CGPointMake(0.101, 0.008), size: CGSizeMake(0.183, 0.399)),
        "monkey" : CGRect(origin: CGPointMake(0.558, 0.467), size: CGSizeMake(0.315, 0.391)),
        "gorilla" : CGRect(origin: CGPointMake(0.691, 0.009), size: CGSizeMake(0.279, 0.519)),
        "chimp" : CGRect(origin: CGPointMake(0.236, 0.339), size: CGSizeMake(0.279, 0.633)),
        "pterodactyl" : CGRect(origin: CGPointMake(0.758, 0.129), size: CGSizeMake(0.29, 0.316)),
        "stegasaurus" : CGRect(origin: CGPointMake(0.281, 0.417), size: CGSizeMake(0.288, 0.25)),
        "trex" : CGRect(origin: CGPointMake(0.527, 0.197), size: CGSizeMake(0.389, 0.791)),
        "triceratop" : CGRect(origin: CGPointMake(0.021, 0.315), size: CGSizeMake(0.244, 0.36)),
        "mermaid" : CGRect(origin: CGPointMake(0.616, 0.293), size: CGSizeMake(0.353, 0.784)),
        "centaur" : CGRect(origin: CGPointMake(0.278, 0.173), size: CGSizeMake(0.302, 0.498))
    ]
    
    let buildingAnimals = [
        ["hippo", "kangaroo", "panda", "giraffe"],
        ["ostrich", "owl", "parrot", "flamingo"],
        ["shark", "squid", "dolphin", "seal"],
        ["wolf", "lion", "tiger", "jaguar"],
        ["alligator", "iguana", "turtle", "rattlesnake"],
        ["baboon", "chimp", "gorilla", "monkey"],
        ["pterodactyl", "stegasaurus", "triceratop", "trex"],
        ["mermaid", "centaur"]
    ]
    
    var buttons: [String : UIButton] = [:]
    var animalAudioNumber: [String : Int] = [:]
    var building: Int!
    var displaySize: CGSize!
    
    func decorate(#building: Int, displaySize: CGSize) {
        self.building = building
        self.displaySize = displaySize
    }
    
    override func viewWillAppear(animated: Bool) {
        //update background
        let image = UIImage(named:"building\(building).jpg")
        backgroundImage.image = image
        blurredBackground.image = image
        
        //generate frames for animal buttons
        buttons = [:]
        animalAudioNumber = [:]
        let displayHeight = displaySize.height
        let currentHeight = self.backgroundImage.frame.height
        let ratio = displayHeight / currentHeight
        let backgroundSize = self.backgroundImage.frame
        let sceneSize = CGSizeMake(backgroundSize.width * ratio, backgroundSize.height * ratio)
        
        for animal in buildingAnimals[building - 1] {
            let frame = percentageFrames[animal]!
            let origin = CGPointMake(frame.origin.x * sceneSize.width, frame.origin.y * sceneSize.height)
            let size = CGSizeMake(frame.width * sceneSize.width, frame.height * sceneSize.height)
            let buttonFrame = CGRect(origin: origin, size: size)
            
            //add button to view
            let dataKey = RZUserOwnsAnimalKey(animal)
            let userOwnsAnimal = data.boolForKey(dataKey)
            
            let image: UIImage?
            if userOwnsAnimal {
                image = UIImage(named: "\(animal)#color")
            }
            else {
                image = UIImage(named: animal)
            }
            
            let button = UIButton(frame: buttonFrame)
            button.setImage(image, forState: UIControlState.Normal)
            button.userInteractionEnabled = false
            backgroundImage.addSubview(button)
            
            buttons.updateValue(button, forKey: animal)
            
            //start on random audio
            let random = Int(arc4random_uniform(2) + 1)
            animalAudioNumber.updateValue(random, forKey: animal)
        }
        
        backgroundImage.layer.masksToBounds = true
        backgroundImage.clipsToBounds = true
        
        //hide info button if there is no relevant audio
        if building > 6 {
            infoButton.hidden = true
        } else {
            infoButton.hidden = false
        }
        
        buildingButton.setImage(UIImage(named: "button-\(building)"), forState: .Normal)
    }
    
    @IBAction func tapDetected(sender: UITapGestureRecognizer) {
        if UAIsAudioPlaying() { return } //don't do visual effects if audio is already playing
        
        let touch = sender.locationInView(backgroundImage)
        var anyHit = false //only allow the top hitbox if two overlap
        
        for animal in buildingAnimals[building - 1] {
            let button = buttons[animal]!
            let frame = button.frame
            
            if CGRectContainsPoint(frame, touch) && !anyHit {
                anyHit = true
                
                if sender.state == .Ended {
                    button.highlighted = false
                    //play an audio for that animal
                    let audio = animalAudioNumber[animal]!
                    let audioName = "\(animal)_\(audio)"
                    let success = UAPlayer().play(audioName, ofType: "mp3", ifConcurrent: .Ignore)
                    
                    if success {
                        //increment audio numver
                        var nextAudio = audio + 1
                        if nextAudio == 4 {
                            nextAudio = 1
                        }
                        animalAudioNumber.updateValue(nextAudio, forKey: animal)
                    }
                }
                else if sender.state == .Began || sender.state == .Changed {
                    button.highlighted = true
                }
            }
            else {
                button.highlighted = false
            }
        }
    }
    
    @IBAction func infoPress(sender: AnyObject) {
        let audioName = "building\(building)"
        UAPlayer().play(audioName, ofType: ".mp3", ifConcurrent: .Ignore)
    }
    
    @IBAction func homePressed(sender: AnyObject) {
        UAHaltPlayback()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}

class UITouchGestureRecognizer : UIGestureRecognizer {
    
    override func touchesBegan(touches: Set<NSObject>!, withEvent event: UIEvent!) {
        super.touchesBegan(touches, withEvent: event)
        self.state = .Began
    }
    
    override func touchesMoved(touches: Set<NSObject>!, withEvent event: UIEvent!) {
        super.touchesMoved(touches, withEvent: event)
        self.state = .Began
    }
    
    override func touchesEnded(touches: Set<NSObject>!, withEvent event: UIEvent!) {
        super.touchesEnded(touches, withEvent: event)
        self.state = .Ended
    }
    
}