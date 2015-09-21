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
    @IBOutlet weak var likeBottom: NSLayoutConstraint!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var quizButton: UIButton!
    var rhymeTimer: NSTimer?
    var quizBounceTimer: NSTimer?
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
    
    func decorate(rhyme: Rhyme) {
        self.rhyme = rhyme
    }
    
    //MARK: - View Setup
    
    func decorateForRhyme(rhyme: Rhyme, updateBackground: Bool = true) {
        //decorate cell for rhyme
        let number = rhyme.number.threeCharacterString()
        let illustration = UIImage(named: "illustration_\(number).jpg")
        rhymePage.image = illustration
        if updateBackground { blurredPage.image = illustration }
        
        let rawText = rhyme.rhymeText
        //add new lines
        var text = rawText.stringByReplacingOccurrencesOfString("/", withString: "\n", options: nil, range: nil)
        text = text.stringByReplacingOccurrencesOfString(";", withString: ",", options: nil, range: nil)
        text = text.stringByReplacingOccurrencesOfString("\'", withString: "'", options: nil, range: nil)
        text = text.stringByReplacingOccurrencesOfString("/", withString: "\n", options: nil, range: nil)
        rhymeString = text
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 9.5
        let attributed = NSAttributedString(string: rhymeString, attributes: [NSParagraphStyleAttributeName : paragraphStyle])
        rhymeText.attributedText = attributed
        
        //set up buttons
        let rhymeIndex = RZQuizDatabase.getIndexForRhyme(rhyme)
        previousRhyme = rhyme.getPrevious(fromFavorites: RZShowingFavorites)
        nextRhyme = rhyme.getNext(fromFavorites: RZShowingFavorites)
        previousButton.hidden = previousRhyme == nil
        nextButton.hidden = nextRhyme == nil
        
        let quizPlayed = rhyme.quizHasBeenPlayed()
        quizButton.setImage(UIImage(named: (quizPlayed ? "button-check" : "button-question")), forState: .Normal)
        quizButton.enabled = false
        
        let favorite = rhyme.isFavorite()
        likeButton.setImage(UIImage(named: (favorite ? "button-unlike" : "button-heart")), forState: .Normal)
        
    }
    
    override func viewWillAppear(animate: Bool) {
        self.view.clipsToBounds = true
        
        decorateForRhyme(rhyme)
        
        //mask the rhyme page
        let height = UIScreen.mainScreen().bounds.height
        let maskHeight = height - 20.0 - (iPad() ? 60.0 : 0.0)
        let maskWidth = (rhymePage.frame.width / rhymePage.frame.height) * maskHeight
        let maskRect = CGRectMake(10.0, 10.0, maskWidth, maskHeight)
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(roundedRect: maskRect, cornerRadius: maskHeight / 20.0).CGPath
        rhymePage.layer.mask = maskLayer
        
        //remove the buttonGradientView if this is a 4S
        let size = UIScreen.mainScreen().bounds.size
        if size.width <= 480.0 {
            //is 4S
            buttonGradientWidth.constant = 0
            self.view.layoutIfNeeded()
        }
        
        //set up buttons
        likeBottom.constant = 10
        repeatHeight.constant = 0
        repeatButton.imageView!.contentMode = UIViewContentMode.ScaleAspectFit
        self.view.layoutIfNeeded()
        
        updateScrollView()
        
    }
    
    func updateScrollView() {
        //check if the content height needs to be updated
        let width = scrollView.frame.width
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 9.5
        let attributes = [NSParagraphStyleAttributeName : paragraphStyle, NSFontAttributeName : rhymeText.font]
        let idealSize = (rhymeString as NSString).boundingRectWithSize(CGSizeMake(width, 1000), options: .UsesLineFragmentOrigin | .UsesFontLeading, attributes: attributes, context: nil)
        
        let difference = abs(idealSize.height - scrollView.frame.height)
        if difference > 6.0 && idealSize.height > scrollView.frame.height {
            scrollContentHeight.constant = difference * 1.2
            self.view.layoutIfNeeded()
        } else {
            scrollContentHeight.constant = 0.0
        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
        delay(0.05) {
            if !self.willPlayAnimalVideo() {
                self.rhymeTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "playRhyme", userInfo: nil, repeats: false)
            }
        }
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        delay(0.06) {
            rhymeTimer?.invalidate()
        }
        UAHaltPlayback()
    }
    
    //MARK: - Handling Playback of the Rhyme
    
    var rhymeTimers: [NSTimer]?
    
    func playRhyme() {
        quizBounceTimer?.invalidate()
        
        //disable quiz button if it hasn't been played yet
        quizButton.enabled = false
        
        let number = rhyme.number.threeCharacterString()
        let audioName = "rhyme_\(number)"
        let success = UAPlayer().play(audioName, ofType: "mp3", ifConcurrent: .Ignore)
        
        if success {
            let wordTimes = rhyme.wordStartTimes
            
            rhymeTimers = []
            
            for word in 0 ..< wordTimes.count {
                let msec = wordTimes[word]
                let timeInterval = Double(msec) / 1000.0
                let timer = NSTimer.scheduledTimerWithTimeInterval(timeInterval, target: self, selector: "updateWord:", userInfo: word, repeats: false)
                rhymeTimers?.append(timer)
            }
        }
    }
    
    func updateWord(timer: NSTimer) {
        if let word = timer.userInfo as? Int {
            updateAttributedTextForCurrentWord(word)
        }
    }
    
    func updateAttributedTextForCurrentWord(currentWord: Int) {
        
        var text = rhymeString
        let replacedLineBreaks = text.stringByReplacingOccurrencesOfString("\n", withString: "~\n", options: nil, range: nil)
        let noSpaces = replacedLineBreaks.stringByReplacingOccurrencesOfString(" ", withString: "\n", options: nil, range: nil)
        let words = noSpaces.componentsSeparatedByString("\n")
        var before: String = ""
        var current: String = ""
        var after: String = ""
        
        for i in 0 ..< words.count {
            let word = words[i]
            if i < currentWord { before = before.stringByAppendingString(word) + " " }
            else if i == currentWord { current = "\(word) " }
            else { after = after.stringByAppendingString(word) + " "}
        }
        
        //add line breaks back in
        before = before.stringByReplacingOccurrencesOfString("~ ", withString: "\n", options: nil, range: nil)
        current = current.stringByReplacingOccurrencesOfString("~ ", withString: "\n", options: nil, range: nil)
        after = after.stringByReplacingOccurrencesOfString("~ ", withString: "\n", options: nil, range: nil)
        
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
        var finalString = NSMutableAttributedString(string: "")
        
        for i in 0...2 {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.paragraphSpacing = 9.5
            
            let color = colors[i]
            let part = rawParts[i]
            let attributes = [
                NSForegroundColorAttributeName : color,
                NSParagraphStyleAttributeName : paragraphStyle
            ]
            let attributed = NSAttributedString(string: part, attributes: attributes)
            finalString.appendAttributedString(attributed)
        }
        
        rhymeText.attributedText = finalString
        
        scrollCurrentLineToVisible(currentWord)
    }
    
    func scrollCurrentLineToVisible(currentWord: Int) {
        
        if scrollContent.frame.height > scrollView.frame.height {
            
            let availableHeight = scrollView.frame.height
            let text = rhymeString
            let lines = getLinesArrayOfStringInLabel(text, rhymeText)
            
            //get line with current
            var lineWithCurrent = -1
            var currentLinePosition: CGFloat = 0
            var numberOfWords = 0
            
            for l in 0 ..< lines.count {
                if lineWithCurrent != -1 { continue }
                
                let line = lines[l]
                let words = line.componentsSeparatedByString(" ")
                for word in words {
                    if numberOfWords == currentWord {
                        lineWithCurrent = l
                    }
                    numberOfWords += 1
                }
                
                if lineWithCurrent != -1 { continue }
                
                var lineHeight = rhymeText.font.lineHeight
                if (line as NSString).containsString("\n") {
                    //is a paragraph break
                    lineHeight += 9.5
                }
                currentLinePosition += lineHeight
            }
            
            if lineWithCurrent == -1 { //no word is highlighed, only happens at the end
                currentLinePosition = CGFloat.max //mimic all the way at the bottom
            }
            
            //do nothing if currentLinePosition is less than half-way down the block
            if currentLinePosition < availableHeight / 2 {
                currentLinePosition = 0
            }
            
            //bottom line must always be at the bottom of the frame
            if currentLinePosition + (availableHeight) > scrollContent.frame.height {
                currentLinePosition = scrollContent.frame.height - (availableHeight)
            }
            
            scrollView.setContentOffset(CGPointMake(0, currentLinePosition), animated: true)
            
            
        }
    }
    
    
    func rhymeFinishedPlaying() {
        
        //animate buttons
        likeBottom.constant = 70
        repeatHeight.constant = 50
        quizButton.enabled = true
        UIView.animateWithDuration(0.7, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.AllowUserInteraction, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
        
        quizBounceTimer?.invalidate()
        if !rhyme.quizHasBeenPlayed() {
            self.quizBounceTimer = NSTimer.scheduledTimerWithTimeInterval(3.5, target: self, selector: "bounceQuizIcon", userInfo: nil, repeats: true)
            delay(0.25) {
                self.quizButtonPressed(self)
            }
        }
    }
    
    func bounceQuizIcon() {
        if !quizButton.enabled {
            quizBounceTimer?.invalidate()
            return
        }
        
        UIView.animateWithDuration(0.3, animations: {
            self.quizButton.transform = CGAffineTransformMakeTranslation(0.0, -50.0)
            }, completion: { success in
                UIView.animateWithDuration(0.7, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.0, options: nil, animations: {
                    self.quizButton.transform = CGAffineTransformMakeTranslation(0.0, 0.0)
                    }, completion: nil)
        })
    }
    
    //MARK: - Interface Buttons
    
    @IBAction func repeatButtonPressed(sender: AnyObject) {
        playRhyme()
        likeBottom.constant = 10
        repeatHeight.constant = 0
        UIView.animateWithDuration(0.4, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    @IBAction func likeButtonPressed(sender: UIButton) {
        let favorite = !rhyme.isFavorite()
        rhyme.setFavoriteStatus(favorite)
        
        self.likeButton.setImage(UIImage(named: (favorite ? "button-unlike" : "button-heart")), forState: .Normal)
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
    
    @IBAction func listButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
        endPlayback()
    }
    
    @IBAction func quizButtonPressed(sender: AnyObject) {
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("quiz") as! QuizViewController
        controller.quiz = rhyme
        quizBounceTimer?.invalidate()
        self.presentViewController(controller, animated: true, completion: nil)
    }
    
    
    //MARK: - Transitioning between rhymes
    
    @IBAction func nextRhyme(sender: UIButton) {
        if let next = nextRhyme {
            animateChangeToRhyme(next, transition: "pageCurl")
        }
    }
    
    @IBAction func previousRhyme(sender: UIButton) {
        if let previous = previousRhyme {
            animateChangeToRhyme(previous, transition: "pageCurl")
        }
    }
    
    func animateChangeToRhyme(rhyme: Rhyme, transition: String) {
        
        nextButton.enabled = false
        quizButton.enabled = false
        previousButton.enabled = false
        
        likeBottom.constant = 10
        repeatHeight.constant = 0
        UIView.animateWithDuration(0.4, animations: {
            self.view.layoutIfNeeded()
        })
        
        self.rhyme = rhyme
        decorateForRhyme(rhyme, updateBackground: false)
        updateScrollView()
        endPlayback()
        playTransitionForView(self.view, duration: 0.5, transition: transition)
        delay(0.5) {
            self.blurredPage.image = self.rhymePage.image
            playTransitionForView(self.blurredPage, duration: 1.0, transition: kCATransitionFade)
            delay(0.6) {
                self.playRhyme()
                self.nextButton.enabled = true
                self.previousButton.enabled = true
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
    
    func playAnimalVideo(name: String) {
        playVideo(name: name, currentController: self, completion: {
            //present the current zoo level building
            let currentZooLevel = RZQuizDatabase.currentZooLevel()
            let building = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("building") as! BuildingViewController
            building.mustBuy = true
            building.decorate(building: currentZooLevel, displaySize: self.view.frame.size)
            self.presentViewController(building, animated: true, completion: nil)
        })
    }
    
}

///stackoverflow.com/questions/4421267/how-to-get-text-from-nth-line-of-uilabel
func getLinesArrayOfStringInLabel(text: NSString, label:UILabel) -> [String] {
    
    let font:UIFont = label.font
    let rect:CGRect = label.frame
    
    let myFont:CTFontRef = CTFontCreateWithName(font.fontName, font.pointSize, nil)
    var attStr:NSMutableAttributedString = NSMutableAttributedString(string: text as String)
    attStr.addAttribute(String(kCTFontAttributeName), value:myFont, range: NSMakeRange(0, attStr.length))
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.paragraphSpacing = 9.5
    attStr.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, attStr.length))
    
    let frameSetter:CTFramesetterRef = CTFramesetterCreateWithAttributedString(attStr as CFAttributedStringRef)
    
    var path:CGMutablePathRef = CGPathCreateMutable()
    CGPathAddRect(path, nil, CGRectMake(0, 0, rect.size.width, 100000))
    let frame:CTFrameRef = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), path, nil)
    let lines = CTFrameGetLines(frame) as! [CTLineRef]
    var linesArray = [String]()
    
    for line in lines {
        let lineRange = CTLineGetStringRange(line)
        let range:NSRange = NSMakeRange(lineRange.location, lineRange.length)
        let lineString = text.substringWithRange(range)
        linesArray.append(lineString as String)
    }
    
    return linesArray
}