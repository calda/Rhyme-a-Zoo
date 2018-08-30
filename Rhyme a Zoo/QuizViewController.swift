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
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var blurredBackground: UIImageView!
    @IBOutlet weak var questionText: UILabel!
    @IBOutlet weak var backToRhymeButton: UIButton!
    @IBOutlet var optionIcons: [UIImageView]!
    @IBOutlet var optionLabels: [UILabel]!
    @IBOutlet var phoneticLabels: [UILabel]!
    
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
    var quizPlayedBefore = false
    var dismissAfterPlaying = true
    
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
        sortOutletCollectionByTag(&optionIcons)
        sortOutletCollectionByTag(&optionLabels)
        sortOutletCollectionByTag(&optionContainers)
        sortOutletCollectionByTag(&coins)
        sortOutletCollectionByTag(&phoneticLabels)
        
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
            container.superview?.layoutIfNeeded()
            container.layoutIfNeeded()
            originalContainerFrames.append(container.frame)
        }
        
        //create dynamic back button
        let quizNumber = quiz.number.threeCharacterString()
        let image = UIImage(named: "thumbnail_\(quizNumber).jpg")!
        createDynamicButtonWithImage(image)
        
        startQuiz(quiz, playAudio: false)
    }
    
    override func viewDidAppear(animated: Bool) {
        playQuizAudio()
    }
    
    func createDynamicButtonWithImage(content: UIImage) {
        async() {
            let scale = UIScreen.mainScreen().scale
            let scaleTrait = UITraitCollection(displayScale: scale)
            let foreground = UIImage(named: "button-dynamic-top")!
            let background = UIImage(named: "button-dynamic-bottom")!
            
            UIGraphicsBeginImageContextWithOptions(background.size, false, 1)
            background.drawAtPoint(CGPointZero)
            
            //draw zookeeper in center
            let size = CGSizeMake(90, 90)
            let origin = CGPointMake(5, 5)
            
            let cropped = cropImageToCircle(content)
            cropped.drawInRect(CGRect(origin: origin, size: size))
            
            foreground.drawAtPoint(CGPointZero)
            
            let composite = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            self.backToRhymeButton.setImage(composite, forState: .Normal)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        stopAllTimers()
        if UAIsAudioPlaying() {
            UAHaltPlayback()
        }
    }
    
    func startQuiz(quiz: Quiz, playAudio: Bool = true) {
        quizPlayedBefore = quiz.quizHasBeenPlayed()

        var animateTransition = (self.quiz != nil) //is not first quiz
        self.quiz = quiz
        let quizNumber = quiz.number.threeCharacterString()
        blurredBackground.image = UIImage(named: "illustration_\(quizNumber).jpg")
        
        if animateTransition {
            playTransitionForView(blurredBackground, duration: 1.0, transition: kCATransitionFade)
        }
        
        questionNumber = -1
        nextQuestion(playAudio)
    }
    
    func nextQuestion(playAudio: Bool = true) {
        questionNumber += 1
        answerAttempts = 0
        
        if questionNumber >= 4 {
            endQuiz()
            return
        }
        
        question = quiz.questions[questionNumber]
        options = question.shuffledOptions
        
        //decorate screen
        questionText.text = question.text
        
        for i in 0 ... 3 {
            let option = options[i]
            optionLabels[i].text = option.word
            optionContainers[i].alpha = 1.0
            phoneticLabels[i].hidden = true
            
            //find the image for the word
            var image = UIImage(named: option.rawWord + ".jpg")
            if image == nil {
                image = UIImage(named: option.rawWord.lowercaseString + ".jpg")
            }
            if image == nil {
                
                optionIcons[i].image = UIImage(named: "blank-white.jpg")
                
                if option.rawWord.hasPrefix("sound-") {
                    //is phonetic question
                    phoneticLabels[i].hidden = false
                    phoneticLabels[i].text = option.word
                    if option.word.characters.count == 1 {
                        phoneticLabels[i].text = "\(option.word) \(option.word.lowercaseString)"
                    }
                    
                    //properly center the text
                    var font = UIFont(name: "TimesNewRomanPS-BoldMT", size: 120.0)!
                    let text = "UGH" as NSString
                    
                    while text.sizeWithAttributes([NSFontAttributeName : font]).width > phoneticLabels[i].frame.height {
                        font = UIFont(name: "TimesNewRomanPS-BoldMT", size: font.pointSize - 10.0)!
                    }
                    
                    phoneticLabels[i].font = font
                    self.view.layoutIfNeeded()
                    
                }
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
            let audioName = options[i].rawWord
            var duration = UALengthOfFile(audioName, ofType: "mp3")
            duration = max(1.0, duration)
            
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
            
            let audioName = options[option].rawWord
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
        if goldCoins == 4 { goldCoins = 5 }
        
        //update data
        if !quizPlayedBefore {
            quiz.saveQuizResult(gold: goldCoins, silver: silverCoins)
            let previousLevel = RZQuizDatabase.currentLevel()
            let levelUp = RZQuizDatabase.advanceLevelIfCurrentIsComplete()
            
            if levelUp && (previousLevel == 24 || previousLevel == 25) {
                //game is won
                delay(3.5) {
                    playVideo(name: "game-over", currentController: self, completion: {
                        UAHaltPlayback()
                        self.stopAllTimers()
                        self.dismissViewControllerAnimated(true, completion: nil)
                    })
                }
                self.dismissAfterPlaying = false //keep this view from dismissing itself
            }
        }
        
        //disable the quiz
        touchRecognizer.enabled = false
        UIView.animateWithDuration(0.3) {
            self.questionText.alpha = 0.0
            self.questionContainer.alpha = 0.0
        }
        
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
        
        //cue audio
        UAPlayer().play(audioName, ofType: "mp3", ifConcurrent: .Interrupt)
        var audioLength = UALengthOfFile(audioName, ofType: "mp3")
        if audioName == "quiz-over-bad" { audioLength -= 2.0 }
        
        let timer = NSTimer.scheduledTimerWithTimeInterval(audioLength - 0.1, target: self, selector: "playCompletionSound", userInfo: count > 1, repeats: false)
        timers.append(timer)
        
        //update buttons
        let quizIndex = RZQuizDatabase.getIndexForRhyme(quiz)
        previousButton.hidden = quiz.getPrevious(fromFavorites: RZShowingFavorites) == nil
        nextButton.hidden = quiz.getNext(fromFavorites: RZShowingFavorites) == nil
        //hide buttons if this was the first time playing the quizes but only if there is a next unplayed to go to
        let hideButtons = !self.quizPlayedBefore && quiz.getNextUnplayed(RZShowingFavorites) != nil
        nextButton.hidden = nextButton.hidden || hideButtons
        previousButton.hidden = previousButton.hidden || hideButtons
        
        UIView.animateWithDuration(0.7, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: [], animations: {
            self.quizOverViewTop.constant = 0.0
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func playCompletionSound() {
        
        let total = CGFloat(self.goldCoins) + CGFloat(self.silverCoins)
        let encouragement = total > 2.0
        let name = encouragement ? "encouragement_" : "do-better_"
        let count = encouragement ? 20 : 11
        let random = Int(arc4random_uniform(UInt32(count))) + 1
        UAPlayer().play("\(name)\(random)", ofType: ".mp3", ifConcurrent: .Interrupt)
        let duration = UALengthOfFile("\(name)\(random)", ofType: ".mp3")
        
        //transition to next unplayed rhyme
        if !quizPlayedBefore && dismissAfterPlaying {
            delay(duration + 0.5) {
                let unplayed = self.quiz.getNextUnplayed(RZShowingFavorites)
                
                if let rhymeController = self.presentingViewController as? RhymeViewController, let rhyme = unplayed {
                    rhymeController.decorate(rhyme)
                }
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        }
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
        if aspect < 1.35 { scale = 1.1 } //4S and iPad
        
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
                RZQuizDatabase.updatePercentCorrect(question, correct: true)
            } else if answerAttempts == 2 {
                silverCoins++
                RZQuizDatabase.updatePercentCorrect(question, correct: false)
            } else {
                RZQuizDatabase.updatePercentCorrect(question, correct: false)
            }
            
            //halt question audio if it is still playing
            if UAIsAudioPlaying() {
                stopAllTimers()
                UAHaltPlayback()
            }
            
            //play sound effect
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
            UIView.animateWithDuration(0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: [], animations: {
                self.optionContainers[guess].center = center
                }, completion: nil)
            
            UIView.animateWithDuration(0.7, delay: 0.0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0.0, options: [], animations: {
                self.optionContainers[guess].transform = CGAffineTransformMakeScale(1.3, 1.3)
                }, completion: nil) 
            
            delay(1.0) {
                if self.questionNumber != 3 {
                    self.optionContainers[guess].transform = CGAffineTransformMakeScale(1.0, 1.0)
                    self.optionContainers[guess].frame = self.originalContainerFrames[guess]
                }
                self.nextQuestion()
            }
            
            //disable repeat button
            UIView.animateWithDuration(0.6, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.AllowUserInteraction, animations: {
                self.repeatButton.transform = CGAffineTransformMakeScale(0.75,0.75)
                }, completion: nil)
            self.repeatButton.enabled = false
            
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
            shakeView(questionText)
        }
    }
    
    @IBAction func returnToRhyme(sender: AnyObject) {
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

func setCoinsInImageViews(_ imageViews: [UIImageView], gold: Int, silver: Int, big: Bool) {
    let goldImage = UIImage(named: big ? "coin-gold-big" : iPad() ? "coin-gold-medium" : "coin-gold")
    let silverImage = UIImage(named: big ? "coin-silver-big" : iPad() ? "coin-silver-medium" : "coin-silver")
    
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
