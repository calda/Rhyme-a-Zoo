//
//  RhymeViewController.swift
//  Rhyme a Zoo
//
//  Created by Cal on 7/2/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import Foundation
import UIKit

class RhymeViewController : UIViewController {
    
    @IBOutlet weak var rhymePage: UIImageView!
    @IBOutlet weak var blurredPage: UIImageView!
    @IBOutlet weak var buttonGradientView: UIView!
    @IBOutlet weak var buttonGradientWidth: NSLayoutConstraint!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var quizButton: UIButton!
    var rhymeTimer: Timer?
    var quizBounceTimer: Timer?
    @IBOutlet weak var repeatButton: UIButton!
    @IBOutlet weak var repeatHeight: NSLayoutConstraint!
    @IBOutlet weak var rhymeText: UILabel!
    @IBOutlet weak var scrollContent: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollContentHeight: NSLayoutConstraint!
    var rhymeString: String!
    
    var rhyme: Rhyme! = Rhyme(1) //for testing if this is inital
    var nextRhyme: Rhyme?
    var previousRhyme: Rhyme?
    
    func decorate(_ rhyme: Rhyme) {
        self.rhyme = rhyme
    }
    
    //MARK: - View Setup
    
    func decorateForRhyme(_ rhyme: Rhyme, updateBackground: Bool = true) {
        //decorate cell for rhyme
        let number = rhyme.number.threeCharacterString
        let illustration = UIImage(named: "illustration_\(number).jpg")
        rhymePage.image = illustration
        if updateBackground { blurredPage.image = illustration }
        
        let rawText = rhyme.rhymeText
        //add new lines
        var text = rawText.replacingOccurrences(of: "/", with: "\n", options: [], range: nil)
        text = text.replacingOccurrences(of: ";", with: ",", options: [], range: nil)
        text = text.replacingOccurrences(of: "\'", with: "'", options: [], range: nil)
        text = text.replacingOccurrences(of: "/", with: "\n", options: [], range: nil)
        rhymeString = text
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 9.5
        let attributed = NSAttributedString(string: rhymeString, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.paragraphStyle) : paragraphStyle]))
        rhymeText.attributedText = attributed
        
        //set up buttons
        previousRhyme = rhyme.getPrevious(fromFavorites: RZShowingFavorites)
        nextRhyme = rhyme.getNext(fromFavorites: RZShowingFavorites)
        previousButton.isHidden = previousRhyme == nil
        nextButton.isHidden = nextRhyme == nil
        
        let quizPlayed = rhyme.quizHasBeenPlayed()
        quizButton.setImage(UIImage(named: (quizPlayed ? "button-check" : "button-question")), for: .normal)
        quizButton.isEnabled = false
        
        let favorite = rhyme.isFavorite()
        likeButton.setImage(UIImage(named: (favorite ? "button-unlike" : "button-heart")), for: .normal)
        
    }
    
    override func viewWillAppear(_ animate: Bool) {
        view.clipsToBounds = true
        decorateForRhyme(rhyme)

        //set up buttons
        repeatHeight.constant = 0
        repeatButton.imageView!.contentMode = .scaleAspectFit
        view.layoutIfNeeded()
        
        updateScrollView()

        // mask the rhyme page, but wait until after the first layout pass is over
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
            let height = self.rhymePage.frame.height
            let maskHeight = height - 20.0 - (iPad() ? 60.0 : 0.0)
            let maskWidth = (self.rhymePage.frame.width / self.rhymePage.frame.height) * maskHeight
            let maskRect = CGRect(x: 10.0, y: 10.0, width: maskWidth, height: maskHeight)
            
            let maskLayer = CAShapeLayer()
            maskLayer.path = UIBezierPath(roundedRect: maskRect, cornerRadius: maskHeight / 20.0).cgPath
            self.rhymePage.layer.mask = maskLayer
        })
    }
    
    func updateScrollView() {
        //check if the content height needs to be updated
        let width = scrollView.frame.width
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 9.5
        let attributes = [convertFromNSAttributedStringKey(NSAttributedString.Key.paragraphStyle) : paragraphStyle, convertFromNSAttributedStringKey(NSAttributedString.Key.font) : rhymeText.font] as [String : Any]
        let idealSize = (rhymeString as NSString).boundingRect(with: CGSize(width: width, height: 1000), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: convertToOptionalNSAttributedStringKeyDictionary(attributes), context: nil)
        
        let difference = abs(idealSize.height - scrollView.frame.height)
        if difference > 6.0 && idealSize.height > scrollView.frame.height {
            scrollContentHeight.constant = difference * 1.2
            self.view.layoutIfNeeded()
        } else {
            scrollContentHeight.constant = 0.0
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        delay(0.05) {
            if !self.willPlayAnimalVideo() {
                self.rhymeTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(RhymeViewController.playRhyme), userInfo: nil, repeats: false)
            }
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        delay(0.06) {
            self.rhymeTimer?.invalidate()
        }
        UAHaltPlayback()
    }
    
    //MARK: - Handling Playback of the Rhyme
    
    var rhymeTimers: [Timer]?
    
    @objc func playRhyme() {
        quizBounceTimer?.invalidate()
        
        //disable quiz button if it hasn't been played yet
        quizButton.isEnabled = false
        
        let number = rhyme.number.threeCharacterString
        let audioName = "rhyme_\(number)"
        let success = UAPlayer().play(audioName, ofType: "mp3", ifConcurrent: .ignore)
        
        if success {
            let wordTimes = rhyme.wordStartTimes
            
            rhymeTimers = []
            
            for word in 0 ..< wordTimes.count {
                let msec = wordTimes[word]
                let timeInterval = Double(msec) / 1000.0
                let timer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(RhymeViewController.updateWord(_:)), userInfo: word, repeats: false)
                rhymeTimers?.append(timer)
            }
        }
    }
    
    @objc func updateWord(_ timer: Timer) {
        if let word = timer.userInfo as? Int {
            updateAttributedTextForCurrentWord(word)
        }
    }
    
    func updateAttributedTextForCurrentWord(_ currentWord: Int) {
        
        guard let text = rhymeString else { return }
        let replacedLineBreaks = text.replacingOccurrences(of: "\n", with: "~\n", options: [], range: nil)
        let noSpaces = replacedLineBreaks.replacingOccurrences(of: " ", with: "\n", options: [], range: nil)
        let words = noSpaces.components(separatedBy: "\n")
        var before: String = ""
        var current: String = ""
        var after: String = ""
        
        for i in 0 ..< words.count {
            let word = words[i]
            if i < currentWord { before = before + word + " " }
            else if i == currentWord { current = "\(word) " }
            else { after = after + word + " "}
        }
        
        //add line breaks back in
        before = before.replacingOccurrences(of: "~ ", with: "\n", options: [], range: nil)
        current = current.replacingOccurrences(of: "~ ", with: "\n", options: [], range: nil)
        after = after.replacingOccurrences(of: "~ ", with: "\n", options: [], range: nil)
        
        if current == "" {
            //current was empty so this is the end of the audio
            UAHaltPlayback()
            delay(1.0) {
                self.rhymeFinishedPlaying()
            }
        }
        
        //build attributed string
        let beforeColor = UIColor(white: 0.14, alpha: 1.0)
        let currentColor = UIColor(hue: 0.597, saturation: 0.89, brightness: 0.64, alpha: 1.0)
        let afterColor = UIColor(white: 0.14, alpha: 0.6)
        let colors = [beforeColor, currentColor, afterColor]
        let rawParts = [before, current, after]
        let finalString = NSMutableAttributedString(string: "")
        
        for i in 0...2 {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.paragraphSpacing = 9.5
            
            let color = colors[i]
            let part = rawParts[i]
            let attributes = [
                convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor) : color,
                convertFromNSAttributedStringKey(NSAttributedString.Key.paragraphStyle) : paragraphStyle
            ]
            let attributed = NSAttributedString(string: part, attributes: convertToOptionalNSAttributedStringKeyDictionary(attributes))
            finalString.append(attributed)
        }
        
        rhymeText.attributedText = finalString
        
        scrollCurrentLineToVisible(currentWord)
    }
    
    func scrollCurrentLineToVisible(_ currentWord: Int) {
        
        if scrollContent.frame.height > scrollView.frame.height {
            
            let availableHeight = scrollView.frame.height
            guard let text = rhymeString else { return }
            let lines = getLinesArrayOfStringInLabel(text as NSString, label: rhymeText)
            
            //get line with current
            var lineWithCurrent = -1
            var currentLinePosition: CGFloat = 0
            var numberOfWords = 0
            
            for l in 0 ..< lines.count {
                if lineWithCurrent != -1 { continue }
                
                let line = lines[l]
                let words = line.components(separatedBy: " ")
                for _ in words {
                    if numberOfWords == currentWord {
                        lineWithCurrent = l
                    }
                    numberOfWords += 1
                }
                
                if lineWithCurrent != -1 { continue }
                
                var lineHeight = rhymeText.font.lineHeight
                if (line as NSString).contains("\n") {
                    //is a paragraph break
                    lineHeight += 9.5
                }
                currentLinePosition += lineHeight
            }
            
            if lineWithCurrent == -1 { //no word is highlighed, only happens at the end
                currentLinePosition = CGFloat.greatestFiniteMagnitude //mimic all the way at the bottom
            }
            
            //do nothing if currentLinePosition is less than half-way down the block
            if currentLinePosition < availableHeight / 2 {
                currentLinePosition = 0
            }
            
            //bottom line must always be at the bottom of the frame
            if currentLinePosition + (availableHeight) > scrollContent.frame.height {
                currentLinePosition = scrollContent.frame.height - (availableHeight)
            }
            
            scrollView.setContentOffset(CGPoint(x: 0, y: currentLinePosition), animated: true)
            
            
        }
    }
    
    
    func rhymeFinishedPlaying() {
        
        //animate buttons
        repeatHeight.constant = 50
        quizButton.isEnabled = true
        UIView.animate(withDuration: 0.7, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
        
        quizBounceTimer?.invalidate()
        if !rhyme.quizHasBeenPlayed() {
            self.quizBounceTimer = Timer.scheduledTimer(timeInterval: 3.5, target: self, selector: #selector(RhymeViewController.bounceQuizIcon), userInfo: nil, repeats: true)
            delay(0.25) {
                return // FIXME
                self.quizButtonPressed(self)
            }
        }
    }
    
    @objc func bounceQuizIcon() {
        if !quizButton.isEnabled {
            quizBounceTimer?.invalidate()
            return
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.quizButton.transform = CGAffineTransform(translationX: 0.0, y: -50.0)
            }, completion: { success in
                UIView.animate(withDuration: 0.7, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.0, options: [], animations: {
                    self.quizButton.transform = CGAffineTransform(translationX: 0.0, y: 0.0)
                    }, completion: nil)
        })
    }
    
    //MARK: - Interface Buttons
    
    @IBAction func repeatButtonPressed(_ sender: AnyObject) {
        playRhyme()
        repeatHeight.constant = 0
        UIView.animate(withDuration: 0.4, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    @IBAction func likeButtonPressed(_ sender: UIButton) {
        let favorite = !rhyme.isFavorite()
        rhyme.setFavoriteStatus(favorite)
        
        self.likeButton.setImage(UIImage(named: (favorite ? "button-unlike" : "button-heart")), for: .normal)
        playTransitionForView(self.likeButton, duration: 2.0, transition: "rippleEffect")
    }
    
    func endPlayback() {
        quizBounceTimer?.invalidate()
        UAHaltPlayback()
        
        //cancel rhyme timers
        if let timers = rhymeTimers {
            for timer in timers {
                timer.invalidate()
            }
        }
    }
    
    @IBAction func listButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
        endPlayback()
    }
    
    @IBAction func quizButtonPressed(_ sender: AnyObject) {
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "quiz") as! QuizViewController
        controller.quiz = rhyme
        quizBounceTimer?.invalidate()
        self.present(controller, animated: true, completion: nil)
    }
    
    
    //MARK: - Transitioning between rhymes
    
    @IBAction func nextRhyme(_ sender: UIButton) {
        if let next = nextRhyme {
            animateChangeToRhyme(next, transition: "pageCurl")
        }
    }
    
    @IBAction func previousRhyme(_ sender: UIButton) {
        if let previous = previousRhyme {
            animateChangeToRhyme(previous, transition: "pageCurl")
        }
    }
    
    func animateChangeToRhyme(_ rhyme: Rhyme, transition: String) {
        
        nextButton.isEnabled = false
        quizButton.isEnabled = false
        previousButton.isEnabled = false
        
        repeatHeight.constant = 0
        UIView.animate(withDuration: 0.4, animations: {
            self.view.layoutIfNeeded()
        })
        
        self.rhyme = rhyme
        decorateForRhyme(rhyme, updateBackground: false)
        updateScrollView()
        endPlayback()
        playTransitionForView(self.view, duration: 0.5, transition: transition)
        delay(0.5) {
            self.blurredPage.image = self.rhymePage.image
            playTransitionForView(self.blurredPage, duration: 1.0, transition: convertFromCATransitionType(.fade))
            delay(0.6) {
                self.playRhyme()
                self.nextButton.isEnabled = true
                self.previousButton.isEnabled = true
            }
        }
        
    }
    
    //MARK: - Playing "Buy your animal" video
    
    func willPlayAnimalVideo() -> Bool {
        let balance = RZQuizDatabase.getPlayerBalance()
        let numberOfAnimals = RZQuizDatabase.getOwnedAnimals().count
        
        var videoToPlay: String? = nil
        if balance >= 20 && numberOfAnimals == 0 { videoToPlay = "animals-video" }
        if balance >= 60 { videoToPlay = "too-much-money" }
        
        if let videoToPlay = videoToPlay {
            playAnimalVideo(videoToPlay)
            return true
        }
        
        return false
    }
    
    func playAnimalVideo(_ name: String) {
        playVideo(name: name, currentController: self, completion: {
            //present the current zoo level building
            let currentZooLevel = RZQuizDatabase.currentZooLevel()
            let building = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "building") as! BuildingViewController
            building.mustBuy = true
            building.decorate(building: currentZooLevel, displaySize: self.view.frame.size, displayInsets: self.view.raz_safeAreaInsets)
            self.present(building, animated: true, completion: nil)
        })
    }
    
}

