//
//  ZookeeperGame.swift
//  Rhyme a Zoo
//
//  Created by Cal on 7/25/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import UIKit

class ZookeeperGameController : UIViewController, UIGestureRecognizerDelegate {
    
    var zookeeperImage: UIImageView!
    @IBOutlet var quitZookeeperButton: UIButton!
    @IBOutlet var mainButtons: [UIButton]!
    var originalButtonAlpha: [UIButton : CGFloat] = [:]
    
    func toggleZookeeper() {
        if zookeeperImage == nil {
            //add zookeeper
            let number = RZQuizDatabase.getKeeperNumber()
            let gender = RZQuizDatabase.getKeeperGender()
            let imageName = "zookeeper-\(gender)\(number)"
            let image = UIImage(named: imageName)
            zookeeperImage = UIImageView(image: image)
            
            let height = self.view.frame.height * 0.5
            let width = height * (0.5746835443)
            let size = CGSizeMake(width, height)
            zookeeperImage.frame.size = size
            zookeeperImage.center = self.view.center
            self.view.addSubview(zookeeperImage)
            
            //animate
            zookeeperImage.alpha = 0.0
            zookeeperImage.transform = CGAffineTransformMakeScale(0.5, 0.5)
            UIView.animateWithDuration(0.6, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.0, options: nil, animations: {
                self.zookeeperImage.alpha = 1.0
                self.zookeeperImage.transform = CGAffineTransformMakeScale(1.0, 1.0)
            }, completion: nil)
            UIView.animateWithDuration(0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: nil, animations: {
                for button in self.mainButtons {
                    self.originalButtonAlpha[button] = button.alpha
                    button.alpha = 0.0
                }
                self.quitZookeeperButton.alpha = 1.0
            }, completion: nil)
        }
            
        else {
            UIView.animateWithDuration(0.4, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: nil, animations: {
                self.zookeeperImage.alpha = 0.0
                self.zookeeperImage.transform = CGAffineTransformMakeScale(self.currentKeeperScale * 0.5, self.currentKeeperScale * 0.5)
                
                for button in self.mainButtons {
                    button.alpha = self.originalButtonAlpha[button] ?? 1.0
                }
                self.quitZookeeperButton.alpha = 0.0
                }, completion: { success in
                    
                    //clean up zookeeper
                    self.zookeeperImage.removeFromSuperview()
                    self.zookeeperImage = nil
                    self.currentKeeperScale = 1.0
                    self.previousKeeperScale = 1.0
                    
            })
        }
    }
    
    //MARK: - User Interaction
    
    func zookeeperGameTap(event sender: UITapGestureRecognizer) {
        if let zookeeperImage = self.zookeeperImage {
            //in zookeeper mode
            UIView.animateWithDuration(0.2, animations: {
                self.zookeeperImage.center = sender.locationInView(self.zookeeperImage.superview)
            })
        }
    }
    
    func zookeeperGamePan(event sender: UIPanGestureRecognizer) {
        if let zookeeperImage = self.zookeeperImage {
            //in zookeeper mode
            UIView.animateWithDuration(0.2, animations: {
                self.zookeeperImage.center = sender.locationInView(self.zookeeperImage.superview)
            })
        }
    }
    
    var previousKeeperScale: CGFloat = 1.0
    var currentKeeperScale: CGFloat = 1.0
    func zookeeperGamePinch(event sender: UIPinchGestureRecognizer) {
        if let zookeeperImage = self.zookeeperImage {
            
            if sender.state == .Began {
                previousKeeperScale = currentKeeperScale
            }
            
            let scale = sender.scale
            currentKeeperScale = min(previousKeeperScale * scale, 3.0)
            zookeeperImage.transform = CGAffineTransformMakeScale(currentKeeperScale, currentKeeperScale)
        }
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}