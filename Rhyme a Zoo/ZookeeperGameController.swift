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
            let size = CGSize(width: width, height: height)
            zookeeperImage.frame.size = size
            zookeeperImage.center = self.view.center
            self.view.addSubview(zookeeperImage)
            
            //animate
            zookeeperImage.alpha = 0.0
            zookeeperImage.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.0, options: [], animations: {
                self.zookeeperImage.alpha = 1.0
                self.zookeeperImage.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }, completion: nil)
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: [], animations: {
                for button in self.mainButtons {
                    self.originalButtonAlpha[button] = button.alpha
                    button.alpha = 0.0
                }
                self.quitZookeeperButton.alpha = 1.0
            }, completion: nil)
        }
            
        else {
            UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: [], animations: {
                self.zookeeperImage.alpha = 0.0
                self.zookeeperImage.transform = CGAffineTransform(scaleX: self.currentKeeperScale * 0.5, y: self.currentKeeperScale * 0.5)
                
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
        if zookeeperImage != nil {
            //in zookeeper mode
            UIView.animate(withDuration: 0.2, animations: {
                self.zookeeperImage.center = sender.location(in: self.zookeeperImage.superview)
            })
        }
    }
    
    func zookeeperGamePan(event sender: UIPanGestureRecognizer) {
        if zookeeperImage != nil {
            //in zookeeper mode
            UIView.animate(withDuration: 0.2, animations: {
                self.zookeeperImage.center = sender.location(in: self.zookeeperImage.superview)
            })
        }
    }
    
    var previousKeeperScale: CGFloat = 1.0
    var currentKeeperScale: CGFloat = 1.0
    func zookeeperGamePinch(event sender: UIPinchGestureRecognizer) {
        if let zookeeperImage = self.zookeeperImage {
            
            if sender.state == .began {
                previousKeeperScale = currentKeeperScale
            }
            
            let scale = sender.scale
            currentKeeperScale = min(previousKeeperScale * scale, 3.0)
            zookeeperImage.transform = CGAffineTransform(scaleX: currentKeeperScale, y: currentKeeperScale)
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}