///stackoverflow.com/questions/4421267/how-to-get-text-from-nth-line-of-uilabel
func getLinesArrayOfStringInLabel(_ text: NSString, label:UILabel) -> [String] {
    
    let font = label.font!
    let rect = label.frame
    
    let myFont = CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)
    let attStr:NSMutableAttributedString = NSMutableAttributedString(string: text as String)
    attStr.addAttribute(convertToNSAttributedStringKey(String(kCTFontAttributeName)), value:myFont, range: NSMakeRange(0, attStr.length))
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.paragraphSpacing = 9.5
    attStr.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attStr.length))
    
    let frameSetter = CTFramesetterCreateWithAttributedString(attStr as CFAttributedString)
    
    let path = CGPath(rect: CGRect(x: 0, y: 0, width: rect.size.width, height: 100000), transform: nil)
    let frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), path, nil)
    let lines = CTFrameGetLines(frame) as! [CTLine]
    var linesArray = [String]()
    
    for line in lines {
        let lineRange = CTLineGetStringRange(line)
        let range:NSRange = NSMakeRange(lineRange.location, lineRange.length)
        let lineString = text.substring(with: range)
        linesArray.append(lineString as String)
    }
    
    return linesArray
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

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromCATransitionType(_ input: CATransitionType) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSAttributedStringKey(_ input: String) -> NSAttributedString.Key {
	return NSAttributedString.Key(rawValue: input)
}
