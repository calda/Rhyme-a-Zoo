//
//  NewUserViewController.swift
//  Rhyme a Zoo
//
//  Created by Cal on 7/16/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import Foundation
import UIKit

let RZUserIconOptions = ["bat", "Birds", "bunny", "calf", "cat", "cow", "dog", "duck", "ducks", "elephant", "fish",
    "fly", "flying squirrel", "fox", "frog", "goat", "goose", "hen", "hog", "horse", "lion", "mouse", "pig",
    "robin", "sheep", "puppy", "turtle", "wolf", "bee", "alligator", "dogs", "giraffe"]

func updateAvailableIconsForUsers(users: [User], inout availableIcons: [String]) {
    var userRemoved = false
    for user in users {
        let usedIcon = user.iconName
        let iconCount = availableIcons.count
        for i_forwards in 1 ... iconCount {
            //go backwards through the array so we can take out indecies as we go
            let i = iconCount - i_forwards
            if usedIcon.lowercaseString.hasPrefix(availableIcons[i].lowercaseString) {
                
                //leave one of the user's current icon
                if user.toUserString() == RZCurrentUser.toUserString() {
                    if userRemoved { continue }
                    else { userRemoved = true }
                }
                
                availableIcons.removeAtIndex(i)
            }
        }
    }
}

