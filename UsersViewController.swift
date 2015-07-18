//
//  UsersViewController.swift
//  Rhyme a Zoo
//
//  Created by Cal on 7/16/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import Foundation
import UIKit

class UsersViewController : UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    var users: [User] = []
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionWidth: NSLayoutConstraint!
    @IBOutlet weak var coverGradient: UIImageView!
    
    override func viewWillAppear(animated: Bool) {
        users = RZUserDatabase.getUsers()
        
        //present welcome view if there are no users
        if users.count == 0 {
            coverGradient.alpha = 1.0
        } else {
            coverGradient.alpha = 0.0
        }
        
        //calculate height of collectionView
        let screenHeight = UIScreen.mainScreen().bounds.height
        let notCollection = screenHeight - (10 + (screenHeight / 4.5) + 10)
        let collectionHeight = (notCollection * 0.75)
        let cellWidth = collectionHeight
        let widthInUse = cellWidth * CGFloat(users.count)
        
        //center collection view if full width is not used
        let screenWidth = UIScreen.mainScreen().bounds.width
        if widthInUse < screenWidth {
            let diff = screenWidth - widthInUse
            collectionWidth.constant = -diff - 80
            self.view.layoutIfNeeded()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        if coverGradient.alpha == 1.0 {
            let welcome = UIStoryboard(name: "User", bundle: nil).instantiateViewControllerWithIdentifier("welcome") as! UIViewController
            self.presentViewController(welcome, animated: false, completion: nil)
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return users.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("user", forIndexPath: indexPath) as! UserCell
        let user = users[indexPath.item]
        cell.decorate(user)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let height = collectionView.frame.height
        return CGSizeMake(height, height)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let user = users[indexPath.item]
        RZCurrentUser = user
        let mainMenu = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! UIViewController
        self.presentViewController(mainMenu, animated: true, completion: nil)
    }
    
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