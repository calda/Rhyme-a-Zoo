//
//  RhymesViewController.swift
//  Rhyme a Zoo
//
//  Created by Cal on 7/1/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import Foundation
import UIKit

let RZAsyncQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

class CatalogViewController : UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewTop: NSLayoutConstraint!
    @IBOutlet weak var collectionViewBottom: NSLayoutConstraint!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var buttonGradientView: UIView!
    @IBOutlet weak var buttonGradientLeading: NSLayoutConstraint!
    @IBOutlet weak var favoritesButton: UIButton!
    var canHideButtonGradient = true
    var animatingFromHome = false
    
    var showFavorites = false
    var offsetBeforeSwitch = CGPointZero
    var gradientVisibleBeforeSwitch = true
    
    //widths for different device classes
    let fourRow: CGFloat = 736.0
    let twoRow: CGFloat = 480.0
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("rhyme", forIndexPath: indexPath) as! RhymeCell
        cell.decorate(indexPath.item, showFavorites: showFavorites)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if showFavorites {
            return RZQuizDatabase.numberOfFavories()
        }
        return RZQuizDatabase.count
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return getSize()
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let rhyme: Rhyme
        if showFavorites {
            let favIndex = indexPath.item
            let favs = data.arrayForKey(RZFavoritesKey) as! [Int]
            let rhymeNumber = favs[favIndex]
            rhyme = Rhyme(rhymeNumber)
        } else {
            let rhymeIndex = indexPath.item
            rhyme = RZQuizDatabase.getRhyme(rhymeIndex)
        }
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("rhyme") as! RhymeViewController
        controller.decorate(rhyme)
        self.presentViewController(controller, animated: true, completion: nil)
    }
    
    func getSize() -> CGSize {
        let screenWidth = self.view.frame.width
        let heightDivisor: CGFloat
        let widthDivisor: CGFloat
        
        if screenWidth == fourRow {
            heightDivisor = 4.0
            widthDivisor = 3.15
        } else if screenWidth <= twoRow {
            heightDivisor = 2.0
            widthDivisor = 1.4
        } else {
            heightDivisor = 3.0
            widthDivisor = 2.2
        }
        
        
        let height = (collectionView.frame.height - (5.0 * (heightDivisor + 1))) / heightDivisor
        let width = collectionView.frame.width / widthDivisor
        return CGSizeMake(width, height)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if !canHideButtonGradient { return }
        if self.buttonGradientLeading.constant != -70.0 {
            self.buttonGradientLeading.constant = -70.0
            UIView.animateWithDuration(0.5, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        collectionView.reloadData()
            
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
            buttonGradientView.alpha = 1.0
            
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
        
        if RZQuizDatabase.numberOfFavories() == 0 {
            favoritesButton.hidden = true
        } else {
            favoritesButton.hidden = false
        }
    }
    
    @IBAction func homePressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func toggleFavorites(sender: UIButton) {
        self.showFavorites = !showFavorites
        favoritesButton.setImage(UIImage(named: showFavorites ? "button-back" : "button-heart"), forState: .Normal)
        if showFavorites {
            offsetBeforeSwitch = collectionView.contentOffset
            gradientVisibleBeforeSwitch = buttonGradientLeading.constant > -70.0
        }
        collectionView.reloadData()
        
        self.canHideButtonGradient = false
        collectionView.contentOffset = (showFavorites ? CGPointZero : offsetBeforeSwitch)
        self.canHideButtonGradient = true
        
        if !showFavorites && gradientVisibleBeforeSwitch {
            buttonGradientLeading.constant = 0.0
            UIView.animateWithDuration(0.5, animations: {
                self.view.layoutIfNeeded()
            })
        } else if showFavorites {
            delay(1.0) {
                self.buttonGradientLeading.constant = -70.0
                self.view.layoutIfNeeded()
            }
        }
        playTransitionForView(collectionView, duration: 1.0, transition: "rippleEffect")
    }
}

class RhymeCell : UICollectionViewCell {
    
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var favoriteIcon: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var coinView: UIView!
    @IBOutlet weak var coin1: UIImageView!
    @IBOutlet weak var coin2: UIImageView!
    @IBOutlet weak var coin3: UIImageView!
    @IBOutlet weak var coin4: UIImageView!
    @IBOutlet weak var coin5: UIImageView!
    var coins: [UIImageView] = []
    
    func decorate(index: Int, showFavorites: Bool) {
        self.coins = [coin1, coin2, coin3, coin4, coin5]
        
        dispatch_async(RZAsyncQueue, {
            let rhyme: Rhyme
            
            if showFavorites {
                let favs = data.arrayForKey(RZFavoritesKey) as! [Int]
                let number = favs[index]
                rhyme = Rhyme(number)
            } else {
                rhyme = RZQuizDatabase.getQuiz(index)
            }
            
            let quizNumber = rhyme.number.threeCharacterString()
            let image = UIImage(named: "thumbnail_\(quizNumber).jpg")
            let name = rhyme.name.uppercaseString
            let isFavorite = rhyme.isFavorite()
            
            dispatch_async(dispatch_get_main_queue(), {
                self.favoriteIcon.hidden = !isFavorite
                self.title.text = name
                self.thumbnail.image = image
            })
        })
    }
    
}