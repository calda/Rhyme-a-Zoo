//
//  QuizViewController.swift
//  Rhyme a Zoo
//
//  Created by Cal on 7/3/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import Foundation
import UIKit

class QuizViewController : UIViewController {
    
    @IBOutlet weak var blurredBackground: UIImageView!
    @IBOutlet weak var questionText: UILabel!
    @IBOutlet weak var questionNumberIcon: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet var optionIcons: [UIImageView]!
    @IBOutlet var optionLabels: [UILabel]!
    @IBOutlet var touchRecognizer: UITouchGestureRecognizer!
    
    @IBOutlet weak var questionContainer: UIView!
    @IBOutlet var optionContainers: [UIView]!
    var originalContainerFrames: [CGRect] = []
    
    var quiz: Quiz! = Quiz(1)
    var questionNumber: Int = -1
    var question: Question!
    var options: [Option]!
    var answerAttempts = 0
    var goldCoins = 0
    var silverCoins = 0
    
    @IBOutlet weak var quizOverView: UIView!
    @IBOutlet weak var quizOverViewTop: NSLayoutConstraint!
    @IBOutlet weak var coinsLabel: UILabel!
    @IBOutlet var coins: [UIImageView]!
    @IBOutlet weak var coinView: UIView!
    @IBOutlet var coinViewAspect: NSLayoutConstraint!
    @IBOutlet weak var coinViewWidth: NSLayoutConstraint!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    
    override func viewWillAppear(animated: Bool) {
        self.view.clipsToBounds = true
        //sort IB arrays
        let arrays: NSArray = [optionIcons, optionLabels, optionContainers, coins]
        optionIcons = (optionIcons as NSArray).sortedArrayUsingDescriptors([NSSortDescriptor(key: "tag", ascending: true)]) as! [UIImageView]
        optionLabels = (optionLabels as NSArray).sortedArrayUsingDescriptors([NSSortDescriptor(key: "tag", ascending: true)]) as! [UILabel]
        optionContainers = (optionContainers as NSArray).sortedArrayUsingDescriptors([NSSortDescriptor(key: "tag", ascending: true)]) as! [UIView]
        coins = (coins as NSArray).sortedArrayUsingDescriptors([NSSortDescriptor(key: "tag", ascending: true)]) as! [UIImageView]
        
        quizOverView.backgroundColor = UIColor.clearColor()
        quizOverViewTop.constant = UIScreen.mainScreen().bounds.height
        self.view.layoutIfNeeded()
        
        for icon in optionIcons {
            icon.layer.masksToBounds = true
            icon.clipsToBounds = true
            icon.layer.cornerRadius = icon.frame.height / 6.0
            icon.layer.borderColor = UIColor.whiteColor().CGColor
            icon.layer.borderWidth = 2.0
        }
        
        for container in optionContainers {
            originalContainerFrames.append(container.frame)
        }
        
        startQuiz(quiz)
    }
    
    func startQuiz(quiz: Quiz) {
        var animateTransition = (self.quiz != nil) //is not first quiz
        self.quiz = quiz
        let quizNumber = quiz.number.threeCharacterString()
        blurredBackground.image = UIImage(named: "illustration_\(quizNumber).jpg")
        
        if animateTransition {
            playTransitionForView(blurredBackground, duration: 1.0, transition: kCATransitionFade)
        }
        
        questionNumber = -1
        nextQuestion()
    }
    
    func nextQuestion() {
        questionNumber += 1
        answerAttempts = 0
        
        if questionNumber == 4 {
            endQuiz()
            return
        }
        
        question = quiz.questions[questionNumber]
        options = question.shuffledOptions
        
        //decorate screen
        questionText.text = question.text
        let numberImage = UIImage(named: "button-\(questionNumber + 1)")
        questionNumberIcon.setImage(numberImage, forState: .Normal)
        
        for i in 0 ... 3 {
            let option = options[i]
            let word = option.word
            optionLabels[i].text = word
            optionContainers[i].alpha = 1.0
            
            //find the image for the word
            var image = UIImage(named: word + ".jpg")
            if image == nil {
                image = UIImage(named: word.lowercaseString + ".jpg")
            }
            if image == nil {
                //no image to display, choose one of the 8 unknown images
                let random = arc4random_uniform(7) + 1
                let imageName = "unknown\(random).jpg"
                image = UIImage(named: imageName)
            }
            if let image = image {
                optionIcons[i].image = image
            }
        }
        
        //play audio
        let audioNumber = question.number.threeCharacterString()
        let audioName = "question_\(audioNumber)"
        let success = UAPlayer().play(audioName, ofType: "mp3", ifConcurrent: .Interrupt)
        
    }
    
