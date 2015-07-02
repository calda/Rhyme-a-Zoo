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
    @IBOutlet weak var repeatButton: UIButton!
    @IBOutlet weak var repeatHeight: NSLayoutConstraint!
    @IBOutlet weak var rhymeText: UILabel!
    var rhymeString: String!
    
    var rhyme: Rhyme!
    
    func decorate(rhyme: Rhyme) {
        self.rhyme = rhyme
    }
    
    override func viewWillAppear(animate: Bool) {
        self.view.clipsToBounds = true
        
        //decorate cell for rhyme
        let number = rhyme.number.threeCharacterString()
        let illustration = UIImage(named: "illustration_\(number).jpg")
        rhymePage.image = illustration
        blurredPage.image = illustration
        
        let rawText = rhyme.rhymeText
        //add new lines
        var text = rawText.stringByReplacingOccurrencesOfString(";/", withString: "\n", options: nil, range: nil)
        text = text.stringByReplacingOccurrencesOfString("\'", withString: "'", options: nil, range: nil)
        text = rawText.stringByReplacingOccurrencesOfString("/", withString: "\n", options: nil, range: nil)
        rhymeString = text
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 9.5
        let attributed = NSAttributedString(string: rhymeString, attributes: [NSParagraphStyleAttributeName : paragraphStyle])
        rhymeText.attributedText = attributed
        
        //mask the rhyme page
        let height = UIScreen.mainScreen().bounds.height
        let maskHeight = height - 20.0
        let maskWidth = (rhymePage.frame.width / rhymePage.frame.height) * maskHeight
        let maskRect = CGRectMake(10.0, 10.0, maskWidth, maskHeight)
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(roundedRect: maskRect, cornerRadius: maskHeight / 20.0).CGPath
        rhymePage.layer.mask = maskLayer
        
        //add button gradient
        let buttonGradient = CAGradientLayer()
        buttonGradient.colors = [
            UIColor(red: 35.0 / 255.0, green: 77.0 / 255.0, blue: 164.0 / 255.0, alpha: 1.0).CGColor,
            UIColor(red: 63.0 / 255.0, green: 175.0 / 255.0, blue: 245.0 / 255.0, alpha: 1.0).CGColor
        ]
        buttonGradient.frame = UIScreen.mainScreen().bounds
        buttonGradientView.layer.insertSublayer(buttonGradient, atIndex: 0)
        buttonGradientView.layer.masksToBounds = true
        
        //remove the buttonGradientView if this is a 4S
        let size = UIScreen.mainScreen().bounds.size
        let aspect = size.height / size.width
        if aspect > 0.6 || aspect < 0.5 {
            //is 4S
            buttonGradientWidth.constant = 0
            self.view.layoutIfNeeded()
        }
        
        //set up buttons
        likeBottom.constant = 10
        repeatHeight.constant = 0
        repeatButton.imageView!.contentMode = UIViewContentMode.ScaleAspectFit
        self.view.layoutIfNeeded()
    }
    
    override func viewDidAppear(animated: Bool) {
        playRhyme()
    }
    
    var rhymeTimers: [NSTimer]?
    
    func playRhyme() {
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
    
    func cropRhymeToFit(currentWord: Int) -> (newString: String, wordsRemovedBeforeCurrent: Int) {
        let text = rhymeString
        let lines = getLinesArrayOfStringInLabel(text, rhymeText)
        let lineHeight = rhymeText.font.lineHeight + 9.5
        let maxLines = Int(rhymeText.frame.height / lineHeight)
        
        //TODO: calculate actual line height now that they are variable :(
        //probably gonna have to change it to a scroll view
        //for the best tbh
        
        if lines.count > maxLines {
            
            //get line with current
            var lineWithCurrent = -1
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
            }
            
            println(lineWithCurrent)
            
            if lineWithCurrent == -1 {
                lineWithCurrent = lines.count
            }
            
            //decide how many lines to remove
            let center = Int(maxLines / 2)
            if lineWithCurrent < center {
                return (text, 0) //do nothing because current line to at top
            }
            
            var linesToRemove = lineWithCurrent - center
            
            if lineWithCurrent + center + 1 >= lines.count {
                //the bottom line should always be at the bottom if visible
                linesToRemove = lines.count - (maxLines + 1)
            }
            
            //remove the number of lines
            var newText = ""
            var removedWordCount = 0
            
            for l in 0 ..< lines.count {
                let line = lines[l]
                
                if l > linesToRemove { //keep line
                    newText = newText + line
                } else {
                    let wordCount = line.componentsSeparatedByString(" ").count
                    removedWordCount += wordCount
                }
            }
            
            return (newText, removedWordCount)
            
            
        }
        return (text, 0)
    }
    
    func updateAttributedTextForCurrentWord(originalCurrentWord: Int) {

        let (text, wordsRemoved) = cropRhymeToFit(originalCurrentWord)
        let currentWord = originalCurrentWord - wordsRemoved
        
        let replacedLineBreaks = text.stringByReplacingOccurrencesOfString("\n", withString: "~\n", options: nil, range: nil)
        let noSpaces = replacedLineBreaks.stringByReplacingOccurrencesOfString(" ", withString: "\n", options: nil, range: nil)
        let words = noSpaces.componentsSeparatedByString("\n")
        var before: String = ""
        var current: String = ""
        var currentPunctuation = ""
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
        
        //ignore current if it is empty
        if current != "" {
            //detach punctuation from current and attach it to after
            //detach \n first
            if current.hasSuffix("\n") {
                after = "\n" + after
                current = current.stringByReplacingOccurrencesOfString("\n", withString: "", options: nil, range: nil)
            }
            
            //current will always end with a space though
            let index = current.endIndex.predecessor()
            let lastCharacter = current.substringFromIndex(index)
            let punctuation = [".", ",", ":", ";", "/", "\\", "\""]
            
            if contains(punctuation, lastCharacter) {
                current = current.substringToIndex(index)
                currentPunctuation = lastCharacter
            }
        } else {
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
        let colors = [beforeColor, currentColor, beforeColor, afterColor]
        let rawParts = [before, current, currentPunctuation, after]
        var finalString = NSMutableAttributedString(string: "")
        
        for i in 0...3 {
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
    }
    
    func rhymeFinishedPlaying() {
        UAHaltPlayback()
        
        //animate buttons
        likeBottom.constant = 70
        repeatHeight.constant = 50
        UIView.animateWithDuration(0.4, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    @IBAction func repeatButtonPressed(sender: AnyObject) {
        playRhyme()
        likeBottom.constant = 10
        repeatHeight.constant = 0
        UIView.animateWithDuration(0.4, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    @IBAction func likeButtonPressed(sender: UIButton) {

        UIView.animateWithDuration(0.25, delay: 0.0, options: nil, animations: {
                sender.transform = CGAffineTransformMakeScale(1.3, 1.3)
            }, completion: { success in
                UIView.animateWithDuration(0.25) {
                    sender.transform = CGAffineTransformMakeScale(1.0, 1.0)
                }
        })
    }
    
    @IBAction func listButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
        UAHaltPlayback()
        
        //cancel rhyme timers
        if let timers = rhymeTimers {
            for timer in timers {
                timer.invalidate()
            }
        }
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