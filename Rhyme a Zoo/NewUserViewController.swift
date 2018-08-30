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
    "robin", "sheep", "puppy", "turtle", "wolf", "bee", "alligator", "dogs", "giraffe", "lizard", "pelican",
    "beagle", "beaver", "hound", "bull", "bulldog", "chipmunk", "collie", "crab", "dragonfly", "eagle",
    "ferret", "gazelle", "bear", "hamster", "jellyfish", "mole", "orca", "parrot", "penguin", "rhino",
    "skunk", "snail", "turkey", "walrus", "zebra"]

func updateAvailableIconsForUsers(_ users: [User], availableIcons: inout [String]) {
    var userRemoved = false
    for user in users {
        let usedIcon = user.iconName
        let iconCount = availableIcons.count
        for i_forwards in 1 ... iconCount {
            //go backwards through the array so we can take out indecies as we go
            let i = iconCount - i_forwards
            if usedIcon.lowercased().hasPrefix(availableIcons[i].lowercased()) {
                
                //leave one of the user's current icon
                if user.toUserString() == RZCurrentUser.toUserString() {
                    if userRemoved { continue }
                    else { userRemoved = true }
                }
                
                availableIcons.remove(at: i)
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
    var instructionsTimer: Timer?
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        editModeBackButton.alpha = 0.0
        editModeDeleteButton.alpha = 0.0
        continueButton.isEnabled = false
        decorateUserIcon(selectedIcon)
        
        finishEditingButton.alpha = 0.0
        
        //remove unavailable icons and shuffle remaining
        availableIcons = availableIcons.shuffled()
        updateAvailableIconsForUsers(RZUserDatabase.getLocalUsers(), availableIcons: &self.availableIcons)
        
        RZUserDatabase.getLinkedClassroom({ classroom in
            if let classroom = classroom {
                self.requireName = true
                RZUserDatabase.getUsersForClassroom(classroom, completion: { users in
                    updateAvailableIconsForUsers(users, availableIcons: &self.availableIcons)
                    self.collectionView.reloadData()
                })
            }
        })
        
        if let user = editUser, editMode {
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
            let iconName = (iconFile as NSString).replacingOccurrences(of: ".jpg", with: "")
            self.availableIcons.append(iconName)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if UAIsAudioPlaying() {
            UAHaltPlayback()
        }
        
        if !editMode {
            instructionsTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(NewUserViewController.playInstructionAudio), userInfo: nil, repeats: false)
        }
    }
    
    func playInstructionAudio() {
        UAPlayer().play("create-user", ofType: "mp3", ifConcurrent: .interrupt)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        instructionsTimer?.invalidate()
        UAHaltPlayback()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "icon", for: indexPath) as! UserIconCell
        cell.decorate(availableIcons[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return availableIcons.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.frame.height / (iPad() ? 3.0 : 2.0)
        return CGSize(width: height, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        for visible in collectionView.visibleCells {
            if let cell = visible as? UserIconCell {
                if collectionView.indexPath(for: cell) == indexPath {
                    
                    //user tapped this cell
                    cell.animateSelection()
                    //dismiss keyboard if it is presented
                    quitEditing(collectionView)
                    
                    let iconName = availableIcons[indexPath.item]
                    currentIconString = iconName + ".jpg"
                    let splitIndex = iconName.characters.index(after: iconName.startIndex)
                    currentIconName = iconName.substring(to: splitIndex).uppercased() + iconName.substring(from: splitIndex).lowercased()
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        quitEditing(scrollView)
    }
    
    @IBAction func editName(_ sender: AnyObject) {
        if editMode { return } //can't edit the name in Edit Mode
        
        hiddenInput.autocorrectionType = UITextAutocorrectionType.no
        hiddenInput.autocapitalizationType = UITextAutocapitalizationType.words
        self.hiddenInput.becomeFirstResponder()
        
        finishEditingButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        UIView.animate(withDuration: 0.8, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: [], animations: {
            self.finishEditingButton.alpha = 1.0
            self.finishEditingButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }, completion: nil)
    }
    
    @IBAction func hiddenInputChanged(_ sender: UITextField) {
        userInputName = sender.text ?? ""
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
    
    @IBAction func quitEditing(_ sender: AnyObject) {
        self.hiddenInput.resignFirstResponder()
        checkIfComplete()
    }

    
    @IBAction func editingEnded(_ sender: UITextField) {
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: [], animations: {
            self.finishEditingButton.alpha = 0.0
            self.finishEditingButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        }, completion: nil)
        checkIfComplete()
    }
    
    func checkIfComplete() {
        let icon = currentIconString != ""
        let name = !requireName || userInputName != ""
        self.continueButton.isEnabled = icon && name
    }
    
    @IBAction func cancelPressed(_ sender: AnyObject) {
        UAHaltPlayback()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func continuePressed(_ sender: AnyObject) {
        self.resignFirstResponder()
        if RZSettingRequirePasscode.currentSetting() == true {
            createPasscode("Create a passcode for \(nameLabel.text!)", currentController: self, completion: { passcode in
                if let passcode = passcode {
                    self.createNewUser(passcode)
                }
            })
        }
        else {
            createNewUser(nil)
        }
    }
    
    func createNewUser(_ passcode: String?) {
        //create new user
        let name = nameLabel.text!
        let iconName = currentIconString
        let user = User(name: name, iconName: iconName)
        user.passcode = passcode
        RZUserDatabase.addLocalUser(user)
        RZCurrentUser = user
        
        let mainMenu = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()!
        self.present(mainMenu, animated: true, completion: nil)
    }
    
    //MARK: Edit Mode (launched from Home view)
    
    func openInEditModeForUser(_ user: User) {
        self.editMode = true
        self.editUser = user
    }
    
    @IBAction func editModeDeletePressed(_ sender: AnyObject) {
        if let user = editUser {
            
            let alert = UIAlertController(title: "Delete \(user.name)?", message: "You'll lose all of your progress. This cannot be undone.", preferredStyle: .alert)
            let nevermind = UIAlertAction(title: "Nevermind", style: .default, handler: nil)
            let delete = UIAlertAction(title: "Delete", style: .destructive, handler: { action in
                
                RZUserDatabase.deleteLocalUser(user, deleteFromClassroom: true)
                
                //present last alert
                let okAlert = UIAlertController(title: "Deleted \(user.name)", message: nil, preferredStyle: .alert)
                let ok = UIAlertAction(title: "ok", style: .default, handler: { action in
                    self.editMode = false
                    dismissController(self, untilMatch: { controller in
                        return controller is UsersViewController
                    })
                })
                okAlert.addAction(ok)
                self.present(okAlert, animated: true, completion: nil)
                
            })
            alert.addAction(nevermind)
            alert.addAction(delete)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func editModeBackPressed(_ sender: AnyObject) {
        if let editUser = editUser {
            //save edits to user
            RZUserDatabase.changeLocalUserIcon(user: editUser, newIcon: currentIconString)
        }
        
        editMode = false
        self.dismiss(animated: true, completion: nil)
    }

}

class UserIconCell : UICollectionViewCell {
    
    @IBOutlet weak var iconImage: UIImageView!
    
    func decorate(_ iconName: String) {
        let image = UIImage(named: "\(iconName).jpg")
        iconImage.image = image
        self.layer.rasterizationScale = UIScreen.main.scale
        self.layer.shouldRasterize = true
        
        decorateUserIcon(iconImage)
        iconImage.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
    }
    
    func animateSelection() {
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: [], animations: {
            self.iconImage.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        }, completion: nil)
    }
    
    func animateDeselection() {
        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: [], animations: {
            self.iconImage.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }, completion: nil)
    }
    
}

func decorateUserIcon(_ view: UIView) {
    decorateUserIcon(view, height: view.frame.height)
}

func decorateUserIcon(_ view: UIView, height: CGFloat) {
    view.layer.masksToBounds = true
    view.layer.cornerRadius = height / 6.0
    view.layer.borderColor = UIColor.white.cgColor
    view.layer.borderWidth = 2.0
}
