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
    
    var users: [User] = []
    var allowUserCreation = true
    var cloudUsers: Bool = false
    @IBOutlet weak var collectionView: UICollectionView!
    var numberOfCells: Int {
        return collectionView(collectionView, numberOfItemsInSection: 0)
    }
    @IBOutlet weak var collectionViewArea: UIView!
    @IBOutlet weak var collectionWidth: NSLayoutConstraint!
    @IBOutlet weak var coverGradient: UIImageView!
    
    @IBOutlet weak var reloadButton: UIButton!
    @IBOutlet weak var classroomIcon: UIButton!
    @IBOutlet weak var classroomLabel: UIButton!
    @IBOutlet weak var collectionViewPosition: NSLayoutConstraint!
    var viewAppeared = false
    var classroomLinked = false
    var viewAppearingAnimated: Bool = true
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var displayOffset: CGFloat {
        return iPad() && numberOfCells > 2 ? 2.0 : 1.0
    }
    
    //MARK: - Loading Users with fail-safes
    
    override func viewWillAppear(animated: Bool) {
        if users.count == 0 { collectionView.alpha = 0.0 }
        else { decorateForLoadedUsers() }
        viewAppearingAnimated = animated
        classroomLabel.hidden = true
        classroomIcon.hidden = true
        activityIndicator.hidden = animated
        
        loadUsers()
        
        if let allowUserCreation = RZSettingUserCreation.currentSetting() {
            self.allowUserCreation = allowUserCreation
        }
        
        //load users again just in case it took a bit to save to the cloud
        if animated {
            delay(2.0) {
                self.loadUsers()
            }
        }
    }
    
    func loadUsers() {
        //present welcome view if there are no users
        //present main view if there is only one user
        //but stay on this view if there is a linked classroom
        RZUserDatabase.getLinkedClassroom() { classroom in
            if let classroom = classroom {
                if let allowUserCreation = RZSettingUserCreation.currentSetting() {
                    self.allowUserCreation = allowUserCreation
                }
                
                self.classroomLabel.hidden = false
                self.classroomLabel.titleLabel!.text = classroom.name
                self.classroomLabel.setTitle(classroom.name, forState: .Normal)
                self.classroomIcon.hidden = false
                self.coverGradient.alpha = 0.0
                self.collectionViewPosition.constant = 30.0
                UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: nil, animations: {
                    self.view.layoutIfNeeded()
                    self.classroomLabel.alpha = 1.0
                    self.classroomIcon.alpha = 1.0
                }, completion: nil)
                self.cloudUsers = true
                
                //get users
                RZUserDatabase.getUsersForClassroom(classroom, completion: { users in
                    
                    self.users = users
                    self.activityIndicator.hidden = true
                    self.decorateForLoadedUsers()
                    self.collectionView.reloadData()
                    self.classroomLinked = true
                    
                })
                
                return
            }
                
            else {
                
                if RZUserDatabase.hasLinkedClassroom() {
                    self.connectionIssues(duringLoad: true)
                }
                
                //fall back to local users if there isn't a classroom
                self.users = RZUserDatabase.getLocalUsers()
                self.collectionView.reloadData()
                self.activityIndicator.hidden = true
                
                if self.users.count == 0 || self.users.count == 1 {
                    self.coverGradient.alpha = 1.0
                } else {
                    self.coverGradient.alpha = 0.0
                }
                
                self.classroomLinked = true
                if self.viewAppeared {
                    self.readyToChangeViews()
                }
                
                self.decorateForLoadedUsers()
                
                UIView.animateWithDuration(0.4, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: nil, animations: {
                    self.reloadButton.alpha = 0.0
                }, completion: nil)
                
            }
            
        }
        
        delay(5.0) {
            //if it takes more that five seconds to load the users
            if !self.classroomLinked {
                self.connectionIssues(duringLoad: true)
            }
            
        }
    }
    
    func connectionIssues(#duringLoad: Bool) {
        let alert = UIAlertController(title: "We're having trouble connecting to the internet.", message: " Classrooms require an internet connection.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Try Again", style: .Default, handler: { _ in
            self.loadUsers()
            
            if !duringLoad {
                self.activityIndicator.alpha = 1.0
                self.classroomLinked = false
                self.cloudUsers = false
                delay(1.0) {
                    self.collectionView.alpha = 0.0
                    self.activityIndicator.alpha = 1.0
                }
                delay(5.0) {
                    if self.users.count == 0 {
                        self.connectionIssues(duringLoad: false)
                    }
                }
            }
            
        }))
        alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { _ in
            openSettings()
            delay(1.0) {
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "Leave Classroom", style: .Destructive, handler: { _ in
            
            //confirm with passcode
            if let passcode = RZUserDatabase.getLinkedClassroomPasscode() {
                
                requestPasscdoe(passcode, "Verify passcode to leave classroom on this device.", currentController: self) { success in
                    if success {
                        RZUserDatabase.unlinkClassroom()
                    }
                    self.loadUsers()
                }
                
            }
            else {
                self.loadUsers()
            }
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //MARK: - Setting up the View Controller
    
    func decorateForLoadedUsers() {
        if users.count == 0 && !cloudUsers {
            coverGradient.alpha = 1.0
        }
        
        if iPad() && displayOffset == 1.0 {
            collectionViewArea.transform = CGAffineTransformMakeScale(0.75, 0.75)
        } else {
            collectionViewArea.transform = CGAffineTransformMakeScale(1.0, 1.0)
        }
        
        //calculate height of collectionView and width of cells
        let screenHeight = UIScreen.mainScreen().bounds.height
        let notCollection = screenHeight - (10 + (screenHeight / 4.5) + 10)
        let collectionHeight = (notCollection * 0.75) / displayOffset
        let iconHeight = collectionHeight - 29
        let cellWidth = iconHeight + 15
        let userCount = CGFloat(users.count + (allowUserCreation ? 1 : 0))
        let widthInUse = cellWidth * CGFloat(ceil(userCount / displayOffset))
        
        //center collection view if full width is not used
        let screenWidth = UIScreen.mainScreen().bounds.width
        if widthInUse < screenWidth {
            let diff = screenWidth - widthInUse
            collectionWidth.constant = -diff
            self.view.layoutIfNeeded()
            collectionView.scrollEnabled = false
            collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        } else {
            collectionView.scrollEnabled = true
            collectionWidth.constant = 0
            self.view.layoutIfNeeded()
            collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        
        //turn off clipping on the collection view
        collectionView.clipsToBounds = false
        
        //animate
        if collectionView.alpha == 0.0 {
            collectionView.transform = CGAffineTransformMakeScale(0.5, 0.5)
            UIView.animateWithDuration(0.7, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: nil, animations: {
                self.collectionView.transform = CGAffineTransformMakeScale(1.0, 1.0)
            }, completion: nil)
            
            UIView.animateWithDuration(0.3) {
                self.collectionView.alpha = 1.0
            }
        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
        viewAppeared = true
        if classroomLinked {
            readyToChangeViews()
        }
    }
    
    func readyToChangeViews() {
        if coverGradient.alpha == 1.0 {
            if users.count == 0 { //present welcome view if there are no users
                let welcome = UIStoryboard(name: "User", bundle: nil).instantiateViewControllerWithIdentifier("welcome") as! UIViewController
                self.presentViewController(welcome, animated: false, completion: nil)
            }
            else if users.count == 1 && !cloudUsers && !viewAppearingAnimated { //present main view if there is only one user
                RZCurrentUser = RZUserDatabase.getLocalUsers()[0]
                let home = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! UIViewController
                self.presentViewController(home, animated: false, completion: nil)
            } else {
                coverGradient.alpha = 0.0
            }
            
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        coverGradient.alpha = 0.0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return users.count + (allowUserCreation ? 1 : 0)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if indexPath.item == users.count { //add user button as last cell
            return collectionView.dequeueReusableCellWithReuseIdentifier("add", forIndexPath: indexPath) as! UICollectionViewCell
        }
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("user", forIndexPath: indexPath) as! UserCell
        let user = users[indexPath.item]
        cell.decorate(user, height: collectionView.frame.height  / displayOffset)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let height = collectionView.frame.height / displayOffset
        let iconHeight = height - 29
        let width = iconHeight + 15
        return CGSizeMake(width, height)
    }
    
    //MARK: - Selection of Cells
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        println(indexPath.item)
        //if indexPath.item == users.count { //add user button is last
        //    return
        //}
        //let user = users[indexPath.item]
        //checkUserPasscode(user)
    }
    
    func checkUserPasscode(user: User) {
        if let passcode = user.passcode where RZSettingRequirePasscode.currentSetting() == true {
            requestPasscdoe(passcode, "Enter the passcode for \(user.name)", currentController: self, forKids: true, { success in
                if success {
                    self.logInToUser(user)
                }
            })
        }
        else {
            logInToUser(user)
        }
    }
    
    func logInToUser(user: User) {
        RZCurrentUser = user
        user.pullDataFromCloud()
        let mainMenu = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! UIViewController
        self.presentViewController(mainMenu, animated: true, completion: nil)
        
        if !RZUserDatabase.hasLinkedClassroom() { return }
        
        //make sure the classroom still exists
        RZUserDatabase.getLinkedClassroomFromCloud({ classroom in
            if classroom == nil {
                
                //if we aren't linked to a classroom now, that means the classroom really was deleted on another device
                if !RZUserDatabase.hasLinkedClassroom() {
                    let alert = UIAlertController(title: "Your classroom was just deleted on another device.", message: "You will now be logged out.", preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { _ in
                        mainMenu.dismissViewControllerAnimated(true, completion: nil)
                    }))
                    mainMenu.presentViewController(alert, animated: true, completion: nil)
                }
                    
                else {
                    //other option is that the internet is no longer available
                    mainMenu.dismissViewControllerAnimated(true, completion: {
                        self.collectionView.alpha = 0.0
                        self.connectionIssues(duringLoad: false)
                    })
                    
                }
                
                
            }
        })
    }
    
    var pannedDuringTouch = false
    
    @IBAction func touchRecognized(sender: UITouchGestureRecognizer) {
        let touch = sender.locationInView(self.view)
        
        if sender.state == .Began {
            pannedDuringTouch = false
        }
        
        for visible in collectionView.visibleCells() {
            if let cell = visible as? UICollectionViewCell {
                
                let screenFrame = cell.superview!.convertRect(cell.frame, toView: self.view)
                if screenFrame.contains(touch) && !pannedDuringTouch {
                    if sender.state == .Ended {
                        //select the cell
                        deselectCell(cell)
                        if let cell = cell as? UserCell {
                            if let user = cell.user where !pannedDuringTouch {
                                checkUserPasscode(user)
                            }
                        }
                        else {
                            //is Add User cell
                            let newUser = UIStoryboard(name: "User", bundle: nil).instantiateViewControllerWithIdentifier("newUser") as! NewUserViewController
                            self.presentViewController(newUser, animated: true, completion: nil)
                        }
                    } else {
                        selectCell(cell)
                    }
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
        pannedDuringTouch = true
        
        for visible in collectionView.visibleCells() {
            if let cell = visible as? UICollectionViewCell {
                deselectCell(cell)
            }
        }
    }
    
    func selectCell(cell: UICollectionViewCell) {
        let scale: CGFloat = iPad() ? 1.05 : 1.1
        UIView.animateWithDuration(0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: nil, animations: {
            cell.transform = CGAffineTransformMakeScale(scale, scale)
        }, completion: nil)
    }
    
    func deselectCell(cell: UICollectionViewCell) {
        UIView.animateWithDuration(0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: nil, animations: {
            cell.transform = CGAffineTransformMakeScale(1.0, 1.0)
        }, completion: nil)
    }
    
    //MARK: Unwind Segue
    @IBAction func returnToUsers(segue: UIStoryboardSegue) { }
    
    //MARK: Other User Interaction
    
    @IBAction func openClassroomSettings(sender: UIButton) {
        RZUserDatabase.getLinkedClassroom({ classroom in
        
            if let classroom = classroom {
                requestPasscode(classroom.passcode, "Passcode for \(classroom.name)", currentController: self, completion: {
                    let settings = UIStoryboard(name: "User", bundle: nil).instantiateViewControllerWithIdentifier("classroomSettings") as! SettingsViewController
                    RZUserDatabase.getLinkedClassroom({ classroom in
                        if let classroom = classroom {
                            settings.classroom = classroom
                            self.presentViewController(settings, animated: true, completion: nil)
                        }
                    })
                })
            }
            
        })
    }
    
    @IBAction func reloadUsers(sender: UIButton) {
        self.loadUsers()
        self.activityIndicator.hidden = false
    }
    
}

class UserCell : UICollectionViewCell {
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var name: UILabel!
    var user: User?
    
    func decorate(user: User, height: CGFloat) {
        self.user = user
        name.text = user.name
        icon.image = user.icon
        decorateUserIcon(icon, height)
    }
    
}