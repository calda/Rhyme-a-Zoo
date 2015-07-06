//
//  BankViewController.swift
//  WordWorld
//
//  Created by Cal
//  Copyright (c) 2015 Hear a Tale. All rights reserved.
//

import UIKit
import Foundation

enum CoinType {
    case Silver, Gold
    
    func getImage() -> UIImage {
        switch(self) {
        case .Silver: return UIImage(named: "Silver-Coin")!
        case .Gold: return UIImage(named: "Gold-Coin")!
        }
    }
}

class BankViewController : UIViewController {
    
    @IBOutlet weak var noCoins: UIButton!
    @IBOutlet weak var coinCount: UILabel!
    @IBOutlet weak var coinView: UIView!
    @IBOutlet weak var backButton: UIButton!
    var addingNewCoins = true
    var initialCoinString: NSAttributedString!
    
    var goldUp: Int = 0
    var silverUp: Int = 0
    
    override func viewWillAppear(animated: Bool) {
        updateReadout()
        coinView.layer.masksToBounds = true
        let balance = RZQuizDatabase.getPlayerBalance()
        let gold = Int(balance)
        let silver = Int(balance * 2) % 2
        
        updateReadout()
        
        for _ in 0 ..< gold {
            var wait = Double(arc4random_uniform(100)) / 50.0
            if coinView.subviews.count < 5 {
                wait = 0.0
            }
            
            delay(wait) {
                self.spawnCoinOfType(.Gold)
                delay(0.1) {
                    self.goldUp++
                    self.updateReadout()
                }
            }
        }
        for _ in 0 ..< silver {
            var wait = Double(arc4random_uniform(100)) / 50.0
            if coinView.subviews.count < 5 {
                wait = 0.0
            }
            
            delay(wait) {
                self.spawnCoinOfType(.Silver)
                delay(0.1) {
                    self.silverUp++
                    self.updateReadout()
                }
            }
        }
        
        if gold == 0 && silver == 0 {
            noCoins.hidden = false
            coinCount.hidden = true
            backButton.titleLabel!.textColor = noCoins.titleLabel!.textColor
        } else {
            noCoins.hidden = true
            coinCount.hidden = false
        }
    }
    
    override func viewDidLoad() {
        initialCoinString = coinCount.attributedText!
    }
    
    func updateReadout() {
        let text = initialCoinString.mutableCopy() as! NSMutableAttributedString
        
        let current = text.string
        var splits = split(current){ $0 == " " }.map { String($0) }
        
        let balance = RZQuizDatabase.getPlayerBalance()
        let silver = Int(balance * 2) % 2
        if silver == 0 {
            text.replaceCharactersInRange(NSMakeRange(count(splits[0]), count(splits[2]) + 3), withString: "")
        } else {
            text.replaceCharactersInRange(NSMakeRange(count(splits[0]) + 3, count(splits[2])), withString: "\(silverUp)")
        }
        text.replaceCharactersInRange(NSMakeRange(0, count(splits[0])), withString: "\(goldUp)")
        coinCount.attributedText = text
    }
    
    func spawnCoinOfType(type: CoinType) {
        if coinView.subviews.count > 500 {
            return
        }
        let startX = CGFloat(arc4random_uniform(UInt32(self.view.frame.width)))
        
        let coin = UIImageView(frame: CGRectMake(startX - 25.0, -50.0, 50.0, 50.0))
        coin.image = type.getImage()
        self.coinView.addSubview(coin)
        
        let endPosition = CGPointMake(startX - 25.0, self.view.frame.height + 50)
        let duration = 2.0 + (Double(Int(arc4random_uniform(1000))) / 250.0)
        UIView.animateWithDuration(duration, animations: {
            coin.frame.origin = endPosition
            }, completion: { success in
                coin.removeFromSuperview()
                if self.addingNewCoins { self.spawnCoinOfType(type) }
        })
    }
    
    @IBAction func back(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
        self.addingNewCoins = false
    }
    
    override func viewDidDisappear(animated: Bool) {
        for subview in coinView.subviews {
            subview.removeFromSuperview()
        }
    }
}
