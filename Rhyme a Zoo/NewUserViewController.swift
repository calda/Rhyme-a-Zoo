//
//  NewUserViewController.swift
//  Rhyme a Zoo
//
//  Created by Cal on 7/16/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import Foundation
import UIKit

class NewUserViewController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var selectedIcon: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var hiddenInput: UITextField!
    @IBOutlet weak var finishEditingButton: UIButton!
    @IBOutlet weak var continueButton: UIButton!
    
    var userInputName: String = ""
    var currentIconName: String = "Name"
    
    var availableIcons = ["angry", "Ate", "baby", "Steal", "cat", "calf", "climb", "clown", "dance", "skip",
        "dog", "dwarf", "Fall", "farmer", "fisherman", "grandfather", "grandmother", "happy", "hen", "proud",
        "horse", "hug", "hunter", "jump"]
    
    override func viewWillAppear(animated: Bool) {
        continueButton.enabled = false
        selectedIcon.layer.masksToBounds = true
        selectedIcon.layer.cornerRadius = selectedIcon.frame.height / 6.0
        selectedIcon.layer.borderColor = UIColor.whiteColor().CGColor
        selectedIcon.layer.borderWidth = 2.0
        
        finishEditingButton.alpha = 0.0
        
        //remove unavailable icons and shuffle remaining
        availableIcons = availableIcons.shuffled()
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
        let height = collectionView.frame.height / 2.0
        return CGSizeMake(height, height)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        for visible in collectionView.visibleCells() {
            if let cell = visible as? UserIconCell {
                if collectionView.indexPathForCell(cell) == indexPath {
                    
                    //user tapped this cell
                    cell.animateSelection()
                    let iconName = availableIcons[indexPath.item]
                    let splitIndex = iconName.startIndex.successor()
                    currentIconName = iconName.substringToIndex(splitIndex).uppercaseString + iconName.substringFromIndex(splitIndex).lowercaseString
                    if userInputName == "" {
                        nameLabel.text = currentIconName
                        nameLabel.alpha = 0.5
                    }
                    selectedIcon.image = UIImage(named: iconName + ".jpg")
                    
                    continueButton.enabled = true
                    
                } else {
                    cell.animateDeselection()
                }
            }
        }
    }
    
    @IBAction func editName(sender: AnyObject) {
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
            nameLabel.text = currentIconName
            nameLabel.alpha = 0.5
        } else {
            nameLabel.text = userInputName
            nameLabel.alpha = 0.85
        }
    }
    
    @IBAction func quitEditing(sender: AnyObject) {
        self.hiddenInput.resignFirstResponder()
    }

    
    @IBAction func editingEnded(sender: UITextField) {
        UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: nil, animations: {
            self.finishEditingButton.alpha = 0.0
            self.finishEditingButton.transform = CGAffineTransformMakeScale(0.5, 0.5)
        }, completion: nil)
    }
    
    @IBAction func cancelPressed(sender: AnyObject) {
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
        
        iconImage.layer.masksToBounds = true
        iconImage.layer.cornerRadius = iconImage.frame.height / 6.0
        iconImage.layer.borderColor = UIColor.whiteColor().CGColor
        iconImage.layer.borderWidth = 2.0
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