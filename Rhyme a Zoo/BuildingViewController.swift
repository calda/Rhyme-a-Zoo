//
//  ZooViewController.swift
//  Rhyme a Zoo
//
//  Created by Cal on 6/29/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import Foundation
import UIKit

class BuildingViewController : ZookeeperGameController {
    
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var blurredBackground: UIImageView!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var buildingButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var homeButton: HomeButton!
    
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
    
    let coinCenters = [ //each point is a percentage of the total width/height of the background image
        "giraffe" : CGPointMake(0.761, 0.944),
        "hippo" : CGPointMake(0.217, 0.355),
        "kangaroo" : CGPointMake(0.369, 0.947),
        "panda" : CGPointMake(0.588, 0.517),
        "ostrich" : CGPointMake(0.532, 0.773),
        "owl" : CGPointMake(0.106, 0.491),
        "parrot" : CGPointMake(0.809, 0.477),
        "flamingo" : CGPointMake(0.317, 0.723),
        "seal" : CGPointMake(0.229, 0.888),
        "shark" : CGPointMake(0.791, 0.507),
        "squid" : CGPointMake(0.219, 0.219),
        "dolphin" : CGPointMake(0.671, 0.235),
        "wolf" : CGPointMake(0.793, 0.925),
        "lion" : CGPointMake(0.235, 0.939),
        "tiger" : CGPointMake(0.197, 0.325),
        "jaguar" : CGPointMake(0.548, 0.187),
        "alligator" : CGPointMake(0.416, 0.491),
        "iguana" : CGPointMake(0.926, 0.709),
        "turtle" : CGPointMake(0.677, 0.336),
        "rattlesnake" : CGPointMake(0.102, 0.757),
        "baboon" : CGPointMake(0.169, 0.347),
        "monkey" : CGPointMake(0.612, 0.723),
        "gorilla" : CGPointMake(0.914, 0.475),
        "chimp" : CGPointMake(0.251, 0.896),
        "pterodactyl" : CGPointMake(0.853, 0.387),
        "stegasaurus" : CGPointMake(0.47, 0.675),
        "trex" : CGPointMake(0.663, 0.925),
        "triceratop" : CGPointMake(0.163, 0.627),
        "mermaid" : CGPointMake(0.735, 0.805),
        "centaur" : CGPointMake(0.444, 0.643)
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
    
    var animalButtons: [String : UIButton] = [:]
    var animalAudioNumber: [String : Int] = [:]
    var buyButtons: [UIButton] = []
    var building: Int!
    var mustBuy: Bool = false
    var displaySize: CGSize!
    var sceneSize: CGSize!
    
    //MARK: - Decorating the view with animals and buttons
    
    func decorate(#building: Int, displaySize: CGSize) {
        self.building = building
        self.displaySize = displaySize
    }
    
    override func viewWillAppear(animated: Bool) {
        self.view.userInteractionEnabled = false
        
        //update background
        let image = UIImage(named:"building\(building).jpg")
        backgroundImage.image = image
        blurredBackground.image = image
        
        //generate frames for animal buttons
        animalButtons = [:]
        animalAudioNumber = [:]
        let displayHeight = displaySize.height
        let currentHeight = self.backgroundImage.frame.height
        let ratio = displayHeight / currentHeight
        let backgroundSize = self.backgroundImage.frame
        sceneSize = CGSizeMake(backgroundSize.width * ratio, backgroundSize.height * ratio)
        
        for animal in buildingAnimals[building - 1] {
            let frame = percentageFrames[animal]!
            let origin = CGPointMake(frame.origin.x * sceneSize.width, frame.origin.y * sceneSize.height)
            let size = CGSizeMake(frame.width * sceneSize.width, frame.height * sceneSize.height)
            let buttonFrame = CGRect(origin: origin, size: size)
            
            //add button to view
            let playerOwnsAnimal = RZQuizDatabase.playerOwnsAnimal(animal)
            
            let image: UIImage?
            if playerOwnsAnimal {
                image = UIImage(named: "\(animal)#color")
            }
            else {
                image = UIImage(named: animal)
            }
            
            let button = UIButton(frame: buttonFrame)
            button.setImage(image, forState: UIControlState.Normal)
            button.userInteractionEnabled = false
            backgroundImage.addSubview(button)
            animalButtons.updateValue(button, forKey: animal)
            
            //start on random audio
            let random = Int(arc4random_uniform(2) + 1)
            animalAudioNumber.updateValue(random, forKey: animal)
            
            //add buy button if this is current level
            let currentLevel = RZQuizDatabase.currentZooLevel()
            if currentLevel == building || RZQuizDatabase.playerOwnsAnimal(animal) {
                addButtonForAnimal(animal, playerOwns: RZQuizDatabase.playerOwnsAnimal(animal))
            }
        }
        
        backgroundImage.layer.masksToBounds = true
        backgroundImage.clipsToBounds = true
        
        //hide info button if there is no relevant audio
        if building > 6 {
            infoButton.hidden = true
        } else {
            infoButton.hidden = false
        }
        
        let dark = (building > RZQuizDatabase.currentZooLevel() ? "-dark" : "")
        buildingButton.setImage(UIImage(named: "button-\(building)\(dark)"), forState: .Normal)
        
        if mustBuy {
            backButton.enabled = false
            homeButton.enabled = false
        }
    }
    
    func addButtonForAnimal(animal: String, playerOwns owned: Bool) {
        let size = (owned ? (iPad() ? CGSizeMake(60, 60) : CGSizeMake(40, 40)) : (iPad() ? CGSizeMake(80, 80) : CGSizeMake(40, 40)))
        let percentCenter = coinCenters[animal]!
        let center = CGPointMake(percentCenter.x * sceneSize.width, percentCenter.y * sceneSize.height)
        var frame = CGRectMake(center.x - size.width/2, center.y - size.height/2, size.width, size.height)
        //calculate the offset so that these buttons are in the main view instead
        let screenWidth = UIScreen.mainScreen().bounds.width
        let unusedWidth = screenWidth - sceneSize.width
        let offset = unusedWidth / 2
        frame.offset(dx: offset, dy: 0)
        
        let button = UIButton(frame: frame)
        button.imageView!.contentMode = UIViewContentMode.ScaleAspectFit
        
        if !owned {
            let coinSize = iPad() ? "medium" : "small"
            let animalCost = RZQuizDatabase.currentZooLevel() == 8 ? 10 : 20
            let coinName = "coin-\(animalCost)-\(coinSize)"
            button.setImage(UIImage(named: coinName), forState: .Normal)
            button.addTarget(self, action: "purchasePressed:", forControlEvents: .TouchUpInside)
            
            if !RZQuizDatabase.canAffordAnimal() {
                button.alpha = 0.6
            }
            
            buyButtons.append(button)
            
        } else {
            button.setImage(UIImage(named: "button-play"), forState: .Normal)
            button.addTarget(self, action: "playAnimalSound:", forControlEvents: .TouchUpInside)
            
            //fade button if file doesn't exist
            if UALengthOfFile(animal, ofType: "m4a") <= 1.0 {
                button.alpha = 0.5
            }
        }
        
        mainButtons.append(button)
        button.restorationIdentifier = animal
        self.view.addSubview(button)
    }
    
    override func viewDidAppear(animated: Bool) {
        delay(1.0) {
            self.view.userInteractionEnabled = true
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        RZUserDatabase.saveCurrentUserToLinkedClassroom()
    }
    
    //MARK: - User Interaction
    
    @IBAction func tapDetected(sender: UITapGestureRecognizer) {
        if let zookeeperImage = self.zookeeperImage {
            //is in zookeeper mode
            zookeeperGameTap(event: sender)
            return
        }
        
        if UAIsAudioPlaying() { return } //don't do visual effects if audio is already playing
        
        let touch = sender.locationInView(backgroundImage)
        var anyHit = false //only allow the top hitbox if two overlap
        
        //activate this code to get percentage points for touches
        /*if sender.state != .Began { return }
        let xun = touch.x / backgroundImage.frame.width
        let yun = touch.y / backgroundImage.frame.height
        let x = Double(round(1000*xun)/1000)
        let y = Double(round(1000*yun)/1000)
        println("CGPointMake(\(x), \(y))")
        return*/
        
        for animal in buildingAnimals[building - 1] {
            let button = animalButtons[animal]!
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
    
    func purchasePressed(sender: UIButton) {
        if !RZQuizDatabase.canAffordAnimal() {
            UAPlayer().play("moreMoney", ofType: ".mp3", ifConcurrent: .Ignore)
            return
        }
        if let animal = sender.restorationIdentifier {
            RZQuizDatabase.purchaseAnimal(animal)
            let didAdvanceLevel = RZQuizDatabase.advanceCurrentLevelIfComplete(buildingAnimals[building - 1])
            backButton.enabled = true
            homeButton.enabled = true
            self.mustBuy = false
            
            //color in animal and play sound
            UAPlayer().play("correct", ofType: ".mp3", ifConcurrent: .Interrupt)
            let animalButton = animalButtons[animal]!
            let colored = UIImage(named: "\(animal)#color")
            animalButton.setImage(colored, forState: .Normal)
            
            //disable buy buttons if the user can't afford another animal
            if !RZQuizDatabase.canAffordAnimal() {
                for button in buyButtons {
                    button.alpha = 0.6
                }
            }
            
            //add Play Sound button
            addButtonForAnimal(animal, playerOwns: true)
            //remove current button from superview
            sender.removeFromSuperview()
            if let index = find(mainButtons, sender) {
                mainButtons.removeAtIndex(index)
            }
            
            //play animal's sound
            let duration = UALengthOfFile(animal, ofType: "m4a")
            delay(0.5) {
                UAPlayer().play(animal, ofType: "m4a", ifConcurrent: .Interrupt)
            }
            
            if didAdvanceLevel {
                delay(max(duration + 0.5, 1.0)) {
                    let newLevel = RZQuizDatabase.currentZooLevel()
                    if contains(2...8, newLevel) {
                        playVideo(name: "zoo-level-\(newLevel)", currentController: self, completion: {
                            self.backButton.enabled = true
                            if self.building != 8 {
                                let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("building") as! BuildingViewController
                                controller.decorate(building: self.building + 1, displaySize: self.view.frame.size)
                                self.presentViewController(controller, animated: true, completion: nil)
                            }
                        })
                    }
                }
            }
        }
    }
    
    func playAnimalSound(sender: UIButton) {
        if let animal = sender.restorationIdentifier {
            if !UAIsAudioPlaying() {
                UAPlayer().play(animal, ofType: "m4a", ifConcurrent: .Interrupt)
            }
        }
    }
    
    @IBAction func zookeeperPressed(sender: UIButton) {
        toggleZookeeper()
    }
    
    @IBAction func panDetected(sender: UIPanGestureRecognizer) {
        zookeeperGamePan(event: sender)
    }
    
    @IBAction func pinchDetected(sender: UIPinchGestureRecognizer) {
        zookeeperGamePinch(event: sender)
    }
    
}