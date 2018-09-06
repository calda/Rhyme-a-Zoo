//
//  ViewController.swift
//  Rhyme a Zoo
//
//  Created by Cal on 6/28/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import UIKit
import CoreLocation

let RZMainMenuTouchDownNotification = "com.hearatale.raz.main-menu-touch-down"

class MainViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var buttonsSuperview: UIView!
    var buttonFrames: [UIButton : CGRect] = [:]
    @IBOutlet var cards: [UIButton] = []
    @IBOutlet var topItems: [UIView] = []
    @IBOutlet var panGestureRecognizer: UIPanGestureRecognizer!
    @IBOutlet weak var userIcon: UIButton!
    @IBOutlet weak var userName: UIButton!
    
    @IBOutlet weak var zookeeperButton: UIButton!
    var currentZookeeper: String?
    
    override func viewWillAppear(_ animated: Bool) {
        if self.presentedViewController == nil {
            
            var delay = 0.0
            var animationViews = [UIView]()
            animationViews.append(contentsOf: cards as [UIView])
            animationViews.append(contentsOf: topItems)
            
            for view in animationViews {
                let origin = view.frame.origin
                let offset: CGFloat = (topItems as NSArray).contains(view) ? -100 : 500.0
                view.frame = view.frame.offsetBy(dx: 0, dy: offset)
                
                UIView.animate(withDuration: 0.7, delay: delay, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
                    view.frame.origin = origin
                }, completion: nil)
                
                delay += 0.03
            }
        }
        userIcon.setImage(RZCurrentUser.icon, for: .normal)
        decorateUserIcon(userIcon)
        userName.setTitle(RZCurrentUser.name, for: .normal)
        
        RZUserDatabase.refreshUser(RZCurrentUser)
        
        if currentZookeeper != RZQuizDatabase.getKeeperString() {
            createImageForZookeeper()
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //test the database because I'm dumb and deleted the Unit Tests
        /*         ALL OF THESE TESTS PASSED ON JUNE 30, 2015        */
        
        /*for i in 0 ..< RZQuizDatabase.count {
            let quiz = RZQuizDatabase.getQuiz(i)
            for question in quiz.questions {
                let options = question.shuffledOptions
                let words = options.map{ return $0.word }
                let success = contains(words, question.answer)
                if !success {
                    println("A question's options array does not contain the question's answer.")
                }
                
                for option in options {
                    let audioName = option.rawWord
                    //check audio exists
                    if UALengthOfFile(audioName, ofType: "mp3") <= 0.0 {
                        println("\(option.word) does not have an audio file")
                    }
                    
                    //check image exists
                    var image = UIImage(named: option.rawWord + ".jpg")
                    if image == nil {
                        image = UIImage(named: option.rawWord.lowercaseString + ".jpg")
                    }
                    if image == nil && !option.rawWord.hasPrefix("sound-") {
                        println("\(option.word) does notgoo have an image file")
                    }
                }
                
            }
        }

        for level in 1...RZQuizDatabase.levelCount {
            let quizes = RZQuizDatabase.quizesInLevel(level)
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.touchDownNotificationRecieved(_:)), name: NSNotification.Name(rawValue: RZMainMenuTouchDownNotification), object: nil)
        
        //replace icon image with aliased version
        let newSize = self.userIcon.frame.size
        let screenScale = UIScreen.main.scale
        let scaleSize = CGSize(width: newSize.width * screenScale, height: newSize.height * screenScale)
        
        RZAsyncQueue.async(execute: {
            if let original = RZCurrentUser.icon, original.size.width > scaleSize.width {
                UIGraphicsBeginImageContext(scaleSize)
                let context = UIGraphicsGetCurrentContext()
                context?.interpolationQuality = .high
                context?.setShouldAntialias(true)
                original.draw(in: CGRect(origin: .zero, size: scaleSize))
                let newImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                DispatchQueue.main.async(execute: {
                    self.userIcon.setImage(newImage, for: .normal)
                })
            }
        })
        
        //play welcome video if it hasn't been played
        delay(0.1) {
            if !RZQuizDatabase.hasWatchedWelcomeVideo() {
                playVideo(name: "welcome-video", currentController: self, completion: {
                    RZQuizDatabase.setHasWatchedWelcomeVideo(true)
                    RZUserDatabase.saveCurrentUserToLinkedClassroom()
                })
            }
        }
        
    }
    
    @objc func touchDownNotificationRecieved(_ notification: Notification) {
        if let touch = notification.object as? UITouch {
            processTouchAtLocation(touch.location(in: buttonsSuperview), state: .began)
        }
    }
    
    @IBAction func touchRecognized(_ sender: UIGestureRecognizer) {
        processTouchAtLocation(sender.location(in: buttonsSuperview), state: sender.state)
    }
    
    func processTouchAtLocation(_ touch: CGPoint, state: UIGestureRecognizer.State) {
        //figure out which button this touch is in
        for (button, frame) in buttonFrames {
            if frame.contains(touch) {
                UIView.animate(withDuration: 0.2, animations: {
                    button.transform = CGAffineTransform(scaleX: 1.07, y: 1.07)
                })
            } else {
                UIView.animate(withDuration: 0.2, animations: {
                    button.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                })
            }
        }
        
        //if the touch is lifted
        if state == .ended {
            
            for (button, frame) in buttonFrames {
                UIView.animate(withDuration: 0.2, animations: {
                    button.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                })
                
                if frame.contains(touch) {
                    let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: button.restorationIdentifier!)
                    if let controller = controller as? CatalogViewController {
                        controller.animatingFromHome = true
                    }
                    self.present(controller, animated: true, completion: nil)
                }
                
            }
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @IBAction func editUser(_ sender: UIButton) {
        let editUserController = UIStoryboard(name: "User", bundle: nil).instantiateViewController(withIdentifier: "newUser") as! NewUserViewController
        editUserController.openInEditModeForUser(RZCurrentUser)
        self.present(editUserController, animated: true, completion: nil)
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
            background.draw(at: CGPoint.zero)
            
            //draw zookeeper in center
            var origin = CGPoint(x: 159, y: 422)
            var size = CGSize(width: 720, height: 1250)
            
            if !iPad() {
                origin = CGPoint(x: origin.x / 2, y: origin.y / 2)
                size = CGSize(width: size.width / 2, height: size.height / 2)
            }
            
            zookeeper.draw(in: CGRect(origin: origin, size: size))
            
            foreground.draw(at: CGPoint.zero)
            
            let composite = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            self.zookeeperButton.setImage(composite, for: .normal)
            self.currentZookeeper = RZQuizDatabase.getKeeperString()
        }
    }
    
}

class TouchView: UIImageView {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        //gesture recognizers can't handle touch down on their own
        guard let touch = touches.first else { return }
        NotificationCenter.default.post(name: Notification.Name(rawValue: RZMainMenuTouchDownNotification), object: touch, userInfo: nil)
    }

}