    func endQuiz() {
        //disable the quiz
        touchRecognizer.enabled = false
        UIView.animateWithDuration(0.3) {
            self.questionText.alpha = 0.0
            self.questionContainer.alpha = 0.0
            self.questionNumberIcon.alpha = 0.0
        }
        
        if goldCoins == 4 { goldCoins = 5 }
        setCoinsInImageViews(coins, gold: goldCoins, silver: silverCoins, big: true)
        
        //build coins string
        var coinString = "You earned"
        var audioName = "quiz-over"
        if goldCoins == 1 { coinString += " 1 gold coin" }
        if goldCoins > 1 { coinString += " \(goldCoins) gold coins"}
        if silverCoins != 0 && goldCoins != 0 { coinString += " and"}
        if silverCoins == 1 { coinString += " 1 silver coin" }
        if silverCoins > 1 { coinString += " \(silverCoins) silver coins"}
        
        if silverCoins == 0 && goldCoins == 0 {
            coinString = "You didn't earn any coins."
            audioName = "quiz-over-bad"
        }
        
        let count = goldCoins + silverCoins
        //update constraints for coinView
        coinView.removeConstraint(coinViewAspect)
        let newAspect = NSLayoutConstraint(item: coinView, attribute: .Width, relatedBy: .Equal, toItem: coinView, attribute: .Height, multiplier: CGFloat(count), constant: 0.0)
        coinView.addConstraint(newAspect)
        coinViewAspect = newAspect
        
        coinViewWidth.constant = -coinView.frame.height * CGFloat(5 - count)
        self.view.layoutIfNeeded()
        
        //update buttons
        let quizIndex = RZQuizDatabase.getIndexForRhyme(quiz)
        previousButton.hidden = (quizIndex == 0)
        nextButton.hidden = (quizIndex == (RZQuizDatabase.count - 1))
        
        delay(1.0) {
            UAPlayer().play(audioName, ofType: "mp3", ifConcurrent: .Interrupt)
        }
        
        coinsLabel.text = coinString
        
        UIView.animateWithDuration(0.7, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: nil, animations: {
            self.quizOverViewTop.constant = 0.0
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    //MARK: - User Interaction
    var touchCurrentlyIn = -1
    
    @IBAction func touchDetected(sender: UITouchGestureRecognizer) {
        let touch = sender.locationInView(questionContainer)
        var touched: Int = -1
        
        for i in 0...3 {
            let frame = originalContainerFrames[i]
            if frame.contains(touch) && optionContainers[i].alpha == 1.0 {
                touched = i
                continue
            }
        }
        
        if sender.state == .Ended {
            touchCurrentlyIn = -1
            highlightOption(-1)
            if touched != -1 { checkAnswer(touched) }
        }
        else {
            highlightOption(touched)
            if touchCurrentlyIn != touched { //the touch just moved to a new option
                //play audio if the finger hasn't moved out of the option
                if touched != -1 {
                    delay(0.2) {
                        if self.touchCurrentlyIn == touched {
                            self.options[touched].playAudio()
                        }
                    }
                }
                touchCurrentlyIn = touched
            }
        }
        
    }
    
    func highlightOption(option: Int) {
        for container in optionContainers {
            if container.tag == option {
                UIView.animateWithDuration(0.3) {
                    container.transform = CGAffineTransformMakeScale(1.2, 1.2)
                }
            } else {
                UIView.animateWithDuration(0.3) {
                    container.transform = CGAffineTransformMakeScale(1.0, 1.0)
                }
            }
        }
    }
    
    func checkAnswer(guess: Int) {
        answerAttempts += 1
        let answer = question.answer
        let option = options[guess]
        
        if option.word == answer { //correct
            
            if answerAttempts == 1 {
                goldCoins++
            } else if answerAttempts == 2 {
                silverCoins++
            }
            
            UAPlayer().play("correct", ofType: "mp3", ifConcurrent: .Interrupt)
            //fade others
            for i in 0...3 {
                if i != guess {
                    UIView.animateWithDuration(0.2) {
                        self.optionContainers[i].alpha = 0.0
                    }
                }
            }
            
            //animate self to center
            let center = CGPointMake(self.questionContainer.frame.width / 2.0, self.questionContainer.frame.height / 2.0)
            UIView.animateWithDuration(0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: nil, animations: {
                self.optionContainers[guess].center = center
                }, completion: nil)
            
            UIView.animateWithDuration(0.7, delay: 0.0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0.0, options: nil, animations: {
                self.optionContainers[guess].transform = CGAffineTransformMakeScale(1.3, 1.3)
                }, completion: nil)
            
            delay(1.0) {
                if self.questionNumber != 3 {
                    self.optionContainers[guess].transform = CGAffineTransformMakeScale(1.0, 1.0)
                    self.optionContainers[guess].frame = self.originalContainerFrames[guess]
                }
                self.nextQuestion()
            }
            
        } else { //incorrect
            UAPlayer().play("incorrect", ofType: "mp3", ifConcurrent: .Interrupt)
            UIView.animateWithDuration(0.2) {
                self.optionContainers[guess].alpha = 0.0
            }
        }
    }
    
    @IBAction func returnToRhyme(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func playOffsetRhyme(sender: UIButton) {
        let offset = sender.tag
        let rhymeIndex = RZQuizDatabase.getIndexForRhyme(quiz)
        let newIndex = rhymeIndex + offset
        let rhyme = RZQuizDatabase.getRhyme(newIndex)
        
        if let rhymeController = self.presentingViewController as? RhymeViewController {
            rhymeController.decorate(rhyme)
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    
    
}

func setCoinsInImageViews(imageViews: [UIImageView], #gold: Int, #silver: Int, #big: Bool) {
    let goldImage = UIImage(named: big ? "coin-gold-big" : "coin-gold")
    let silverImage = UIImage(named: big ? "coin-silver-big" : "coin-gold")
    
    for i in 0 ..< gold {
        imageViews[i].alpha = 1.0
        imageViews[i].image = goldImage
    }
    for i in 0 ..< silver {
        imageViews[i].alpha = 1.0
        imageViews[i + gold].image = silverImage
    }
    for i in 0 ..< imageViews.count {
        if i >= gold + silver {
            imageViews[i].alpha = 0.0
            imageViews[i].image = goldImage
        }
    }
}















