//
//  RhymesViewController.swift
//  Rhyme a Zoo
//
//  Created by Cal on 7/1/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import Foundation
import UIKit

let RZAsyncQueue = DispatchQueue(label: "RAZAsyncQueue", qos: .userInitiated)
var RZShowingFavorites = false

class CatalogViewController : UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var favoritesButton: UIButton!
    var animatingFromHome = false
    
    var offsetBeforeFavoritesToggled = CGPoint.zero
    
    //widths for different device classes
    let fourRow: CGFloat = 1000.0
    let twoRow: CGFloat = 480.0
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == hearATaleCellIndex {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Hear a Tale", for: indexPath) as! DecorationCell
            cell.decorate()
            return cell;
        }
        
        if indexPath.item == celebrationCellIndex {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Celebration", for: indexPath) as! DecorationCell
            cell.decorate()
            return cell;
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "rhyme", for: indexPath) as! RhymeCell
        cell.decorate(indexPath.item, showFavorites: RZShowingFavorites, cellSize: cellSize)
        return cell
    }
    
    var hearATaleCellIndex: Int? = nil
    var celebrationCellIndex: Int? = nil
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if RZShowingFavorites {
            hearATaleCellIndex = RZQuizDatabase.numberOfFavories()
            celebrationCellIndex = nil
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return cellSize
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if indexPath.item == hearATaleCellIndex { //is Hear a Tale cell
            return
            /* interaction with the Hear a Tale cell cannot exist without a parental gate
             
            //show alert
            let alert = UIAlertController(title: "Open Hear a Tale?", message: "You will leave the Rhyme a Zoo app.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
            alert.addAction(UIAlertAction(title: "Open", style: .Default, handler: { _ in
                if let url = NSURL(string: "http://hearatale.org") {
                    UIApplication.sharedApplication().openURL(url)
                }
            }))
            self.presentViewController(alert, animated: true, completion: nil)
            return
            */
        }
        
        if indexPath.item == celebrationCellIndex { //is celebration cell
            //play celebration video
            playVideo(name: "game-over", currentController: self, completion: nil)
        }
        
        let rhyme: Rhyme
        if RZShowingFavorites {
            let favIndex = indexPath.item
            let favs = RZQuizDatabase.getFavorites()
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

        
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "rhyme") as! RhymeViewController
        controller.decorate(rhyme)
        self.present(controller, animated: true, completion: nil)
    }
    
    var cellSize: CGSize {
        let height = (collectionView.frame.height - (5.0 * (cellsPerRow + 1))) / cellsPerRow
        let width = height * cellAspectRatio
        return CGSize(width: width, height: height)
    }
    
    var cellsPerRow: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        
        if screenWidth >= fourRow {
            return 4
        } else if screenWidth <= twoRow {
            return 2
        } else {
            return 3
        }
    }
    
    var cellAspectRatio: CGFloat {
        return 3
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if RZShowingFavorites && RZQuizDatabase.numberOfFavories() == 0 {
            RZShowingFavorites = false
        }
        
        collectionView.reloadData()
            
        if animatingFromHome {
            //set collection view position to current unplayed level
            let unplayedIndex = max(1, (RZQuizDatabase.currentLevel() - 1) * 5)
            
            if let unplayedItemLayout = collectionView.collectionViewLayout.layoutAttributesForItem(at: IndexPath(item: unplayedIndex - 1, section: 0)) {
                collectionView.contentOffset = CGPoint(x: unplayedItemLayout.frame.origin.x
                    + collectionView.contentInset.left
                    + collectionView.raz_safeAreaInsets.left,
                    y: 0)
            }

            animatingFromHome = false
        }
        
        if RZQuizDatabase.numberOfFavories() == 0 {
            favoritesButton.isHidden = true
        } else {
            favoritesButton.isHidden = false
        }
    }
    
    @IBAction func homePressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
        RZShowingFavorites = false
    }
    
    @IBAction func toggleFavorites(_ sender: UIButton) {
        RZShowingFavorites = !RZShowingFavorites
        favoritesButton.setImage(UIImage(named: RZShowingFavorites ? "button-back" : "button-heart"), for: .normal)
        if RZShowingFavorites {
            offsetBeforeFavoritesToggled = collectionView.contentOffset
        }
        collectionView.reloadData()
        
        collectionView.contentOffset = (RZShowingFavorites ? .zero : offsetBeforeFavoritesToggled)
        
        if !RZShowingFavorites {
            UIView.animate(withDuration: 0.5, animations: {
                self.view.layoutIfNeeded()
            })
        } else if RZShowingFavorites {
            delay(1.0) {
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
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var coinView: UIView!
    @IBOutlet weak var coin1: UIImageView!
    @IBOutlet weak var coin2: UIImageView!
    @IBOutlet weak var coin3: UIImageView!
    @IBOutlet weak var coin4: UIImageView!
    @IBOutlet weak var coin5: UIImageView!
    var coins: [UIImageView] = []
    @IBOutlet weak var coinContainerAspect: NSLayoutConstraint!
    @IBOutlet weak var coinContainer: UIView!
    
    func decorate(_ index: Int, showFavorites: Bool, cellSize: CGSize) {
        self.coins = [coin1, coin2, coin3, coin4, coin5]
        
        let rhyme: Rhyme
        
        if showFavorites {
            let favs = RZQuizDatabase.getFavorites()
            if index >= favs.count { return }
            let number = favs[index]
            rhyme = Rhyme(number)
        } else {
            rhyme = RZQuizDatabase.getQuiz(index)
        }
        
        let quizIndex = RZQuizDatabase.getIndexForRhyme(rhyme)
        let quizNumber = rhyme.number.threeCharacterString
        let image = UIImage.thumbnail(for: "thumbnail_\(quizNumber).jpg", maxSize: cellSize.height * UIScreen.main.scale)
        let name = rhyme.name.uppercased()
        let isFavorite = rhyme.isFavorite()
        let (gold, silver) = rhyme.getQuizResult()
        let hasBeenPlayed = rhyme.quizHasBeenPlayed()
        
        self.favoriteIcon.isHidden = !isFavorite
        self.title.text = name
        self.numberLabel.text = "\(quizIndex + 1)"
        self.thumbnail.image = image
    
        //update coins
        var countToShow = gold + silver
    
        if gold + silver == 0 && hasBeenPlayed {
            countToShow = 5
        }
        setCoinsInImageViews(self.coins, gold: gold, silver: silver, big: false)
    
        self.coinContainer.isHidden = !hasBeenPlayed
        self.coinContainer.removeConstraint(self.coinContainerAspect)
    
        let coinContainerAspect = self.coinContainer.widthAnchor.constraint(equalTo: self.coinContainer.heightAnchor, multiplier: CGFloat(countToShow))
        coinContainerAspect.isActive = true
        self.coinContainerAspect = coinContainerAspect
    }
    
}

class DecorationCell : UICollectionViewCell {
    
    func decorate() {
        // noop
    }
    
}
