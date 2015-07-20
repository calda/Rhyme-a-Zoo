//
//  UsersViewController.swift
//  Rhyme a Zoo
//
//  Created by Cal on 7/16/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import Foundation
import UIKit

class UsersViewController : UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UIGestureRecognizerDelegate {
    
    //MARK: Setting up the View Controller
    
    var users: [User] = []
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionWidth: NSLayoutConstraint!
    @IBOutlet weak var coverGradient: UIImageView!
    
    override func viewDidLoad() {
        users = RZUserDatabase.getUsers()
        //present welcome view if there are no users
        //present main view if there is only one user
        if users.count == 0 || users.count == 1 {
            coverGradient.alpha = 1.0
        } else {
            coverGradient.alpha = 0.0
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        users = RZUserDatabase.getUsers()
        self.collectionView.reloadData()
        
        if users.count == 0 {
            coverGradient.alpha = 1.0
        }
        
        //calculate height of collectionView and width of cells
        let screenHeight = UIScreen.mainScreen().bounds.height
        let notCollection = screenHeight - (10 + (screenHeight / 4.5) + 10)
        let collectionHeight = (notCollection * 0.75)
        let iconHeight = collectionHeight - 29
        let cellWidth = iconHeight + 15
        let widthInUse = cellWidth * CGFloat(users.count + 1)
        
        //center collection view if full width is not used
        let screenWidth = UIScreen.mainScreen().bounds.width
        if widthInUse < screenWidth {
            let diff = screenWidth - widthInUse
            collectionWidth.constant = -diff
            self.view.layoutIfNeeded()
            collectionView.scrollEnabled = false
            collectionView.contentInset = UIEdgeInsetsZero
        } else {
            collectionView.scrollEnabled = true
            collectionView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        }
        
        //turn off clipping on the collection view
        collectionView.clipsToBounds = false
    }
    
    override func viewDidAppear(animated: Bool) {
        if coverGradient.alpha == 1.0 {
            if users.count == 0 { //present welcome view if there are no users
                let welcome = UIStoryboard(name: "User", bundle: nil).instantiateViewControllerWithIdentifier("welcome") as! UIViewController
                self.presentViewController(welcome, animated: false, completion: nil)
            }
            else { //present main view if there is only one user
                RZCurrentUser = RZUserDatabase.getUsers()[0]
                let home = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! UIViewController
                self.presentViewController(home, animated: false, completion: nil)
            }
            
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        coverGradient.alpha = 0.0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return users.count + 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if indexPath.item == users.count { //add user button as last cell
            return collectionView.dequeueReusableCellWithReuseIdentifier("add", forIndexPath: indexPath) as! UICollectionViewCell
        }
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("user", forIndexPath: indexPath) as! UserCell
        let user = users[indexPath.item]
        cell.decorate(user)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let height = collectionView.frame.height
        let iconHeight = height - 29
        let width = iconHeight + 15
        return CGSizeMake(width, height)
    }
    
    //MARK: Selection of Cells
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if indexPath.item == users.count { //add user button is last
            return
        }
        let user = users[indexPath.item]
        RZCurrentUser = user
        let mainMenu = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! UIViewController
        self.presentViewController(mainMenu, animated: true, completion: nil)
    }
    
    @IBAction func touchRecognized(sender: UITouchGestureRecognizer) {
        let touch = sender.locationInView(self.view)
        
        for visible in collectionView.visibleCells() {
            if let cell = visible as? UICollectionViewCell {
                
                if sender.state == .Ended {
                    deselectCell(cell)
                    continue
                }
                
                let screenFrame = cell.superview!.convertRect(cell.frame, toView: self.view)
                if screenFrame.contains(touch) {
                   selectCell(cell)
                } else {
                    deselectCell(cell)
                }
            }
        }
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    //deselect all cells when the view scrolls
    func scrollViewDidScroll(scrollView: UIScrollView) {
        for visible in collectionView.visibleCells() {
            if let cell = visible as? UICollectionViewCell {
                deselectCell(cell)
            }
        }
    }
    
    func selectCell(cell: UICollectionViewCell) {
        UIView.animateWithDuration(0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: nil, animations: {
            cell.transform = CGAffineTransformMakeScale(1.1, 1.1)
        }, completion: nil)
    }
    
    func deselectCell(cell: UICollectionViewCell) {
        UIView.animateWithDuration(0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: nil, animations: {
            cell.transform = CGAffineTransformMakeScale(1.0, 1.0)
        }, completion: nil)
    }
    
    //MARK: Unwind Segue
    @IBAction func returnToUsers(segue: UIStoryboardSegue) { }
    
}

class UserCell : UICollectionViewCell {
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var name: UILabel!
    
    func decorate(user: User) {
        name.text = user.name
        icon.image = user.icon
        decorateUserIcon(icon)
    }
    
}