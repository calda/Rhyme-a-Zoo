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
    
    var timers: [Timer] = []
    
    //MARK: - Managing the view controller
    
    override func viewWillAppear(_ animated: Bool) {
        self.view.clipsToBounds = true
        //sort IB arrays
        sortOutletCollectionByTag(&optionIcons)
        sortOutletCollectionByTag(&optionLabels)
        sortOutletCollectionByTag(&optionContainers)
        sortOutletCollectionByTag(&coins)
        sortOutletCollectionByTag(&phoneticLabels)
        
        quizOverView.backgroundColor = UIColor.clear
        quizOverViewTop.constant = -UIScreen.main.bounds.height
        self.view.layoutIfNeeded()
        
        for icon in optionIcons {
            icon.layer.masksToBounds = true
            icon.clipsToBounds = true
            icon.layer.cornerRadius = icon.frame.height / 6.0
            icon.layer.borderColor = UIColor.white.cgColor
            icon.layer.borderWidth = 2.0
        }
        
        //create dynamic back button
        let quizNumber = quiz.number.threeCharacterString
        let image = UIImage(named: "thumbnail_\(quizNumber).jpg")!
        createDynamicButtonWithImage(image)
        
        startQuiz(quiz, playAudio: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        playQuizAudio()
        
        // save the original frames of the quiz options
        for container in optionContainers {
            container.superview?.layoutIfNeeded()
            container.layoutIfNeeded()
            originalContainerFrames.append(container.frame)
        }
    }
    
    func createDynamicButtonWithImage(_ content: UIImage) {
        async() {
            let foreground = UIImage(named: "button-dynamic-top")!
            let background = UIImage(named: "button-dynamic-bottom")!
            
            UIGraphicsBeginImageContextWithOptions(background.size, false, 1)
            background.draw(at: CGPoint.zero)
            
            //draw zookeeper in center
            let size = CGSize(width: 90, height: 90)
            let origin = CGPoint(x: 5, y: 5)
            
            let cropped = cropImageToCircle(content)
            cropped.draw(in: CGRect(origin: origin, size: size))
            
            foreground.draw(at: CGPoint.zero)
            
            let composite = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            self.backToRhymeButton.setImage(composite, for: .normal)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        stopAllTimers()
        if UAIsAudioPlaying() {
            UAHaltPlayback()
        }
    }
    
    func startQuiz(_ quiz: Quiz, playAudio: Bool = true) {
        quizPlayedBefore = quiz.quizHasBeenPlayed()

        let animateTransition = (self.quiz != nil) //is not first quiz
        self.quiz = quiz
        let quizNumber = quiz.number.threeCharacterString
        blurredBackground.image = UIImage(named: "illustration_\(quizNumber).jpg")
        
        if animateTransition {
            playTransitionForView(blurredBackground, duration: 1.0, transition: convertFromCATransitionType(.fade))
        }
        
        questionNumber = -1
        nextQuestion(playAudio)
    }
    
    func nextQuestion(_ playAudio: Bool = true) {
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
            phoneticLabels[i].isHidden = true
            
            //find the image for the word
            var image = UIImage(named: option.rawWord + ".jpg")
            if image == nil {
                image = UIImage(named: option.rawWord.lowercased() + ".jpg")
            }
            if image == nil {
                
                optionIcons[i].image = UIImage(named: "blank-white.jpg")
                
                if option.rawWord.hasPrefix("sound-") {
                    //is phonetic question
                    phoneticLabels[i].isHidden = false
                    phoneticLabels[i].text = option.word
                    if option.word.count == 1 {
                        phoneticLabels[i].text = "\(option.word) \(option.word.lowercased())"
                    }
                    
                    //properly center the text
                    var font = UIFont(name: "TimesNewRomanPS-BoldMT", size: 120.0)!
                    let text = "UGH" as NSString
                    
                    while text.size(withAttributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font) : font])).width > phoneticLabels[i].frame.height {
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
        
        UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
            self.repeatButton.transform = CGAffineTransform(scaleX: 0.75,y: 0.75)
        }, completion: nil)
        self.repeatButton.isEnabled = false
        
        //play audio
        let audioNumber = question.number.threeCharacterString
        let audioName = "question_\(audioNumber)"
        UAPlayer().play(audioName, ofType: "mp3", ifConcurrent: .interrupt)
        
        let questionLength = UALengthOfFile(audioName, ofType: "mp3")
        var currentDelay = questionLength
        
        for i in 0...4 {
            //don't play audio if the item isn't visible
            if i != 4 && optionContainers[i].alpha == 0 { continue }
            
            let timer = Timer.scheduledTimer(timeInterval: currentDelay, target: self, selector: #selector(QuizViewController.playAudioForOption(_:)), userInfo: i, repeats: false)
            timers.append(timer)
            
            if i == 4 { continue }
            //calculate next delay
            let audioName = options[i].rawWord
            var duration = UALengthOfFile(audioName, ofType: "mp3")
            duration = max(1.0, duration)
            
            currentDelay += duration
        }
    }
    
    @objc func playAudioForOption(_ timer: Timer) {
        if let option = timer.userInfo as? Int{
            self.highlightOption(option)
            if option == 4 {
                
                //animate in repeat button
                UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
                    self.repeatButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    }, completion: nil)
                self.repeatButton.isEnabled = true
                
                stopAllTimers()
                return
            }
            
            let audioName = options[option].rawWord
            UAPlayer().play(audioName, ofType: "mp3", ifConcurrent: .interrupt)
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
                        self.dismiss(animated: true, completion: nil)
                    })
                }
                self.dismissAfterPlaying = false //keep this view from dismissing itself
            }
        }
        
        //disable the quiz
        touchRecognizer.isEnabled = false
        UIView.animate(withDuration: 0.3, animations: {
            self.questionText.alpha = 0.0
            self.questionContainer.alpha = 0.0
        }) 
        
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
        let newAspect = NSLayoutConstraint(item: coinView, attribute: .width, relatedBy: .equal, toItem: coinView, attribute: .height, multiplier: CGFloat(count), constant: 0.0)
        coinView.addConstraint(newAspect)
        coinViewAspect = newAspect
        
        coinViewWidth.constant = -coinView.frame.height * CGFloat(5 - count)
        coinsLabel.text = coinString
        self.view.layoutIfNeeded()
        
        //cue audio
        UAPlayer().play(audioName, ofType: "mp3", ifConcurrent: .interrupt)
        var audioLength = UALengthOfFile(audioName, ofType: "mp3")
        if audioName == "quiz-over-bad" { audioLength -= 2.0 }
        
        let timer = Timer.scheduledTimer(timeInterval: audioLength - 0.1, target: self, selector: #selector(QuizViewController.playCompletionSound), userInfo: count > 1, repeats: false)
        timers.append(timer)
        
        //update buttons
        previousButton.isHidden = quiz.getPrevious(fromFavorites: RZShowingFavorites) == nil
        nextButton.isHidden = quiz.getNext(fromFavorites: RZShowingFavorites) == nil
        //hide buttons if this was the first time playing the quizes but only if there is a next unplayed to go to
        let hideButtons = !self.quizPlayedBefore && quiz.getNextUnplayed(RZShowingFavorites) != nil
        nextButton.isHidden = nextButton.isHidden || hideButtons
        previousButton.isHidden = previousButton.isHidden || hideButtons
        
        UIView.animate(withDuration: 0.7, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: [], animations: {
            self.quizOverViewTop.constant = 0.0
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    @objc func playCompletionSound() {
        
        let total = CGFloat(self.goldCoins) + CGFloat(self.silverCoins)
        let encouragement = total > 2.0
        let name = encouragement ? "encouragement_" : "do-better_"
        let count = encouragement ? 20 : 11
        let random = Int(arc4random_uniform(UInt32(count))) + 1
        UAPlayer().play("\(name)\(random)", ofType: ".mp3", ifConcurrent: .interrupt)
        let duration = UALengthOfFile("\(name)\(random)", ofType: ".mp3")
        
        //transition to next unplayed rhyme
        if !quizPlayedBefore && dismissAfterPlaying {
            delay(duration + 0.5) {
                let unplayed = self.quiz.getNextUnplayed(RZShowingFavorites)
                
                if let rhymeController = self.presentingViewController as? RhymeViewController, let rhyme = unplayed {
                    rhymeController.decorate(rhyme)
                }
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    //MARK: - User Interaction
    var touchCurrentlyIn = -1
    
    @IBAction func touchDetected(_ sender: UITouchGestureRecognizer) {
        let touch = sender.location(in: questionContainer)
        var touched: Int = -1
        
        for i in 0...3 {
            let frame = originalContainerFrames[i]
            if frame.contains(touch) && optionContainers[i].alpha == 1.0 {
                
                //end the speaking of the question
                stopAllTimers()
                
                //animate in repeat button
                UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
                    self.repeatButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    }, completion: nil)
                self.repeatButton.isEnabled = true
                
                touched = i
                break
            }
        }
        
        if sender.state == .ended {
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
    
    func highlightOption(_ option: Int) {
        var scale: CGFloat = 1.1
        let aspect = self.view.frame.width / self.view.frame.height
        if aspect < 1.35 { scale = 1.03 } //4S and iPad
        
        for container in optionContainers {
            if container.tag == option {
                UIView.animate(withDuration: 0.225, animations: {
                    container.transform = CGAffineTransform(scaleX: scale, y: scale)
                }) 
            } else {
                UIView.animate(withDuration: 0.225, animations: {
                    container.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                }) 
            }
        }
    }
    
    func checkAnswer(_ guess: Int) {
        answerAttempts += 1
        let answer = question.answer
        let option = options[guess]
        
        if option.word == answer { //correct
            
            if answerAttempts == 1 {
                goldCoins += 1
                RZQuizDatabase.updatePercentCorrect(question, correct: true)
            } else if answerAttempts == 2 {
                silverCoins += 1
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
            UAPlayer().play("correct", ofType: "mp3", ifConcurrent: .interrupt)
            
            //fade others
            for i in 0...3 {
                if i != guess {
                    UIView.animate(withDuration: 0.2, animations: {
                        self.optionContainers[i].alpha = 0.0
                    }) 
                }
            }
            
            //animate self to center
            let center = CGPoint(x: self.questionContainer.frame.width / 2.0, y: self.questionContainer.frame.height / 2.0)
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: [], animations: {
                self.optionContainers[guess].center = center
                }, completion: nil)
            
            UIView.animate(withDuration: 0.7, delay: 0.0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0.0, options: [], animations: {
                self.optionContainers[guess].transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
                }, completion: nil) 
            
            delay(1.0) {
                if self.questionNumber != 3 {
                    self.optionContainers[guess].transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    self.optionContainers[guess].frame = self.originalContainerFrames[guess]
                }
                self.nextQuestion()
            }
            
            //disable repeat button
            UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
                self.repeatButton.transform = CGAffineTransform(scaleX: 0.75,y: 0.75)
                }, completion: nil)
            self.repeatButton.isEnabled = false
            
        } else { //incorrect
            UAPlayer().play("incorrect", ofType: "mp3", ifConcurrent: .interrupt)
            UIView.animate(withDuration: 0.2, animations: {
                self.optionContainers[guess].alpha = 0.0
            }) 
        }
    }
    
    @IBAction func replayQuestion(_ sender: AnyObject) {
        if timers.count == 0 { //is the question playback timers aren't active
            playQuizAudio()
            shakeView(questionText)
        }
    }
    
    @IBAction func returnToRhyme(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func playOffsetRhyme(_ sender: UIButton) {
        let offset = sender.tag
        let rhyme = self.quiz.getWithOffsetIndex(offset, fromFavorites: RZShowingFavorites)
        
        if let rhymeController = self.presentingViewController as? RhymeViewController, let rhyme = rhyme {
            rhymeController.decorate(rhyme)
        }
        self.dismiss(animated: true, completion: nil)
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

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromCATransitionType(_ input: CATransitionType) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
