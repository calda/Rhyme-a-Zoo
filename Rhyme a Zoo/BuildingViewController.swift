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
    
    //each point is a percentage of the total width/height of the background image
    let percentageFrames: [String: CGRect] = [
        "giraffe"     : CGRect(origin: CGPoint(x: 0.637, y: 0.0493), size: CGSize(width: 0.318, height: 0.921)),
        "hippo"       : CGRect(origin: CGPoint(x: 0.038, y: 0.011), size: CGSize(width: 0.378, height: 0.369)),
        "kangaroo"    : CGRect(origin: CGPoint(x: 0.115, y: 0.433), size: CGSize(width: 0.450, height: 0.550)),
        "panda"       : CGRect(origin: CGPoint(x: 0.431, y: 0.108), size: CGSize(width: 0.312, height: 0.447)),
        "ostrich"     : CGRect(origin: CGPoint(x: 0.396, y: 0.192), size: CGSize(width: 0.28, height: 0.596)),
        "owl"         : CGRect(origin: CGPoint(x: -0.035, y: 0.08), size: CGSize(width: 0.288, height: 0.504)),
        "parrot"      : CGRect(origin: CGPoint(x: 0.675, y: 0.085), size: CGSize(width: 0.422, height: 0.896)),
        "flamingo"    : CGRect(origin: CGPoint(x: 0.12, y: 0.377), size: CGSize(width: 0.265, height: 0.664)),
        "seal"        : CGRect(origin: CGPoint(x: 0.108, y: 0.397), size: CGSize(width: 0.52, height: 0.53)),
        "shark"       : CGRect(origin: CGPoint(x: 0.567, y: 0.325), size: CGSize(width: 0.381, height: 0.287)),
        "squid"       : CGRect(origin: CGPoint(x: 0.165, y: 0.02), size: CGSize(width: 0.302, height: 0.456)),
        "dolphin"     : CGRect(origin: CGPoint(x: 0.469, y: 0.087), size: CGSize(width: 0.451, height: 0.222)),
        "wolf"        : CGRect(origin: CGPoint(x: 0.628, y: 0.391), size: CGSize(width: 0.316, height: 0.556)),
        "lion"        : CGRect(origin: CGPoint(x: 0.009, y: 0.393), size: CGSize(width: 0.527, height: 0.588)),
        "tiger"       : CGRect(origin: CGPoint(x: 0.015, y: 0.023), size: CGSize(width: 0.3, height: 0.373)),
        "jaguar"      : CGRect(origin: CGPoint(x: 0.319, y: 0.003), size: CGSize(width: 0.419, height: 0.266)),
        "alligator"   : CGRect(origin: CGPoint(x: 0.055, y: 0.056), size: CGSize(width: 0.431, height: 0.479)),
        "iguana"      : CGRect(origin: CGPoint(x: 0.589, y: 0.444), size: CGSize(width: 0.373, height: 0.503)),
        "turtle"      : CGRect(origin: CGPoint(x: 0.556, y: 0.055), size: CGSize(width: 0.396, height: 0.317)),
        "rattlesnake" : CGRect(origin: CGPoint(x: 0.021, y: 0.619), size: CGSize(width: 0.388, height: 0.264)),
        "baboon"      : CGRect(origin: CGPoint(x: 0.101, y: 0.008), size: CGSize(width: 0.183, height: 0.399)),
        "monkey"      : CGRect(origin: CGPoint(x: 0.558, y: 0.467), size: CGSize(width: 0.315, height: 0.391)),
        "gorilla"     : CGRect(origin: CGPoint(x: 0.691, y: 0.009), size: CGSize(width: 0.279, height: 0.519)),
        "chimp"       : CGRect(origin: CGPoint(x: 0.236, y: 0.339), size: CGSize(width: 0.279, height: 0.633)),
        "pterodactyl" : CGRect(origin: CGPoint(x: 0.758, y: 0.129), size: CGSize(width: 0.29, height: 0.316)),
        "stegasaurus" : CGRect(origin: CGPoint(x: 0.281, y: 0.417), size: CGSize(width: 0.288, height: 0.25)),
        "trex"        : CGRect(origin: CGPoint(x: 0.527, y: 0.197), size: CGSize(width: 0.389, height: 0.791)),
        "triceratop"  : CGRect(origin: CGPoint(x: 0.021, y: 0.315), size: CGSize(width: 0.244, height: 0.36)),
        "mermaid"     : CGRect(origin: CGPoint(x: 0.616, y: 0.293), size: CGSize(width: 0.353, height: 0.784)),
        "centaur"     : CGRect(origin: CGPoint(x: 0.278, y: 0.173), size: CGSize(width: 0.302, height: 0.498))
    ]
    
    //each point is a percentage of the total width/height of the background image
    let coinCenters : [String: CGPoint] = [
        "giraffe"     : CGPoint(x: 0.761, y: 0.944),
        "hippo"       : CGPoint(x: 0.217, y: 0.355),
        "kangaroo"    : CGPoint(x: 0.369, y: 0.947),
        "panda"       : CGPoint(x: 0.588, y: 0.517),
        "ostrich"     : CGPoint(x: 0.532, y: 0.773),
        "owl"         : CGPoint(x: 0.106, y: 0.491),
        "parrot"      : CGPoint(x: 0.809, y: 0.477),
        "flamingo"    : CGPoint(x: 0.317, y: 0.723),
        "seal"        : CGPoint(x: 0.229, y: 0.888),
        "shark"       : CGPoint(x: 0.791, y: 0.507),
        "squid"       : CGPoint(x: 0.219, y: 0.219),
        "dolphin"     : CGPoint(x: 0.671, y: 0.235),
        "wolf"        : CGPoint(x: 0.793, y: 0.925),
        "lion"        : CGPoint(x: 0.235, y: 0.939),
        "tiger"       : CGPoint(x: 0.197, y: 0.325),
        "jaguar"      : CGPoint(x: 0.548, y: 0.187),
        "alligator"   : CGPoint(x: 0.416, y: 0.491),
        "iguana"      : CGPoint(x: 0.926, y: 0.709),
        "turtle"      : CGPoint(x: 0.677, y: 0.336),
        "rattlesnake" : CGPoint(x: 0.102, y: 0.757),
        "baboon"      : CGPoint(x: 0.169, y: 0.347),
        "monkey"      : CGPoint(x: 0.612, y: 0.723),
        "gorilla"     : CGPoint(x: 0.914, y: 0.475),
        "chimp"       : CGPoint(x: 0.251, y: 0.896),
        "pterodactyl" : CGPoint(x: 0.853, y: 0.387),
        "stegasaurus" : CGPoint(x: 0.47, y: 0.675),
        "trex"        : CGPoint(x: 0.663, y: 0.925),
        "triceratop"  : CGPoint(x: 0.163, y: 0.627),
        "mermaid"     : CGPoint(x: 0.735, y: 0.805),
        "centaur"     : CGPoint(x: 0.444, y: 0.643)
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
    
    func decorate(building: Int, displaySize: CGSize) {
        self.building = building
        self.displaySize = displaySize
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.view.isUserInteractionEnabled = false
        
        guard let building = building else {
            fatalError("Must configure `building` through the `decorate` method.")
        }
        
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
        sceneSize = CGSize(width: backgroundSize.width * ratio, height: backgroundSize.height * ratio)
        
        for animal in buildingAnimals[building - 1] {
            let frame = percentageFrames[animal]!
            let origin = CGPoint(x: frame.origin.x * sceneSize.width, y: frame.origin.y * sceneSize.height)
            let size = CGSize(width: frame.width * sceneSize.width, height: frame.height * sceneSize.height)
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
            button.setImage(image, for: UIControlState())
            button.isUserInteractionEnabled = false
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
            infoButton.isHidden = true
        } else {
            infoButton.isHidden = false
        }
        
        let dark = (building > RZQuizDatabase.currentZooLevel() ? "-dark" : "")
        buildingButton.setImage(UIImage(named: "button-\(building)\(dark)"), for: UIControlState())
        
        if mustBuy {
            backButton.isEnabled = false
            homeButton.isEnabled = false
        }
    }
    
    func addButtonForAnimal(_ animal: String, playerOwns owned: Bool) {
        let size = (owned ? (iPad() ? CGSize(width: 60, height: 60) : CGSize(width: 40, height: 40)) : (iPad() ? CGSize(width: 80, height: 80) : CGSize(width: 40, height: 40)))
        let percentCenter = coinCenters[animal]!
        let center = CGPoint(x: percentCenter.x * sceneSize.width, y: percentCenter.y * sceneSize.height)
        var frame = CGRect(x: center.x - size.width/2, y: center.y - size.height/2, width: size.width, height: size.height)
        //calculate the offset so that these buttons are in the main view instead
        let screenWidth = UIScreen.main.bounds.width
        let unusedWidth = screenWidth - sceneSize.width
        let offset = unusedWidth / 2
        frame = frame.offsetBy(dx: offset, dy: 0)
        
        let button = UIButton(frame: frame)
        button.imageView!.contentMode = UIViewContentMode.scaleAspectFit
        
        if !owned {
            let coinSize = iPad() ? "medium" : "small"
            let animalCost = RZQuizDatabase.currentZooLevel() == 8 ? 10 : 20
            let coinName = "coin-\(animalCost)-\(coinSize)"
            button.setImage(UIImage(named: coinName), for: UIControlState())
            button.addTarget(self, action: #selector(BuildingViewController.purchasePressed(_:)), for: .touchUpInside)
            
            if !RZQuizDatabase.canAffordAnimal() {
                button.alpha = 0.6
            }
            
            buyButtons.append(button)
            
        } else {
            button.setImage(UIImage(named: "button-play"), for: UIControlState())
            button.addTarget(self, action: #selector(BuildingViewController.playAnimalSound(_:)), for: .touchUpInside)
            
            //fade button if file doesn't exist
            if UALengthOfFile(animal, ofType: "m4a") <= 1.0 {
                button.alpha = 0.5
            }
        }
        
        mainButtons.append(button)
        button.restorationIdentifier = animal
        self.view.addSubview(button)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        delay(1.0) {
            self.view.isUserInteractionEnabled = true
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        RZUserDatabase.saveCurrentUserToLinkedClassroom()
    }
    
    //MARK: - User Interaction
    
    @IBAction func tapDetected(_ sender: UITapGestureRecognizer) {
        if self.zookeeperImage != nil {
            //is in zookeeper mode
            zookeeperGameTap(event: sender)
            return
        }
        
        if UAIsAudioPlaying() { return } //don't do visual effects if audio is already playing
        
        let touch = sender.location(in: backgroundImage)
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
            
            if frame.contains(touch) && !anyHit {
                anyHit = true
                
                if sender.state == .ended {
                    button.isHighlighted = false
                    //play an audio for that animal
                    let audio = animalAudioNumber[animal]!
                    let audioName = "\(animal)_\(audio)"
                    let success = UAPlayer().play(audioName, ofType: "mp3", ifConcurrent: .ignore)
                    
                    if success {
                        //increment audio numver
                        var nextAudio = audio + 1
                        if nextAudio == 4 {
                            nextAudio = 1
                        }
                        animalAudioNumber.updateValue(nextAudio, forKey: animal)
                    }
                }
                else if sender.state == .began || sender.state == .changed {
                    button.isHighlighted = true
                }
            }
            else {
                button.isHighlighted = false
            }
        }
    }
    
    @IBAction func infoPress(_ sender: AnyObject) {
        let audioName = "building\(building)"
        UAPlayer().play(audioName, ofType: ".mp3", ifConcurrent: .ignore)
    }
    
    @IBAction func homePressed(_ sender: AnyObject) {
        UAHaltPlayback()
        self.dismiss(animated: true, completion: nil)
    }
    
    func purchasePressed(_ sender: UIButton) {
        if !RZQuizDatabase.canAffordAnimal() {
            UAPlayer().play("moreMoney", ofType: ".mp3", ifConcurrent: .ignore)
            return
        }
        if let animal = sender.restorationIdentifier {
            RZQuizDatabase.purchaseAnimal(animal)
            let didAdvanceLevel = RZQuizDatabase.advanceCurrentLevelIfComplete(buildingAnimals[building - 1])
            backButton.isEnabled = true
            homeButton.isEnabled = true
            self.mustBuy = false
            
            //color in animal and play sound
            UAPlayer().play("correct", ofType: ".mp3", ifConcurrent: .interrupt)
            let animalButton = animalButtons[animal]!
            let colored = UIImage(named: "\(animal)#color")
            animalButton.setImage(colored, for: UIControlState())
            
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
            if let index = mainButtons.index(of: sender) {
                mainButtons.remove(at: index)
            }
            
            //play animal's sound
            let duration = UALengthOfFile(animal, ofType: "m4a")
            delay(0.5) {
                UAPlayer().play(animal, ofType: "m4a", ifConcurrent: .interrupt)
            }
            
            if didAdvanceLevel {
                delay(max(duration + 0.5, 1.0)) {
                    let newLevel = RZQuizDatabase.currentZooLevel()
                    if (2...8).contains(newLevel) {
                        playVideo(name: "zoo-level-\(newLevel)", currentController: self, completion: {
                            self.backButton.isEnabled = true
                            if self.building != 8 {
                                let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "building") as! BuildingViewController
                                controller.decorate(building: self.building + 1, displaySize: self.view.frame.size)
                                self.present(controller, animated: true, completion: nil)
                            }
                        })
                    }
                }
            }
        }
    }
    
    func playAnimalSound(_ sender: UIButton) {
        if let animal = sender.restorationIdentifier {
            if !UAIsAudioPlaying() {
                UAPlayer().play(animal, ofType: "m4a", ifConcurrent: .interrupt)
            }
        }
    }
    
    @IBAction func zookeeperPressed(_ sender: UIButton) {
        toggleZookeeper()
    }
    
    @IBAction func panDetected(_ sender: UIPanGestureRecognizer) {
        zookeeperGamePan(event: sender)
    }
    
    @IBAction func pinchDetected(_ sender: UIPinchGestureRecognizer) {
        zookeeperGamePinch(event: sender)
    }
    
}
