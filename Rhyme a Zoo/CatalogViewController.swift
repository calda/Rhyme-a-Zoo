//
//  RhymesViewController.swift
//  Rhyme a Zoo
//
//  Created by Cal on 7/1/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import Foundation
import UIKit

let RZAsyncQueue = dispatch_queue_create("com.hearatale.raz.aync", DISPATCH_QUEUE_SERIAL)

class CatalogViewController : UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewTop: NSLayoutConstraint!
    @IBOutlet weak var collectionViewBottom: NSLayoutConstraint!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var buttonGradientView: UIView!
    var canHideButtonGradient = true
    var animatingFromHome = false
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("rhyme", forIndexPath: indexPath) as! RhymeCell
        dispatch_async(RZAsyncQueue, {
            let rhyme = RZQuizDatabase.getQuiz(indexPath.item)
            cell.decorate(rhyme)
        })
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return RZQuizDatabase.count
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return getSize()
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let index = indexPath.item
        let rhyme = RZQuizDatabase.getRhyme(index)
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("rhyme") as! RhymeViewController
        controller.decorate(rhyme)
        self.presentViewController(controller, animated: true, completion: nil)
    }
    
    func getSize() -> CGSize {
        //TODO: different number of rows for different screen sizes
        let height = (collectionView.frame.height - 20.0) / 3.0
        let width = collectionView.frame.width / 2.2
        return CGSizeMake(width, height)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if !canHideButtonGradient { return }
        UIView.animateWithDuration(0.5, animations: {
            self.buttonGradientView.alpha = 0.0
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        if animatingFromHome {
            //set background gradient
            let gradient = CAGradientLayer()
            gradient.frame = UIScreen.mainScreen().bounds
            gradient.colors = [
                UIColor(red: 35.0 / 255.0, green: 77.0 / 255.0, blue: 164.0 / 255.0, alpha: 1.0).CGColor,
                UIColor(red: 63.0 / 255.0, green: 175.0 / 255.0, blue: 245.0 / 255.0, alpha: 1.0).CGColor
            ]
            self.view.layer.insertSublayer(gradient, atIndex: 0)
            self.view.backgroundColor = UIColor.clearColor()
            
            //add button gradient
            let buttonGradient = CAGradientLayer()
            buttonGradient.colors = gradient.colors
            buttonGradient.frame = UIScreen.mainScreen().bounds
            buttonGradientView.layer.insertSublayer(buttonGradient, atIndex: 0)
            buttonGradientView.layer.masksToBounds = true
            self.buttonGradientView.alpha = 1.0
            
            //set collection view position to current unplayed level
            let unplayedIndex = 6
            let col = CGFloat(unplayedIndex / 3)
            let width = UIScreen.mainScreen().bounds.width / 2.2
            let x = (width * (col)) + (5.0 * (col + 1))
            canHideButtonGradient = false
            delay(0.1) {
                self.collectionView.contentOffset = CGPointMake(x, 0)
                self.canHideButtonGradient = true
            }
            animatingFromHome = false
        }
    }
    
    @IBAction func homePressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}

class RhymeCell : UICollectionViewCell {
    
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var coinView: UIView!
    @IBOutlet weak var coin1: UIImageView!
    @IBOutlet weak var coin2: UIImageView!
    @IBOutlet weak var coin3: UIImageView!
    @IBOutlet weak var coin4: UIImageView!
    @IBOutlet weak var coin5: UIImageView!
    var coins: [UIImageView] = []
    
    func decorate(rhyme: Rhyme) {
        let quizNumber = rhyme.number.threeCharacterString()
        let image = UIImage(named: "thumbnail_\(quizNumber).jpg")
        let name = rhyme.name.uppercaseString
        
        coins = [coin1, coin2, coin3, coin4, coin5]
        
        dispatch_sync(dispatch_get_main_queue(), {
            self.title.text = name
            self.thumbnail.image = image
        })
        
    }
    
}