class NewUserViewController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var selectedIcon: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var hiddenInput: UITextField!
    @IBOutlet weak var finishEditingButton: UIButton!
    @IBOutlet weak var continueButton: UIButton!
    var instructionsTimer: NSTimer?
    
    var userInputName: String = ""
    var currentIconName: String = "Name"
    var currentIconString: String = ""
    var requireName = false
    
    //if the view was launched to edit a user instead of creating a user
    var editMode = false
    var editUser: User?
    @IBOutlet weak var editModeBackButton: UIButton!
    @IBOutlet weak var editModeDeleteButton: UIButton!
    @IBOutlet weak var typeNameButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    
    
    var availableIcons = RZUserIconOptions
    
    override func viewWillAppear(animated: Bool) {
        editModeBackButton.alpha = 0.0
        editModeDeleteButton.alpha = 0.0
        continueButton.enabled = false
        decorateUserIcon(selectedIcon)
        
        finishEditingButton.alpha = 0.0
        
        //remove unavailable icons and shuffle remaining
        availableIcons = availableIcons.shuffled()
        updateAvailableIconsForUsers(RZUserDatabase.getLocalUsers(), &self.availableIcons)
        
        RZUserDatabase.getLinkedClassroom({ classroom in
            if let classroom = classroom {
                self.requireName = true
                RZUserDatabase.getUsersForClassroom(classroom, completion: { users in
                    updateAvailableIconsForUsers(users, &self.availableIcons)
                    self.collectionView.reloadData()
                })
            }
        })
        
        if let user = editUser where editMode {
            selectedIcon.image = user.icon
            currentIconString = user.iconName
            nameLabel.text = user.name
            nameLabel.alpha = 0.95
            userInputName = user.name
            
            editModeDeleteButton.alpha = RZSettingUserCreation.currentSetting() == false ? 0.0 : 1.0
            editModeBackButton.alpha = 1.0
            doneButton.alpha = 0.0
            typeNameButton.alpha = 0.0
            
            //add user's icon to the available icons
            let iconFile = user.iconName
            //remove .jpg
            let iconName = (iconFile as NSString).stringByReplacingOccurrencesOfString(".jpg", withString: "")
            self.availableIcons.append(iconName)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        if UAIsAudioPlaying() {
            UAHaltPlayback()
        }
        
        if !editMode {
            instructionsTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "playInstructionAudio", userInfo: nil, repeats: false)
        }
    }
    
    func playInstructionAudio() {
        UAPlayer().play("create-user", ofType: "mp3", ifConcurrent: .Interrupt)
    }
    
    override func viewWillDisappear(animated: Bool) {
        instructionsTimer?.invalidate()
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("icon", forIndexPath: indexPath) as! UserIconCell
        cell.decorate(availableIcons[indexPath.item])
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return availableIcons.count
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let height = collectionView.frame.height / (iPad() ? 3.0 : 2.0)
        return CGSizeMake(height, height)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        for visible in collectionView.visibleCells() {
            if let cell = visible as? UserIconCell {
                if collectionView.indexPathForCell(cell) == indexPath {
                    
                    //user tapped this cell
                    cell.animateSelection()
                    //dismiss keyboard if it is presented
                    quitEditing(collectionView)
                    
                    let iconName = availableIcons[indexPath.item]
                    currentIconString = iconName + ".jpg"
                    let splitIndex = iconName.startIndex.successor()
                    currentIconName = iconName.substringToIndex(splitIndex).uppercaseString + iconName.substringFromIndex(splitIndex).lowercaseString
                    if userInputName == "" && !requireName {
                        nameLabel.text = currentIconName
                        nameLabel.alpha = 0.5
                    }
                    selectedIcon.image = UIImage(named: currentIconString)
                    
                    checkIfComplete()
                    
                } else {
                    cell.animateDeselection()
                }
            }
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        quitEditing(scrollView)
    }
    
    @IBAction func editName(sender: AnyObject) {
        if editMode { return } //can't edit the name in Edit Mode
        
        hiddenInput.autocorrectionType = UITextAutocorrectionType.No
        hiddenInput.autocapitalizationType = UITextAutocapitalizationType.Words
        self.hiddenInput.becomeFirstResponder()
        
        finishEditingButton.transform = CGAffineTransformMakeScale(0.5, 0.5)
        UIView.animateWithDuration(0.8, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: nil, animations: {
            self.finishEditingButton.alpha = 1.0
            self.finishEditingButton.transform = CGAffineTransformMakeScale(1.1, 1.1)
        }, completion: nil)
    }
    
    @IBAction func hiddenInputChanged(sender: UITextField) {
        userInputName = sender.text
        if userInputName == " " {
            sender.text = ""
            userInputName = ""
        }
        
        if userInputName == "" {
            nameLabel.text = requireName ? "Name" : currentIconName
            nameLabel.alpha = 0.5
        } else {
            nameLabel.text = userInputName
            nameLabel.alpha = 0.95
        }
        checkIfComplete()
    }
    
    @IBAction func quitEditing(sender: AnyObject) {
        self.hiddenInput.resignFirstResponder()
        checkIfComplete()
    }

    
    @IBAction func editingEnded(sender: UITextField) {
        UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: nil, animations: {
            self.finishEditingButton.alpha = 0.0
            self.finishEditingButton.transform = CGAffineTransformMakeScale(0.5, 0.5)
        }, completion: nil)
        checkIfComplete()
    }
    
    func checkIfComplete() {
        let icon = currentIconString != ""
        let name = !requireName || userInputName != ""
        self.continueButton.enabled = icon && name
    }
    
    @IBAction func cancelPressed(sender: AnyObject) {
        UAHaltPlayback()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func continuePressed(sender: AnyObject) {
        self.resignFirstResponder()
        if RZSettingRequirePasscode.currentSetting() == true {
            createPasscode("Create a passcode for \(nameLabel.text!)", currentController: self, { passcode in
                if let passcode = passcode {
                    self.createNewUser(passcode)
                }
            })
        }
        else {
            createNewUser(nil)
        }
    }
    
    func createNewUser(passcode: String?) {
        //create new user
        let name = nameLabel.text!
        let iconName = currentIconString
        let user = User(name: name, iconName: iconName)
        user.passcode = passcode
        RZUserDatabase.addLocalUser(user)
        RZCurrentUser = user
        
        let mainMenu = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! UIViewController
        self.presentViewController(mainMenu, animated: true, completion: nil)
    }
    
    //MARK: Edit Mode (launched from Home view)
    
    func openInEditModeForUser(user: User) {
        self.editMode = true
        self.editUser = user
    }
    
    @IBAction func editModeDeletePressed(sender: AnyObject) {
        if let user = editUser {
            
            let alert = UIAlertController(title: "Delete \(user.name)?", message: "You'll lose all of your progress. This cannot be undone.", preferredStyle: .Alert)
            let nevermind = UIAlertAction(title: "Nevermind", style: .Default, handler: nil)
            let delete = UIAlertAction(title: "Delete", style: .Destructive, handler: { action in
                
                RZUserDatabase.deleteLocalUser(user, deleteFromClassroom: true)
                
                //present last alert
                let okAlert = UIAlertController(title: "Deleted \(user.name)", message: nil, preferredStyle: .Alert)
                let ok = UIAlertAction(title: "ok", style: .Default, handler: { action in
                    self.editMode = false
                    dismissController(self, untilMatch: { controller in
                        return controller is UsersViewController
                    })
                })
                okAlert.addAction(ok)
                self.presentViewController(okAlert, animated: true, completion: nil)
                
            })
            alert.addAction(nevermind)
            alert.addAction(delete)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func editModeBackPressed(sender: AnyObject) {
        if let editUser = editUser {
            //save edits to user
            RZUserDatabase.changeLocalUserIcon(user: editUser, newIcon: currentIconString)
        }
        
        editMode = false
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}

class UserIconCell : UICollectionViewCell {
    
    @IBOutlet weak var iconImage: UIImageView!
    
    func decorate(iconName: String) {
        let image = UIImage(named: "\(iconName).jpg")
        iconImage.image = image
        self.layer.rasterizationScale = UIScreen.mainScreen().scale
        self.layer.shouldRasterize = true
        
        decorateUserIcon(iconImage)
        iconImage.transform = CGAffineTransformMakeScale(0.95, 0.95)
    }
    
    func animateSelection() {
        UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: nil, animations: {
            self.iconImage.transform = CGAffineTransformMakeScale(0.85, 0.85)
        }, completion: nil)
    }
    
    func animateDeselection() {
        UIView.animateWithDuration(0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: nil, animations: {
            self.iconImage.transform = CGAffineTransformMakeScale(0.95, 0.95)
        }, completion: nil)
    }
    
}

func decorateUserIcon(view: UIView) {
    decorateUserIcon(view, view.frame.height)
}

func decorateUserIcon(view: UIView, height: CGFloat) {
    view.layer.masksToBounds = true
    view.layer.cornerRadius = height / 6.0
    view.layer.borderColor = UIColor.whiteColor().CGColor
    view.layer.borderWidth = 2.0
}