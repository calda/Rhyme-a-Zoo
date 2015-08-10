//
//  SettingsViewController.swift
//  Rhyme a Zoo
//
//  Created by Cal on 8/3/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import Foundation
import UIKit
import MessageUI

let RZSetTouchDelegateEnabledNotification = "com.hearatale.raz.settingsTouchDelegateEnabled"

class SettingsViewController : UIViewController, SettingsViewTableDelegate, UIGestureRecognizerDelegate {
    
    var classroom: Classroom!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet var touchRecognizer: UITouchGestureRecognizer!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewWillAppear(animated: Bool) {
        tableView.contentInset = UIEdgeInsets(top: 70.0, left: 0.0, bottom: 0.0, right: 0.0)
        self.observeNotification(RZSetTouchDelegateEnabledNotification, selector: "setTouchRecognizerEnabled:")
        self.view.clipsToBounds = true
        self.view.layer.masksToBounds = true
        tableView.clipsToBounds = false
        tableView.layer.masksToBounds = false
    }
    
    func getTitle() -> String {
        return "Manage your Classroom"
    }
    
    func getBackButtonImage() -> UIImage {
        return UIImage(named: "button-home")!
    }
    
    //MARK: - Table View Data Source
    
    enum CellType {
        case Function(function: ((SettingsViewController) -> ())?)
        case Toggle(setting: ClassroomSetting)
        case Title
        
        func getFunction() -> ((SettingsViewController) -> ())? {
            switch self {
                case .Function(let function):
                    return function
                default: return nil
            }
        }
        
        func getSetting() -> ClassroomSetting? {
            switch self {
                case .Toggle(let setting):
                    return setting
                default:
                    return nil
            }
        }
    }
    
    let cells: [(identifier: String, type: CellType)] = [
        ("students", .Function(function: { controller in
            controller.showUsers()
        })),
        ("toggle", .Toggle(setting: RZSettingRequirePasscode)),
        ("toggle", .Toggle(setting: RZSettingUserCreation)),
        ("toggle", .Toggle(setting: RZSettingPhoneticsOnly)),
        ("toggle", .Toggle(setting: RZSettingSkipVideos)),
        ("passcode", .Function(function: { controller in
            controller.changePasscode()
        })),
        ("leave", .Function(function: { controller in
            controller.removeDeviceFromClassroom()
        })),
        ("delete", .Function(function: { controller in
            controller.deleteClassroom()
        }))
    ]
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let index = indexPath.item
        let cell = cells[index]
        
        if cell.identifier == "students" {
            let row = tableView.dequeueReusableCellWithIdentifier(cell.identifier, forIndexPath: indexPath) as! StudentsCell
            RZUserDatabase.getUsersForClassroom(classroom, completion: { users in
                row.decorateForUsers(users)
            })
            row.backgroundColor = UIColor.clearColor()
            return row
        }
        
        if cell.identifier == "toggle" {
            let row = tableView.dequeueReusableCellWithIdentifier(cell.identifier, forIndexPath: indexPath) as! ToggleCell
            if let setting = cell.type.getSetting() {
                row.decorateForSetting(setting)
            }
            return row
        }
        
