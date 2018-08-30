//
//  BankViewController.swift
//  WordWorld
//
//  Created by Cal
//  Copyright (c) 2015 Hear a Tale. All rights reserved.
//

import UIKit
import Foundation

let _SilverCoin = UIImage(named: "Silver-Coin")!
let _GoldCoin = UIImage(named: "Gold-Coin")!

enum CoinType {
    case Silver, Gold
    
    func getImage() -> UIImage {
        switch(self) {
            case .Silver: return _SilverCoin
            case .Gold: return _GoldCoin
        }
    }
}

class BankViewController : UIViewController {
    
    @IBOutlet weak var noCoins: UIButton!
    @IBOutlet weak var coinCount: UILabel!
    @IBOutlet weak var coinView: UIView!
    @IBOutlet weak var coinPile: UIImageView!
    @IBOutlet var coinImages: [UIImageView]!
    @IBOutlet weak var availableCoinsArea: UIView!
    @IBOutlet weak var availableCoinsView: UIView!
    @IBOutlet weak var coinAreaOffset: NSLayoutConstraint!
    @IBOutlet weak var coinAreaHeight: NSLayoutConstraint!
    @IBOutlet weak var backButton: UIButton!
    var addingNewCoins = true
    var initialCoinString: NSAttributedString!
    @IBOutlet weak var repeatAnimationButton: UIButton!
    
    var hasSpentCoins: Bool = false
    var coinTimers: [NSTimer] = []
    
    override func viewWillAppear(animated: Bool) {
        self.view.layoutIfNeeded()
        sortOutletCollectionByTag(&coinImages)
        
        updateReadout()
        coinView.layer.masksToBounds = true
        let availableBalance = RZQuizDatabase.getPlayerBalance()
        let availableGold = Int(availableBalance)
        let availableSilver = Int(availableBalance * 2) % 2
        
        updateReadout()
        decorateCoins(gold: availableGold, silver: availableSilver)
        self.coinCount.alpha = 0.0
        
        if availableBalance == 0 {
            noCoins.hidden = false
            availableCoinsArea.hidden = true
        } else {
            noCoins.hidden = true
            availableCoinsArea.hidden = false
        }
        
        if availableBalance > 60 {
            coinPile.hidden = false
            coinPile.alpha = 1.0
            availableCoinsArea.hidden = true
        }
        
        let (totalGold, totalSilver) = RZQuizDatabase.getTotalMoneyEarned()
        let totalBalance = Double(totalGold) + (Double(totalSilver) * 0.5)
        hasSpentCoins = totalBalance > availableBalance
        
        //adjust center mark of coin view
        let height = availableCoinsView.frame.height
        let offset = height / -19.7
        coinAreaOffset.constant = offset
        self.view.layoutIfNeeded()
    }
    
    override func viewDidAppear(animated: Bool) {
        playAnimation()
    }
    
    override func viewDidLoad() {
        initialCoinString = coinCount.attributedText!
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.endTimers()
        UAHaltPlayback()
    }
    
    func decorateCoins(gold gold: Int, silver: Int) {
        //clear coins
        for i in 0...9 {
            coinImages[i].image = nil
        }
        
        //calculate coins
        var coin20 = max(0, Int(gold / 20))
        let coin5 = max(0, (gold - (coin20 * 20)) / 5)
        let coinGold = max(0, gold - (coin20 * 20) - (coin5 * 5))
        let coinSilver = silver
        
        if coin20 > 7 {
            //too many to display
            availableCoinsView.hidden = true
            coinPile.hidden = false
        }
        else {
            availableCoinsView.hidden = false
            coinPile.hidden = true
        }
        
        //display coins
        func setImage(inout current: Int, type: String) {
            if current > 9 { return }
            coinImages[current].image = UIImage(named: type)
            current += 1
        }
        
        var current = 0
        for _ in 0 ..< coin20 {
            setImage(&current, type: "coin-20")
        }
        for _ in 0 ..< coin5 {
            setImage(&current, type: "coin-5")
        }
        for _ in 0 ..< coinGold {
            setImage(&current, type: "coin-gold-big")
        }
        for _ in 0 ..< coinSilver {
            setImage(&current, type: "coin-silver-big")
        }

    }
    
