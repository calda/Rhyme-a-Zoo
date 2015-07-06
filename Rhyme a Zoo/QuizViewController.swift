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
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet var optionIcons: [UIImageView]!
    @IBOutlet var optionLabels: [UILabel]!
    @IBOutlet var touchRecognizer: UITouchGestureRecognizer!
    
    @IBOutlet weak var questionContainer: UIView!
    @IBOutlet var optionContainers: [UIView]!
    var originalContainerFrames: [CGRect] = []
    
    var quiz: Quiz! = Quiz(115)
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
    @IBOutlet weak var repeatButton: UIButton!
    
    
    var timers: [NSTimer] = []
    
    //MARK: - Managing the view controller
    
    override func viewWillAppear(animated: Bool) {
        self.view.clipsToBounds = true
        //sort IB arrays
        let arrays: NSArray = [optionIcons, optionLabels, optionContainers, coins]
        optionIcons = (optionIcons as NSArray).sortedArrayUsingDescriptors([NSSortDescriptor(key: "tag", ascending: true)]) as! [UIImageView]
        optionLabels = (optionLabels as NSArray).sortedArrayUsingDescriptors([NSSortDescriptor(key: "tag", ascending: true)]) as! [UILabel]
        optionContainers = (optionContainers as NSArray).sortedArrayUsingDescriptors([NSSortDescriptor(key: "tag", ascending: true)]) as! [UIView]
        coins = (coins as NSArray).sortedArrayUsingDescriptors([NSSortDescriptor(key: "tag", ascending: true)]) as! [UIImageView]
        
        quizOverView.backgroundColor = UIColor.clearColor()
        quizOverViewTop.constant = -UIScreen.mainScreen().bounds.height
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
        
        startQuiz(quiz, playAudio: false)
    }
    
    override func viewDidAppear(animated: Bool) {
        playQuizAudio()
    }
    
    func startQuiz(quiz: Quiz, playAudio: Bool = true) {
        var animateTransition = (self.quiz != nil) //is not first quiz
        self.quiz = quiz
        let quizNumber = quiz.number.threeCharacterString()
        blurredBackground.image = UIImage(named: "illustration_\(quizNumber).jpg")
        
        if animateTransition {
            playTransitionForView(blurredBackground, duration: 1.0, transition: kCATransitionFade)
        }
        
        questionNumber = -1
        nextQuestion(playAudio: playAudio)
    }
    
    func nextQuestion(playAudio: Bool = true) {
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
        
        if playAudio { playQuizAudio() }
    }
    
    func playQuizAudio() {
        
        UIView.animateWithDuration(0.6, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.AllowUserInteraction, animations: {
            self.repeatButton.transform = CGAffineTransformMakeScale(0.75,0.75)
        }, completion: nil)
        self.repeatButton.enabled = false
        
        //play audio
        let audioNumber = question.number.threeCharacterString()
        let audioName = "question_\(audioNumber)"
        let success = UAPlayer().play(audioName, ofType: "mp3", ifConcurrent: .Interrupt)
        
        let questionLength = UALengthOfFile(audioName, ofType: "mp3")
        var currentDelay = questionLength
        
        for i in 0...4 {
            //don't play audio if the item isn't visible
            if i != 4 && optionContainers[i].alpha == 0 { continue }
            
            let timer = NSTimer.scheduledTimerWithTimeInterval(currentDelay, target: self, selector: "playAudioForOption:", userInfo: i, repeats: false)
            timers.append(timer)
            
            if i == 4 { continue }
            //calculate next delay
            let audioName = options[i].word
            var duration = UALengthOfFile(audioName, ofType: "mp3")
            if duration == 0.0 { duration = 1.0 }
            
            currentDelay += duration
        }
    }
    
    func playAudioForOption(timer: NSTimer) {
        if let option = timer.userInfo as? Int{
            self.highlightOption(option)
            if option == 4 {
                
                //animate in repeat button
                UIView.animateWithDuration(0.6, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.AllowUserInteraction, animations: {
                    self.repeatButton.transform = CGAffineTransformMakeScale(1.0, 1.0)
                    }, completion: nil)
                self.repeatButton.enabled = true
                
                stopAllTimers()
                return
            }
            
            let audioName = options[option].word
            UAPlayer().play(audioName, ofType: "mp3", ifConcurrent: .Interrupt)
        }
    }
    
    func stopAllTimers() {
        for timer in timers {
            timer.invalidate()
        }
        timers = []
    }
    
    func endQuiz() {
        //update data
        quiz.saveQuizResult(gold: goldCoins, silver: silverCoins)
        RZQuizDatabase.advanceLevelIfCurrentIsComplete()
        
        //disable the quiz
        touchRecognizer.enabled = false
        UIView.animateWithDuration(0.3) {
            self.questionText.alpha = 0.0
            self.questionContainer.alpha = 0.0
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
        coinString += "!"
        
        if silverCoins == 0 && goldCoins == 0 {
            coinString = "You didn't earn any coins."
            audioName = "quiz-over-bad"
        }
        
        var count = goldCoins + silverCoins
        if count == 0 { count = 5 }
        //update constraints for coinView
        coinView.removeConstraint(coinViewAspect)
        let newAspect = NSLayoutConstraint(item: coinView, attribute: .Width, relatedBy: .Equal, toItem: coinView, attribute: .Height, multiplier: CGFloat(count), constant: 0.0)
        coinView.addConstraint(newAspect)
        coinViewAspect = newAspect
        
        coinViewWidth.constant = -coinView.frame.height * CGFloat(5 - count)
        coinsLabel.text = coinString
        self.view.layoutIfNeeded()
        
        //update buttons
        let quizIndex = RZQuizDatabase.getIndexForRhyme(quiz)
        previousButton.hidden = quiz.getPrevious(fromFavorites: RZShowingFavorites) == nil
        nextButton.hidden = quiz.getNext(fromFavorites: RZShowingFavorites) == nil
        
        //cue audio
        UAPlayer().play(audioName, ofType: "mp3", ifConcurrent: .Interrupt)
        let audioLength = UALengthOfFile(audioName, ofType: "mp3")
        let timer = NSTimer.scheduledTimerWithTimeInterval(audioLength - 0.1, target: self, selector: "playCompletionSound", userInfo: count > 1, repeats: false)
        timers.append(timer)
        
        UIView.animateWithDuration(0.7, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: nil, animations: {
            self.quizOverViewTop.constant = 0.0
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func playCompletionSound() {
        let encouragement = true
        let name = "encouragement_"
        let count = encouragement ? 20 : 0
        let random = Int(arc4random_uniform(UInt32(count))) + 1
        UAPlayer().play("\(name)\(random)", ofType: ".mp3", ifConcurrent: .Ignore)
    }
    
    //MARK: - User Interaction
    var touchCurrentlyIn = -1
    
    @IBAction func touchDetected(sender: UITouchGestureRecognizer) {
        let touch = sender.locationInView(questionContainer)
        var touched: Int = -1
        
        for i in 0...3 {
            let frame = originalContainerFrames[i]
            if frame.contains(touch) && optionContainers[i].alpha == 1.0 {
                
                //end the speaking of the question
                stopAllTimers()
                
                //animate in repeat button
                UIView.animateWithDuration(0.6, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.AllowUserInteraction, animations: {
                    self.repeatButton.transform = CGAffineTransformMakeScale(1.0, 1.0)
                    }, completion: nil)
                self.repeatButton.enabled = true
                
                touched = i
                break
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
        var scale: CGFloat = 1.2
        let aspect = self.view.frame.width / self.view.frame.height
        if aspect > 1.8 { scale = 1.1 } //4S and iPad
        
        for container in optionContainers {
            if container.tag == option {
                UIView.animateWithDuration(0.3) {
                    container.transform = CGAffineTransformMakeScale(scale, scale)
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
    
    @IBAction func replayQuestion(sender: AnyObject) {
        if timers.count == 0 { //is the question playback timers aren't active
            playQuizAudio()
            shakeTitle()
        }
    }
    
    func shakeTitle() {
        let animations : [CGFloat] = [20.0, -20.0, 10.0, -10.0, 3.0, -3.0, 0]
        for i in 0 ..< animations.count {
            let frameOrigin = CGPointMake(questionText.frame.origin.x + animations[i], questionText.frame.origin.y)
            
            UIView.animateWithDuration(0.1, delay: NSTimeInterval(0.1 * Double(i)), options: nil, animations: {
                self.questionText.frame.origin = frameOrigin
                }, completion: nil)
        }
    }
    
    
    @IBAction func returnToRhyme(sender: AnyObject) {
        stopAllTimers()
        if UAIsAudioPlaying() {
            UAHaltPlayback()
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func playOffsetRhyme(sender: UIButton) {
        let offset = sender.tag
        let rhyme = self.quiz.getWithOffsetIndex(offset, fromFavorites: RZShowingFavorites)
        
        if let rhymeController = self.presentingViewController as? RhymeViewController, let rhyme = rhyme {
            rhymeController.decorate(rhyme)
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}

func setCoinsInImageViews(imageViews: [UIImageView], #gold: Int, #silver: Int, #big: Bool) {
    let goldImage = UIImage(named: big ? "coin-gold-big" : "coin-gold")
    let silverImage = UIImage(named: big ? "coin-silver-big" : "coin-silver")
    
    for i in 0 ..< gold {
        imageViews[i].alpha = 1.0
        imageViews[i].image = goldImage
    }
    for i in 0 ..< silver {
        imageViews[i + gold].alpha = 1.0
        imageViews[i + gold].image = silverImage
    }
    for i in 0 ..< imageViews.count {
        if i >= gold + silver {
            imageViews[i].alpha = (gold + silver == 0 ? 0.2 : 0.0)
            imageViews[i].image = goldImage
        }
    }
}
