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
        
        if availableBalance == 0 {
            noCoins.hidden = false
            availableCoinsArea.hidden = true
        } else {
            noCoins.hidden = true
            availableCoinsArea.hidden = false
        }
        
        //adjust center mark of coin view
        let height = availableCoinsView.frame.height
        let offset = height / -19.7
        coinAreaOffset.constant = offset
        self.view.layoutIfNeeded()
    }
    
    func decorateCoins(#gold: Int, silver: Int) {
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
            current++
        }
        
        var current = 0
        for _ in 0 ..< coin20 {
            setImage(&current, "coin-20")
        }
        for _ in 0 ..< coin5 {
            setImage(&current, "coin-5")
        }
        for _ in 0 ..< coinGold {
            setImage(&current, "coin-gold-big")
        }
        for _ in 0 ..< coinSilver {
            setImage(&current, "coin-silver-big")
        }

    }
    
    func spawnCoins() {
        let (totalGold, totalSilver) = RZQuizDatabase.getTotalMoneyEarned()
        
        for _ in 0 ..< min(300, totalGold) {
            var wait = Double(arc4random_uniform(400)) / 100.0
            if coinView.subviews.count < 5 {
                wait = 0.0
            }
            
            delay(wait) {
                self.spawnCoinOfType(.Gold)
            }
        }
        for _ in 0 ..< min(300, totalSilver) {
            var wait = Double(arc4random_uniform(100)) / 50.0
            if coinView.subviews.count < 5 {
                wait = 0.0
            }
            
            delay(wait) {
                self.spawnCoinOfType(.Silver)
            }
        }
    }
    
    override func viewDidLoad() {
        initialCoinString = coinCount.attributedText!
    }
    
    func updateReadout() {
        let (totalGold, totalSilver) = RZQuizDatabase.getTotalMoneyEarned()
        
        let text = initialCoinString.mutableCopy() as! NSMutableAttributedString
        let current = text.string
        var splits = split(current){ $0 == " " }.map { String($0) }
        
        let balance = RZQuizDatabase.getPlayerBalance()
        if totalSilver == 0 {
            text.replaceCharactersInRange(NSMakeRange(count(splits[0]), count(splits[2]) + 3), withString: "")
        } else {
            text.replaceCharactersInRange(NSMakeRange(count(splits[0]) + 3, count(splits[2])), withString: "\(totalSilver)")
        }
        text.replaceCharactersInRange(NSMakeRange(0, count(splits[0])), withString: "\(totalGold)")
        coinCount.attributedText = text
    }
    
    func spawnCoinOfType(type: CoinType) {
        if coinView.subviews.count > 500 {
            return
        }
        let startX = CGFloat(arc4random_uniform(UInt32(self.view.frame.width)))
        
        let coin = UIImageView(frame: CGRectMake(startX - 15.0, -30.0, 30.0, 30.0))
        if iPad() {
            coin.frame = CGRectMake(startX - 25.0, -50.0, 50.0, 50.0)
        }
        coin.image = type.getImage()
        self.coinView.addSubview(coin)
        
        let endPosition = CGPointMake(startX - 25.0, self.view.frame.height + 50)
        let duration = 2.0 + (Double(Int(arc4random_uniform(1000))) / 250.0)
        UIView.animateWithDuration(duration, animations: {
            coin.frame.origin = endPosition
        }, completion: { success in
            coin.removeFromSuperview()
        })
    }
    
    @IBAction func back(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
        self.addingNewCoins = false
    }
    
    @IBAction func totalButton(sender: UIButton) {
        spawnCoins()
        sender.enabled = false
        delay(5.0) {
            sender.enabled = true
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        for subview in coinView.subviews {
            subview.removeFromSuperview()
        }
    }
}