        let row = tableView.dequeueReusableCellWithIdentifier(cell.identifier, forIndexPath: indexPath) as! UITableViewCell
        row.backgroundColor = UIColor.clearColor()
        return row
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let cell = cells[indexPath.item]
        if cell.identifier == "students" {
            return 75.0
        }
        return 50.0
    }
    
    //MARK: - User Interaction
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @IBAction func touchRecognized(sender: UITouchGestureRecognizer) {
        if sender.state == .Ended {
            animateSelection(nil)
        }
        
        for cell in tableView.visibleCells() as! [UITableViewCell] {
            let touch = sender.locationInView(cell.superview!)
            if cell.frame.contains(touch) {
                
                let index = tableView.indexPathForCell(cell)!.item
                let cell = cells[index]
                let delegate = tableView.delegate as? SettingsViewTableDelegate
                
                if sender.state == .Ended {
                    delegate?.processSelectedCell(index)
                }
                else {
                    if delegate?.canHighlightCell(index) == true {
                        animateSelection(index)
                    }
                }
            }
        }
    }
    
    func processSelectedCell(index: Int) {
        let cell = cells[index]
        //call function for cell
        if let function = cell.type.getFunction() {
            function(self)
        }
    }
    
    func canHighlightCell(index: Int) -> Bool {
        let cell = cells[index]
        return cell.type.getFunction() != nil
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        postNotification(RZSetTouchDelegateEnabledNotification, false)
        delay(0.5) {
            postNotification(RZSetTouchDelegateEnabledNotification, true)
        }
    }
    
    func setTouchRecognizerEnabled(notification: NSNotification) {
        if let enabled = notification.object as? Bool {
            touchRecognizer.enabled = enabled
            if enabled == false {
                animateSelection(nil)
            }
        }
    }
    
    func animateSelection(index: Int?) {
        for cell in tableView.visibleCells() as! [UITableViewCell] {
            
            if let indexPath = tableView.indexPathForCell(cell) where indexPath.item == index && touchRecognizer.enabled {
                UIView.animateWithDuration(0.15) {
                    cell.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
                }
            }
            else {
                UIView.animateWithDuration(0.15) {
                    cell.backgroundColor = UIColor(white: 1.0, alpha: 0.0)
                }
            }
            
        }
    }
    
    //MARK: - Functions for Table View Cells
    
    func changePasscode() {
        createPasscode("Create a new 4-Digit passcode for \"\(classroom.name)\"", currentController: self, { newPasscode in
            
            if let newPasscode = newPasscode {
                self.classroom.passcode = newPasscode
                RZUserDatabase.saveClassroom(self.classroom)
                let alert = UIAlertController(title: "Passcode Changed", message: nil, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
            
        })
    }
    
    func removeDeviceFromClassroom() {
        
        //prompt with alert
        let alert = UIAlertController(title: "Remove this device from your classroom?", message: "You can rejoin at any time.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Nevermind", style: .Default, handler: nil))
        alert.addAction(UIAlertAction(title: "Leave", style: .Destructive, handler: { _ in
        
            let classroomName = self.classroom.name
            RZUserDatabase.unlinkClassroom()
            
            //give the server a sec to catch up
            //show alert then dismiss
            let alert = UIAlertController(title: "Removing this device from \"\(classroomName)\"", message: "", preferredStyle: .Alert)
            self.presentViewController(alert, animated: true, completion: nil)
            delay(3.0) {
                self.dismissViewControllerAnimated(true, completion: {
                    self.dismissViewControllerAnimated(true, completion: nil)
                })
            }
        
        }))
        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    
    
    func deleteClassroom() {
        
        //prompt with alert
        let alert = UIAlertController(title: "Are you sure you want to delete \"\(classroom.name)\"", message: "This cannot be undone. All user progress will be lost forever.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Nevermind", style: .Default, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: { _ in
            
            requestPasscode(self.classroom.passcode, "Verify passcode to delete Classroom.", currentController: self, completion: {
                let classroomName = self.classroom.name
                RZUserDatabase.deleteClassroom(self.classroom)
                RZUserDatabase.unlinkClassroom()
                
                //give the server a sec to catch up
                //show alert then dismiss
                let alert = UIAlertController(title: "Deleting \"\(classroomName)\"", message: "", preferredStyle: .Alert)
                self.presentViewController(alert, animated: true, completion: nil)
                delay(3.0) {
                    self.dismissViewControllerAnimated(true, completion: {
                        self.dismissViewControllerAnimated(true, completion: nil)
                    })
                }
            })
        
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    
    func showUsers() {
        let delegate = SettingsUsersDelegate(self)
        switchToDelegate(delegate, isBack: false)
        self.activityIndicator.hidden = false
        RZUserDatabase.getUsersForClassroom(self.classroom, completion: { users in
            delay(0.3) {
                delegate.users = users
                self.activityIndicator.hidden = true
            }
        })
    }
    
    //MARK: - Handling Delegate changes
    
    var delegateStack: Stack<SettingsViewTableDelegate> = Stack()
    var currentDelegate: SettingsViewTableDelegate!
    
    @IBAction func backButtonPressed(sender: AnyObject) {
        if let newDelegate = delegateStack.pop() {
            switchToDelegate(newDelegate, isBack: true)
        }
        else {
            //already on the last delegate
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func switchToDelegate(delegate: SettingsViewTableDelegate, isBack: Bool) {
        self.activityIndicator.hidden = true
        if let currentDelegate = tableView.delegate as? SettingsViewTableDelegate where !isBack {
            delegateStack.push(currentDelegate)
        }
        currentDelegate = delegate //store a strong reference of the delegate
        tableView.delegate = delegate
        tableView.dataSource = delegate
        tableView.reloadData()
        let subtype = isBack ? kCATransitionFromLeft : kCATransitionFromRight
        playTransitionForView(tableView, duration: 0.3, transition: kCATransitionPush, subtype: subtype)
        
        //change title
        let newTitle = delegate.getTitle()
        titleLabel.text = newTitle
        playTransitionForView(titleLabel, duration: 0.3, transition: kCATransitionPush, subtype: subtype)
        
        //change button
        let image = delegate.getBackButtonImage()
        backButton.setImage(image, forState: .Normal)
        playTransitionForView(backButton, duration: 0.3, transition: kCATransitionFade)
    }
    
}

//MARK: - Delegates for different screens

protocol SettingsViewTableDelegate : UITableViewDelegate, UITableViewDataSource {
    
    func processSelectedCell(index: Int)
    func canHighlightCell(index: Int) -> Bool
    func getTitle() -> String
    func getBackButtonImage() -> UIImage
    
}

//MARK: Delegate for showing a list of users

class SettingsUsersDelegate : NSObject, SettingsViewTableDelegate, MFMailComposeViewControllerDelegate {
    
    var tableView: UITableView
    var settingsController: SettingsViewController
    var users: [User] = [] {
        didSet {
            tableView.reloadData()
            playTransitionForView(tableView, duration: 0.2, transition: kCATransitionFade)
        }
    }
    var passcodesRequired: Bool
    var showEmailCell: Bool {
        return passcodesRequired && users.count != 0
    }
    
    init(_ settingsController: SettingsViewController) {
        self.settingsController = settingsController
        self.tableView = settingsController.tableView
        passcodesRequired = RZSettingRequirePasscode.currentSetting() == true
    }
    
    func getTitle() -> String {
        return "Students"
    }
    
    func getBackButtonImage() -> UIImage {
        return UIImage(named: "button-back")!
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count + (showEmailCell ? 2 : 1)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var index = indexPath.item
        if index == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("newUser", forIndexPath: indexPath) as! UITableViewCell
            cell.backgroundColor = UIColor.clearColor()
            return cell
        }
        if index == 1 && showEmailCell {
            let cell = tableView.dequeueReusableCellWithIdentifier("passcodeEmail", forIndexPath: indexPath) as! UITableViewCell
            cell.backgroundColor = UIColor.clearColor()
            return cell
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier("user", forIndexPath: indexPath) as! UserNameCell
        cell.decorateForUser(users[index - (showEmailCell ? 2 : 1)])
        cell.backgroundColor = UIColor.clearColor()
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return indexPath.item == 0 ? 75.0 : 50.0
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        postNotification(RZSetTouchDelegateEnabledNotification, false)
        delay(0.5) {
            postNotification(RZSetTouchDelegateEnabledNotification, true)
        }
    }
    
    func processSelectedCell(index: Int) {
        if index == 0 {
            startNewStudentFlow()
        }
        else if index == 1 && showEmailCell {
            sendPasscodeEmail()
        }
        else {
            let user = users[index - (showEmailCell ? 2 : 1)]
        }
    }
    
    func canHighlightCell(index: Int) -> Bool {
        return true
    }
    
    //MARK: Adding New Students
    
    func startNewStudentFlow(message: String? = nil) {
        //show name alert
        let alert = UIAlertController(title: "Add New Student", message: nil, preferredStyle: .Alert)
        var textField: UITextField?
        alert.addTextFieldWithConfigurationHandler() { field in
            field.placeholder = "Type the student's name."
            field.autocapitalizationType = .Words
            field.autocorrectionType = .No
            textField = field
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
        alert.addAction(UIAlertAction(title: "Done", style: .Default, handler: { _ in
            
            if let name = textField?.text where count(name) > 0 {
                //pick a random icon name
                var icons = RZUserIconOptions.shuffled()
                updateAvailableIconsForUsers(self.users, &icons)
                let icon = icons[0] + ".jpg"
                self.getPasscodeForNewStudentFlow(name, iconName: icon)
            }
            else {
                self.startNewStudentFlow(message: "You must type a name.")
            }
            
        }))
        
        settingsController.presentViewController(alert, animated: true, completion: nil)
    }
    
    func getPasscodeForNewStudentFlow(name: String, iconName: String) {
        if RZSettingRequirePasscode.currentSetting() == true {
            let alert = UIAlertController(title: "Add a Passcode", message: "You have student passcodes enabled.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Random", style: .Default, handler: { _ in
                //generate a 4-digit passcode
                var passcode: String = ""
                for _ in 1...4 {
                    let digit = "\(arc4random_uniform(9))"
                    passcode = passcode + digit
                }
                 self.finishNewStudentFlow(name, iconName: iconName, passcode: passcode)
            }))
            
            alert.addAction(UIAlertAction(title: "Custom", style: UIAlertActionStyle.Default, handler: { _ in
                //show password dialog
                createPasscode("Create a custom 4-digit passcode for \(name)", currentController: self.settingsController, { passcode in
                    if let passcode = passcode {
                        self.finishNewStudentFlow(name, iconName: iconName, passcode: passcode)
                    } else {
                        self.getPasscodeForNewStudentFlow(name, iconName: iconName)
                    }
                })
            }))
            
            alert.addAction(UIAlertAction(title: "Don't add a Passcode", style: .Destructive, handler: { _ in
                self.finishNewStudentFlow(name, iconName: iconName, passcode: nil)
            }))
            
            settingsController.presentViewController(alert, animated: true, completion: nil)
        }
        else {
            finishNewStudentFlow(name, iconName: iconName, passcode: nil)
        }
    }
    
    func finishNewStudentFlow(name: String, iconName: String, passcode: String?) {
        let user = User(name: name, iconName: iconName, passcode: passcode)
        users.append(user)
        //sort the new array by name again
        let nsusers = users as NSArray
        users = nsusers.sortedArrayUsingDescriptors([NSSortDescriptor(key: "name", ascending: true)]) as! [User]
        tableView.reloadData()
        
        //show an alert
        let message = passcode != nil ? "Passcode: \(passcode!)" : ""
        let alert = UIAlertController(title: "Created \(name)", message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        settingsController.presentViewController(alert, animated: true, completion: nil)
    }
    
    //MARK: Other Interactions
    
    func sendPasscodeEmail() {
        
        if !MFMailComposeViewController.canSendMail() {
            //show an alert to tell the user to set up mail
            let alert = UIAlertController(title: "You haven't set up your email yet.", message: "Set up your email in the Settings App and then try again.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Nevermind", style: .Destructive, handler: nil))
            alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { _ in
                openSettings()
            }))
            return
        }
        
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = self
        mail.setSubject("Rhyme a Zoo: Student Passcodes for \(settingsController.classroom.name)")
        
        //create message body
        var messageBody = ""
        var allUsersHavePasscode = true
        
        for user in users {
            let name = user.name
            var passcode: String! = user.passcode
            if passcode == nil {
                passcode = "No passcode set."
                allUsersHavePasscode = false
            }
            
            let line = "<b>\(name):</b> \(passcode)</br>"
            messageBody = messageBody + line
        }
        
        if !allUsersHavePasscode {
            let line = "</br><i>Not all of your students have passcodes.</br>Anybody with access to your classroom will be able to play on their profile."
            let line2 = "</br>You can give them a passcode by going in to your classroom settings, tapping \"View / Edit Students\", and then tapping their name.</i>"
            messageBody = messageBody + line + line2
        }
        
        mail.setMessageBody(messageBody, isHTML: true)
        
        settingsController.presentViewController(mail, animated: true, completion: {
            //show an alert after presenting the mail controller
            let alert = UIAlertController(title: "Created Email Message of Student Passcodes", message: "Send it to yourself for record keeping, to print on a computer, or to use in a spreadsheet.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .Destructive, handler: { _ in
                mail.dismissViewControllerAnimated(true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            mail.presentViewController(alert, animated: true, completion: nil)
        })
        
        
    }
    
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func showStudentStatistics() {
        
    }
    
}

//MARK: - Custom Cells

class StudentsCell : UITableViewCell {
    
    @IBOutlet weak var label: UILabel!
    var previousUserCount = 0
    
    func decorateForUsers(usersArray: [User]) {
        let contentView = label.superview!
        let users = usersArray.reverse() //reverse user array since we draw it backwards
        
        if previousUserCount == users.count { return }
        
        //remove old image views
        for subview in contentView.subviews {
            if let imageView = subview as? UIImageView {
                imageView.removeFromSuperview()
            }
        }
        
        //add new image views
        let endX = label.frame.origin.x + label.frame.width
        let height = label.frame.height * 1.3
        let size = CGSizeMake(height, height)
        let y = CGRectGetMidY(label.frame) - height / 2
        
        var currentX = contentView.frame.width - size.width
        var currentUser = 0
        
        while currentX > endX && currentUser < users.count {
            let origin = CGPointMake(currentX, y)
            let image = UIImageView(image: users[currentUser].icon)
            image.frame = CGRect(origin: origin, size: size)
            decorateUserIcon(image)
            contentView.addSubview(image)
            downsampleImageInView(image)
            
            image.alpha = 0.0
            UIView.animateWithDuration(0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: nil, animations: {
                image.alpha = 1.0
            }, completion: nil)
            
            currentX -= size.width + 5.0
            currentUser++
        }
        
        previousUserCount = users.count
    }
    
}

class ToggleCell : UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var toggleSwitch: UISwitch!
    
    var setting: ClassroomSetting?
    
    func decorateForSetting(setting: ClassroomSetting) {
        self.setting = setting
        self.backgroundColor = UIColor.clearColor()
        
        nameLabel.text = setting.name
        descriptionLabel.text = setting.description
        if let current = setting.currentSetting() {
            toggleSwitch.on = current
        }
    }
    
    @IBAction func switchToggled(sender: UISwitch) {
        setting?.updateSetting(sender.on)
    }
    
}

class UserNameCell : UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var passcodeLabel: UILabel!
    
    func decorateForUser(user: User) {
        nameLabel.text = user.name
        icon.image = user.icon
        decorateUserIcon(icon)
        downsampleImageInView(icon)
        
        if let passcode = user.passcode where RZSettingRequirePasscode.currentSetting() == true {
            passcodeLabel.text = "passcode: \(passcode)"
            passcodeLabel.textColor = UIColor.whiteColor()
            passcodeLabel.alpha = 0.5
        } else {
            passcodeLabel.text = "no passcode set"
            passcodeLabel.textColor = UIColor.redColor()
            passcodeLabel.alpha = 0.4
        }
    }
    
}





