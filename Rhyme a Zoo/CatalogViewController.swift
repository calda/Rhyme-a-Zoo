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
var RZShowingFavorites = false

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
    
    var offsetBeforeSwitch = CGPointZero
    var gradientVisibleBeforeSwitch = true
    
    //widths for different device classes
    let fourRow: CGFloat = 736.0
    let twoRow: CGFloat = 480.0
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if indexPath.item == hearATaleCellIndex {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Hear a Tale", forIndexPath: indexPath) as! DecorationCell
            cell.decorate()
            return cell;
        }
        
        if indexPath.item == celebrationCellIndex {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Celebration", forIndexPath: indexPath) as! DecorationCell
            cell.decorate()
            return cell;
        }
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("rhyme", forIndexPath: indexPath) as! RhymeCell
        cell.decorate(indexPath.item, showFavorites: RZShowingFavorites)
        return cell
    }
    
    var hearATaleCellIndex: Int? = nil
    var celebrationCellIndex: Int? = nil
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if RZShowingFavorites {
            return RZQuizDatabase.numberOfFavories() + 1
        }
        
        //update current level
        RZQuizDatabase.advanceLevelIfCurrentIsComplete()
        
        let availableRhymes = RZQuizDatabase.currentLevel() * 5
        var displayedCells = availableRhymes + 1 //Hear a Tale cell
        hearATaleCellIndex = displayedCells - 1
        
        let rhymeCount = RZQuizDatabase.levelCount * 5
        let completedRhymes = RZQuizDatabase.getQuizData().count
        if completedRhymes == rhymeCount {
            displayedCells += 1 //add Celebration cell
            hearATaleCellIndex = displayedCells - 1
            celebrationCellIndex = displayedCells - 2
        } else { celebrationCellIndex = nil }
        
        return displayedCells
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return getSize()
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if indexPath.item == hearATaleCellIndex { //is Hear a Tale cell
            //show alert
            let alert = UIAlertController(title: "Open Hear a Tale?", message: "You will leave the Rhyme a Zoo app.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
            alert.addAction(UIAlertAction(title: "Open", style: .Default, handler: { _ in
                if let url = NSURL(string: "http://hearatale.com") {
                    UIApplication.sharedApplication().openURL(url)
                }
            }))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        if indexPath.item == celebrationCellIndex { //is celebration cell
            //play celebration video
            playVideo(name: "game-over", currentController: self, completion: nil)
        }
        
        let rhyme: Rhyme
        if RZShowingFavorites {
            let favIndex = indexPath.item
            let favs = data.arrayForKey(userKey(RZFavoritesKey)) as! [Int]
            let rhymeNumber = favs[favIndex]
            rhyme = Rhyme(rhymeNumber)
        } else {
            let rhymeIndex = indexPath.item
            rhyme = RZQuizDatabase.getRhyme(rhymeIndex)
        }
        
        /*let quiz = Quiz(rhyme.number)
        quiz.saveQuizResult(gold: 5, silver: 0)
        if RZQuizDatabase.advanceLevelIfCurrentIsComplete() {
            println("ADVANCED LEVEL")
        }
        collectionView.reloadData()*/

        
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("rhyme") as! RhymeViewController
        controller.decorate(rhyme)
        self.presentViewController(controller, animated: true, completion: nil)
    }
    
    func getSize() -> CGSize {
        let (heightDivisor, widthDivisor) = multipliersForCell()
        var height = (collectionView.frame.height - (5.0 * (heightDivisor + 1))) / heightDivisor
        let width = collectionView.frame.width / widthDivisor
        return CGSizeMake(width, height)
    }
    
    func multipliersForCell() -> (height: CGFloat, width: CGFloat) {
        let screenWidth = UIScreen.mainScreen().bounds.width
        
        if screenWidth == fourRow {
            return (4.0, 3.15)
        } else if screenWidth <= twoRow {
            return (2.0, 1.4)
        } else {
            return (3.0, 2.2)
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if !canHideButtonGradient { return }
        if self.buttonGradientLeading.constant != -70.0 {
            self.buttonGradientLeading.constant = -70.0
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        
        if RZShowingFavorites && RZQuizDatabase.numberOfFavories() == 0 {
            RZShowingFavorites = false
        }
        
        collectionView.reloadData()
            
        if animatingFromHome {
            //set collection view position to current unplayed level
            let minimumIndex = max(1, (RZQuizDatabase.currentLevel() - 1) * 5)
            var unplayedIndex = minimumIndex
            
            for i in (minimumIndex - 1) ..< RZQuizDatabase.currentLevel() * 5 {
                let quiz = RZQuizDatabase.getQuiz(i)
                if !quiz.quizHasBeenPlayed() {
                    unplayedIndex = i
                    break
                }
            }
            
            let divisors = multipliersForCell()
            let heightDivisor = Int(divisors.height)
            let widthDivisor = divisors.width
            
            var col = CGFloat(unplayedIndex / heightDivisor) - 1
            col = max(col, 0)
            let width = UIScreen.mainScreen().bounds.width / widthDivisor
            var x = (width * (col)) + (5.0 * (col + 1))
            
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
        RZShowingFavorites = false
    }
    
    @IBAction func toggleFavorites(sender: UIButton) {
        RZShowingFavorites = !RZShowingFavorites
        favoritesButton.setImage(UIImage(named: RZShowingFavorites ? "button-back" : "button-heart"), forState: .Normal)
        if RZShowingFavorites {
            offsetBeforeSwitch = collectionView.contentOffset
            gradientVisibleBeforeSwitch = buttonGradientLeading.constant > -70.0
        }
        collectionView.reloadData()
        
        self.canHideButtonGradient = false
        collectionView.contentOffset = (RZShowingFavorites ? CGPointZero : offsetBeforeSwitch)
        self.canHideButtonGradient = true
        
        if !RZShowingFavorites && gradientVisibleBeforeSwitch {
            buttonGradientLeading.constant = 0.0
            UIView.animateWithDuration(0.5, animations: {
                self.view.layoutIfNeeded()
            })
        } else if RZShowingFavorites {
            delay(1.0) {
                self.buttonGradientLeading.constant = -70.0
                self.view.layoutIfNeeded()
            }
        }
        playTransitionForView(collectionView, duration: 0.3, transition: "rotate")
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
    @IBOutlet weak var coinContainerAspect: NSLayoutConstraint!
    @IBOutlet weak var coinContainer: UIView!
    
    func decorate(index: Int, showFavorites: Bool) {
        self.coins = [coin1, coin2, coin3, coin4, coin5]
        self.alpha = 0.0
        
        dispatch_async(RZAsyncQueue, {
            let rhyme: Rhyme
            
            if showFavorites {
                let favs = data.arrayForKey(userKey(RZFavoritesKey)) as! [Int]
                if index >= favs.count { return }
                let number = favs[index]
                rhyme = Rhyme(number)
            } else {
                rhyme = RZQuizDatabase.getQuiz(index)
            }
            
            let quizNumber = rhyme.number.threeCharacterString()
            let image = UIImage(named: "thumbnail_\(quizNumber).jpg")
            let name = rhyme.name.uppercaseString
            let isFavorite = rhyme.isFavorite()
            let (gold, silver) = rhyme.getQuizResult()
            let hasBeenPlayed = rhyme.quizHasBeenPlayed()
            
            dispatch_async(dispatch_get_main_queue(), {
                self.favoriteIcon.hidden = !isFavorite
                self.title.text = name
                self.thumbnail.image = image
                
                //update coins
                var countToShow = gold + silver
                
                if gold + silver == 0 && hasBeenPlayed {
                    countToShow = 5
                }
                setCoinsInImageViews(self.coins, gold: gold, silver: silver, big: false)
                
                self.coinContainer.hidden = !hasBeenPlayed
                self.coinContainer.removeConstraint(self.coinContainerAspect)
                self.coinContainerAspect = NSLayoutConstraint(item: self.coinContainer, attribute: .Width, relatedBy: .Equal, toItem: self.coinContainer, attribute: .Height, multiplier: CGFloat(countToShow), constant: 0.0)
                self.coinContainer.addConstraint(self.coinContainerAspect)
                
                UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.AllowUserInteraction, animations: {
                    self.alpha = 1.0
                }, completion: nil)
                
                //self.layer.shouldRasterize = true
                //self.layer.rasterizationScale = UIScreen.mainScreen().scale
                
            })
        })
    }
    
}

class DecorationCell : UICollectionViewCell {
    
    func decorate() {
        self.alpha = 0.0
        UIView.animateWithDuration(0.2, delay: 0.05, options: UIViewAnimationOptions.AllowUserInteraction, animations: {
            self.alpha = 1.0
        }, completion: nil)
    }
    
}