    func playAnimation() {
        self.repeatAnimationButton.enabled = false
        
        UAPlayer().play("coins-available", ofType: "mp3", ifConcurrent: .Interrupt)
        let duration = UALengthOfFile("coins-total", ofType: "mp3")
        
        //TODO: FIX
        //if !hasSpentCoins { return }
        
        let (totalGold, totalSilver) = RZQuizDatabase.getTotalMoneyEarned()
        let totalEarned = totalGold + totalSilver
        let animationLoops = (totalEarned / 100) + 1
        
        for i in 1...animationLoops {
            let loop: Double = Double(i) - 1
            //play raining coins animation
            coinTimers.append(NSTimer.scheduledTimerWithTimeInterval(duration + (loop * 4.5), target: self, selector: #selector(BankViewController.playAnimationPart(_:)), userInfo: 1, repeats: false))
            
            if i == 1 { //only play the audio on the first loop
                coinTimers.append(NSTimer.scheduledTimerWithTimeInterval(duration + 0.5 + (loop * 4.5), target: self, selector: #selector(BankViewController.playAnimationPart(_:)), userInfo: 2, repeats: false))
            }
            
            //only fade the background on the last loop
            if i == animationLoops {
                coinTimers.append(NSTimer.scheduledTimerWithTimeInterval(duration + 4.5 + (loop * 4.5), target: self, selector: #selector(BankViewController.playAnimationPart(_:)), userInfo: 3, repeats: false))
            }
        }
    }
    
    func playAnimationPart(timer: NSTimer) {
        if let part = timer.userInfo as? Int {
            
            if part == 1 {
                UIView.animateWithDuration(1.0) {
                    self.coinView.backgroundColor = UIColor(white: 0.0, alpha: 0.7)
                    self.availableCoinsArea.alpha = 0.3
                    self.coinCount.alpha = 1.0
                }
                self.spawnCoins()
                
            }
                
            else if part == 2 {
                UAPlayer().play("coins-total", ofType: "mp3", ifConcurrent: .Interrupt)
            }
            
            else if part == 3 {
                self.repeatAnimationButton.enabled = true
                UIView.animateWithDuration(0.5) {
                    self.coinView.backgroundColor = UIColor.clearColor()
                    self.availableCoinsArea.alpha = 1.0
                }
                UIView.animateWithDuration(1.0, delay: 2.5, options: [], animations: {
                    self.coinCount.alpha = 0.0
                }, completion: nil)
            }
        }
    }
    
    func spawnCoins() {
        var (totalGold, totalSilver) = RZQuizDatabase.getTotalMoneyEarned()
        totalGold = min(100, totalGold)
        totalSilver = min(100, totalSilver)
        
        dispatch_async(RZAsyncQueue) {
            for _ in 0 ..< min(300, totalGold) {
                let wait = NSTimeInterval(arc4random_uniform(100)) / 100.0
                
                sync() {
                    let timer = NSTimer.scheduledTimerWithTimeInterval(wait, target: self, selector: #selector(BankViewController.spawnCoinOfType(_:)), userInfo: CoinType.Gold.getImage(), repeats: false)
                    self.coinTimers.append(timer)
                }
                
            }
            for _ in 0 ..< min(300, totalSilver) {
                let wait = Double(arc4random_uniform(100)) / 50.0
                
                sync() {
                    let timer = NSTimer.scheduledTimerWithTimeInterval(wait, target: self, selector: "spawnCoinOfType:", userInfo: CoinType.Silver.getImage(), repeats: false)
                    self.coinTimers.append(timer)
                }
                
            }
        }
        
    }
    
    func spawnCoinOfType(timer: NSTimer) {
        if let image = timer.userInfo as? UIImage {
            if coinView.subviews.count > 500 {
                return
            }
            let startX = CGFloat(arc4random_uniform(UInt32(self.view.frame.width)))
            
            let coin = UIImageView(frame: CGRectMake(startX - 15.0, -30.0, 30.0, 30.0))
            if iPad() {
                coin.frame = CGRectMake(startX - 25.0, -50.0, 50.0, 50.0)
            }
            coin.image = image
            self.coinView.addSubview(coin)
            
            let endPosition = CGPointMake(startX - 25.0, self.view.frame.height + 50)
            let duration = 2.0 + (Double(Int(arc4random_uniform(1000))) / 250.0)
            UIView.animateWithDuration(duration, animations: {
                coin.frame.origin = endPosition
                }, completion: { success in
                    coin.removeFromSuperview()
            })
        }
        
    }
    
    func endTimers() {
        for timer in coinTimers {
            timer.invalidate()
        }
        coinTimers = []
    }
    
    func updateReadout() {
        let (totalGold, totalSilver) = RZQuizDatabase.getTotalMoneyEarned()
        
        let text = initialCoinString.mutableCopy() as! NSMutableAttributedString
        let current = text.string
        var splits = current.characters.split{ $0 == " " }.map { String($0) }.map { String($0) }
        
        let balance = RZQuizDatabase.getPlayerBalance()
        if totalSilver == 0 {
            text.replaceCharactersInRange(NSMakeRange(splits[0].characters.count, splits[2].characters.count + 3), withString: "")
        } else {
            text.replaceCharactersInRange(NSMakeRange(splits[0].characters.count + 3, splits[2].characters.count), withString: "\(totalSilver)")
        }
        text.replaceCharactersInRange(NSMakeRange(0, splits[0].characters.count), withString: "\(totalGold)")
        coinCount.attributedText = text
    }
    
    @IBAction func back(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
        self.addingNewCoins = false
    }
    
    @IBAction func repeatAnimation(sender: UIButton) {
        playAnimation()
    }
    
    override func viewDidDisappear(animated: Bool) {
        for subview in coinView.subviews {
            subview.removeFromSuperview()
        }
        UAHaltPlayback()
    }
}
