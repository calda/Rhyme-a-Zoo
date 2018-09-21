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
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.contentInset = UIEdgeInsets(top: 70.0, left: 0.0, bottom: 0.0, right: 0.0)
        self.observeNotification(RZSetTouchDelegateEnabledNotification, selector: #selector(SettingsViewController.setTouchRecognizerEnabled(_:)))
        self.view.clipsToBounds = true
        self.view.layer.masksToBounds = true
        tableView.clipsToBounds = false
        tableView.layer.masksToBounds = false
        SettingsUserStatisticsDelegate.settingsControllerStatic = self
    }
    
    func getTitle() -> String {
        return "Manage your Classroom"
    }
    
    func getBackButtonImage() -> UIImage {
        return UIImage(named: "button-home")!
    }
    
    //MARK: - Table View Data Source
    
    enum CellType {
        case function(function: ((SettingsViewController) -> ())?)
        case toggle(setting: ClassroomSetting)
        case title
        
        func getFunction() -> ((SettingsViewController) -> ())? {
            switch self {
                case .function(let function):
                    return function
                default: return nil
            }
        }
        
        func getSetting() -> ClassroomSetting? {
            switch self {
                case .toggle(let setting):
                    return setting
                default:
                    return nil
            }
        }
    }
    
    let cells: [(identifier: String, type: CellType)] = [
        ("students", .function(function: { controller in
            controller.showUsers()
        })),
        ("toggle", .toggle(setting: RZSettingRequirePasscode)),
        ("toggle", .toggle(setting: RZSettingUserCreation)),
        ("toggle", .toggle(setting: RZSettingSkipVideos)),
        ("passcode", .function(function: { controller in
            controller.changePasscode()
        })),
        ("leave", .function(function: { controller in
            controller.removeDeviceFromClassroom()
        })),
        ("delete", .function(function: { controller in
            controller.deleteClassroom()
        }))
    ]
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = indexPath.item
        let cell = cells[index]
        
        if cell.identifier == "students" {
            let row = tableView.dequeueReusableCell(withIdentifier: cell.identifier, for: indexPath) as! StudentsCell
            RZUserDatabase.getUsersForClassroom(classroom, completion: { users in
                guard let users = users else { return }
                row.decorateForUsers(users)
            })
            row.backgroundColor = UIColor.clear
            return row
        }
        
        if cell.identifier == "toggle" {
            let row = tableView.dequeueReusableCell(withIdentifier: cell.identifier, for: indexPath) as! ToggleCell
            if let setting = cell.type.getSetting() {
                row.decorateForSetting(setting)
            }
            return row
        }
        
        let row = tableView.dequeueReusableCell(withIdentifier: cell.identifier, for: indexPath) 
        row.backgroundColor = UIColor.clear
        return row
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cell = cells[indexPath.item]
        if cell.identifier == "students" {
            return 75.0
        }
        return 50.0
    }
    
    //MARK: - User Interaction
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @IBAction func touchRecognized(_ sender: UITouchGestureRecognizer) {
        if sender.state == .ended {
            animateSelection(nil)
        }
        
        for cell in tableView.visibleCells {
            let touch = sender.location(in: cell.superview!)
            if cell.frame.contains(touch) {
                
                if let index = tableView.indexPath(for: cell)?.item {
                    let delegate = tableView.delegate as? SettingsViewTableDelegate
                    
                    if sender.state == .ended {
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
    }
    
    func processSelectedCell(_ index: Int) {
        let cell = cells[index]
        //call function for cell
        if let function = cell.type.getFunction() {
            function(self)
        }
    }
    
    func canHighlightCell(_ index: Int) -> Bool {
        let cell = cells[index]
        return cell.type.getFunction() != nil
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        postNotification(RZSetTouchDelegateEnabledNotification, object: NSNumber(value: false))
        delay(0.5) {
            postNotification(RZSetTouchDelegateEnabledNotification, object: NSNumber(value: true))
        }
    }
    
    @objc func setTouchRecognizerEnabled(_ notification: Notification) {
        if let enabled = notification.object as? NSNumber {
            touchRecognizer.isEnabled = enabled.boolValue
            if enabled.boolValue == false {
                animateSelection(nil)
            }
        }
    }
    
    func animateSelection(_ index: Int?) {
        for cell in tableView.visibleCells {
            
            if let indexPath = tableView.indexPath(for: cell), indexPath.item == index && touchRecognizer.isEnabled {
                UIView.animate(withDuration: 0.15, animations: {
                    cell.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
                }) 
            }
            else {
                UIView.animate(withDuration: 0.15, animations: {
                    cell.backgroundColor = UIColor(white: 1.0, alpha: 0.0)
                }) 
            }
            
        }
    }
    
    //MARK: - Functions for Table View Cells
    
    func changePasscode() {
        createPasscode("Create a new 4-Digit passcode for \"\(classroom.name)\"", currentController: self, completion: { newPasscode in
            
            if let newPasscode = newPasscode {
                self.classroom.passcode = newPasscode
                RZUserDatabase.saveClassroom(self.classroom)
                let alert = UIAlertController(title: "Passcode Changed", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            
        })
    }
    
    func removeDeviceFromClassroom() {
        
        //prompt with alert
        let alert = UIAlertController(title: "Remove this device from your classroom?", message: "You can rejoin at any time.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Nevermind", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Leave", style: .destructive, handler: { _ in
        
            let classroomName = self.classroom.name
            RZUserDatabase.unlinkClassroom()
            
            //give the server a sec to catch up
            //show alert then dismiss
            let alert = UIAlertController(title: "Removing this device from \"\(classroomName)\"", message: "", preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
            delay(3.0) {
                self.dismiss(animated: true, completion: {
                    self.dismiss(animated: true, completion: nil)
                })
            }
        
        }))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    
    func deleteClassroom() {
        
        //prompt with alert
        let alert = UIAlertController(title: "Are you sure you want to delete \"\(classroom.name)\"", message: "This cannot be undone. All user progress will be lost forever.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Nevermind", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            
            requestPasscode(self.classroom.passcode, description: "Verify passcode to delete Classroom.", currentController: self, completion: { success in
                guard success else { return }
                
                let classroomName = self.classroom.name
                RZUserDatabase.deleteClassroom(self.classroom)
                RZUserDatabase.unlinkClassroom()
                
                //give the server a sec to catch up
                //show alert then dismiss
                let alert = UIAlertController(title: "Deleting \"\(classroomName)\"", message: "", preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
                delay(3.0) {
                    self.dismiss(animated: true, completion: {
                        self.dismiss(animated: true, completion: nil)
                    })
                }
            })
        
        }))
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func showUsers() {
        let delegate = SettingsUsersDelegate(self)
        switchToDelegate(delegate, isBack: false, atOffset: nil)
        self.activityIndicator.isHidden = false
        RZUserDatabase.getUsersForClassroom(self.classroom, completion: { users in
            guard let users = users else { return }
            
            delay(0.3) {
                delegate.users = users
                self.activityIndicator.isHidden = true
            }
        })
    }
    
    //MARK: - Handling Delegate changes
    
    var delegateStack: Stack<(delegate: SettingsViewTableDelegate, contentOffset: CGPoint)> = Stack()
    var currentDelegate: SettingsViewTableDelegate!
    
    @IBAction func backButtonPressed(_ sender: AnyObject) {
        if let (newDelegate, offset) = delegateStack.pop() {
            switchToDelegate(newDelegate, isBack: true, atOffset: offset)
        }
        else if sender is UIButton {
            //already on the last delegate
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func switchToDelegate(_ delegate: SettingsViewTableDelegate, isBack: Bool, atOffset offset: CGPoint?) {
        self.activityIndicator.isHidden = true
        if let currentDelegate = tableView.delegate as? SettingsViewTableDelegate, !isBack {
            let delegateInfo = (delegate: currentDelegate, contentOffset: self.tableView.contentOffset)
            delegateStack.push(delegateInfo)
        }
        currentDelegate = delegate //store a strong reference of the delegate
        tableView.delegate = delegate
        tableView.dataSource = delegate
        tableView.reloadData()
        let subtype = isBack ? convertFromCATransitionSubtype(.fromLeft) : convertFromCATransitionSubtype(.fromRight)
        playTransitionForView(tableView, duration: 0.3, transition: convertFromCATransitionType(.push), subtype: subtype)
        
        //change title
        let newTitle = delegate.getTitle()
        titleLabel.text = newTitle
        playTransitionForView(titleLabel, duration: 0.3, transition: convertFromCATransitionType(.push), subtype: subtype)
        
        //change button
        let image = delegate.getBackButtonImage()
        backButton.setImage(image, for: .normal)
        self.tableView.contentOffset = offset ?? CGPoint(x: 0.0, y: -70.0)
        playTransitionForView(backButton, duration: 0.3, transition: convertFromCATransitionType(.fade))
    }
    
}

//MARK: - Delegates for different screens

protocol SettingsViewTableDelegate : UITableViewDelegate, UITableViewDataSource {
    
    func processSelectedCell(_ index: Int)
    func canHighlightCell(_ index: Int) -> Bool
    func getTitle() -> String
    func getBackButtonImage() -> UIImage
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    
}

//MARK: - Delegate for showing a list of users

class SettingsUsersDelegate : NSObject, SettingsViewTableDelegate, MFMailComposeViewControllerDelegate {
    
    var tableView: UITableView
    var settingsController: SettingsViewController
    var users: [User] = [] {
        didSet {
            tableView.reloadData()
            playTransitionForView(tableView, duration: 0.2, transition: convertFromCATransitionType(.fade))
        }
    }
    var passcodesRequired: Bool
    var showCustomEmailCell: Bool {
        return users.count != 0
    }
    var showPasscodeEmailCell: Bool {
        return passcodesRequired && users.count != 0
    }
    var additionalCells: Int {
        return 1 + (showCustomEmailCell ? 1 : 0) + (showPasscodeEmailCell ? 1 : 0)
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
    
    //MARK: Table View Data Source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count + additionalCells
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = indexPath.item
        if index == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "newUser", for: indexPath) 
            cell.backgroundColor = UIColor.clear
            return cell
        }
        if index == 1 && showCustomEmailCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "dataEmail", for: indexPath) 
            cell.backgroundColor = UIColor.clear
            return cell
        }
        if index == 2 && showPasscodeEmailCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "passcodeEmail", for: indexPath) 
            cell.backgroundColor = UIColor.clear
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "user", for: indexPath) as! UserNameCell
        cell.decorateForUser(users[index - additionalCells])
        cell.backgroundColor = UIColor.clear
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.item == 0 ? 75.0 : 50.0
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        postNotification(RZSetTouchDelegateEnabledNotification, object: NSNumber(value: false))
        delay(0.5) {
            postNotification(RZSetTouchDelegateEnabledNotification, object: NSNumber(value: true))
        }
    }
    
    func processSelectedCell(_ index: Int) {
        if index == 0 {
            startNewStudentFlow()
        }
        else if index == 1 && showCustomEmailCell {
            //switch to the email creation delegate
            let newDelegate = SettingsComposeEmailDelegate(users: self.users, settingsController: settingsController)
            settingsController.switchToDelegate(newDelegate, isBack: false, atOffset: nil)
        }
        else if index == 2 && showPasscodeEmailCell {
            sendPasscodeEmail()
        }
        else {
            let user = users[index - additionalCells]
            showStudentStatistics(user)
        }
    }
    
    func canHighlightCell(_ index: Int) -> Bool {
        return true
    }
    
    //MARK: Adding New Students
    
    func startNewStudentFlow(_ message: String? = nil) {
        //show name alert
        let alert = UIAlertController(title: "Add New Student", message: nil, preferredStyle: .alert)
        var textField: UITextField?
        alert.addTextField() { field in
            field.placeholder = "Type the student's name."
            field.autocapitalizationType = .words
            field.autocorrectionType = .no
            textField = field
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Done", style: .default, handler: { _ in
            
            if let name = textField?.text, name.count > 0 {
                //pick a random icon name
                var icons = RZUserIconOptions.shuffled()
                updateAvailableIconsForUsers(self.users, availableIcons: &icons)
                let icon = icons[0] + ".jpg"
                self.getPasscodeForNewStudentFlow(name, iconName: icon)
            }
            else {
                self.startNewStudentFlow("You must type a name.")
            }
            
        }))
        
        settingsController.present(alert, animated: true, completion: nil)
    }
    
    func getPasscodeForNewStudentFlow(_ name: String, iconName: String) {
        if RZSettingRequirePasscode.currentSetting() == true {
            let alert = UIAlertController(title: "Add a Passcode", message: "To keep your student's profile safe, please choose an option to assign them a passcode.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Random", style: .default, handler: { _ in
                //generate a 4-digit passcode
                var passcode: String = ""
                for _ in 1...4 {
                    let digit = "\(arc4random_uniform(9))"
                    passcode = passcode + digit
                }
                 self.finishNewStudentFlow(name, iconName: iconName, passcode: passcode)
            }))
            
            alert.addAction(UIAlertAction(title: "Custom", style: UIAlertAction.Style.default, handler: { _ in
                //show password dialog
                createPasscode("Create a custom 4-digit passcode for \(name)", currentController: self.settingsController, completion: { passcode in
                    if let passcode = passcode {
                        self.finishNewStudentFlow(name, iconName: iconName, passcode: passcode)
                    } else {
                        self.getPasscodeForNewStudentFlow(name, iconName: iconName)
                    }
                })
            }))
            
            alert.addAction(UIAlertAction(title: "Don't add a Passcode", style: .destructive, handler: { _ in
                self.finishNewStudentFlow(name, iconName: iconName, passcode: nil)
            }))
            
            settingsController.present(alert, animated: true, completion: nil)
        }
        else {
            finishNewStudentFlow(name, iconName: iconName, passcode: nil)
        }
    }
    
    func finishNewStudentFlow(_ name: String, iconName: String, passcode: String?) {
        let user = User(name: name, iconName: iconName, passcode: passcode)
        users.append(user)
        users.sort(by: { $0.name < $1.name })
        tableView.reloadData()
        
        //show an alert
        let message = passcode != nil ? "Passcode: \(passcode!)" : ""
        let alert = UIAlertController(title: "Created \(name)", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        settingsController.present(alert, animated: true, completion: nil)
    }
    
    //MARK: Other Interactions
    
    func sendPasscodeEmail() {
        //create message body
        var messageBody = ""
        var allUsersHavePasscode = true
        
        for user in users {
            let name = user.name
            let passcode = user.passcode ?? "No passcode set."
            if user.passcode == nil {
                allUsersHavePasscode = false
            }
            
            let line = "<b>\(name):&nbsp;</b> \(passcode)</br>"
            messageBody = messageBody + line
        }
        
        if !allUsersHavePasscode {
            let line = "</br><i>Not all of your students have passcodes.</br>Anybody with access to your classroom will be able to play on their profile."
            let line2 = "</br>You can give them a passcode by going in to your classroom settings, tapping \"View All Students\", and then tapping their name.</i>"
            messageBody = messageBody + line + line2
        }
        
        EmailManager.sendCustomEmail(
            subject: "Rhyme a Zoo: Student Passcodes for \(settingsController.classroom.name)",
            body: messageBody,
            from: settingsController)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func showStudentStatistics(_ user: User) {
        let newDelegate = SettingsUserStatisticsDelegate(user: user, settingsController: settingsController)
        settingsController.switchToDelegate(newDelegate, isBack: false, atOffset: nil)
    }
    
}

//MARK: - Delegate for showing User Statistics

class SettingsUserStatisticsDelegate : NSObject, SettingsViewTableDelegate {
    
    let user: User
    let settingsController: SettingsViewController
    static var settingsControllerStatic: SettingsViewController? = nil
    
    init(user: User, settingsController: SettingsViewController) {
        self.user = user
        user.pullDataFromCloud()
        self.settingsController = settingsController
        SettingsUserStatisticsDelegate.settingsControllerStatic = settingsController
    }
    
    func getTitle() -> String {
        return "Statistics: \(user.name)"
    }
    
    func getBackButtonImage() -> UIImage {
        return UIImage(named: "button-back")!
    }
    
    //MARK: Table View Data Source
    
    static var cells: [(identifier: String, decorate: ((UITableViewCell, User) -> ())?, tap: ((User, SettingsViewController) -> ())?)] = [
        
        //MARK: User Name and Icon
        (identifier: "bigUser", decorate: { cell, user in
            if let cell = cell as? BigUserCell, let settingsController = SettingsUserStatisticsDelegate.settingsControllerStatic {
                cell.decorateForUser(user, controller: settingsController)
            }
        }, tap: nil),
        
        //MARK: Passcode
        (identifier: "userInfo", decorate: { cell, user in
            if let cell = cell as? UserInfoCell {
                cell.setTitle("Passcode:")
                cell.setItem(user.passcode ?? "Not set")
                cell.setIndent(0)
                
                if user.passcode == nil && RZSettingRequirePasscode.currentSetting() == true {
                    cell.itemLabel.textColor = UIColor.red
                    cell.itemLabel.alpha = 0.4
                }
            }
        }, tap: nil),
        
        //MARK: Change / Create Passcode
        (identifier: "userInfo", decorate: { cell, user in
            if let cell = cell as? UserInfoCell {
                cell.setTitle(user.passcode == nil ? "Create Passcode" : "Change Passcode")
                if RZSettingRequirePasscode.currentSetting() == false {
                    cell.setItem("(Passcodes are disabled)")
                } else {
                    cell.setItem(nil)
                }
                cell.setIndent(1)
                cell.setHasFunction(true)
            }
            }, tap: { user, settingsController in
                let new = user.passcode != nil ? " new " : " "
                createPasscode("Create a\(new)4-digit Passcode for \(user.name)", currentController: settingsController, completion: { passcode in
                    if let passcode = passcode {
                        user.passcode = passcode
                        RZUserDatabase.saveUserToLinkedClassroom(user)
                        settingsController.tableView.reloadData()
                    }
                })
        }),
        
        (identifier: "blank", decorate: { cell, user in cell.hideSeparator() }, tap: nil),
        
        //MARK: Most Recent Activity
        (identifier: "userInfo", decorate: { cell, user in
            if let cell = cell as? UserInfoCell {
                cell.setTitle("Last played ")
                cell.setIndent(0)
                
                if let date = user.dateLastModified() {
                    
                    let deltaTime = -date.timeIntervalSinceNow
                    
                    if deltaTime < 3600 { //less than an hour
                        let amount = Int(deltaTime/60.0)
                        let plural = amount == 1 ? "" : "s"
                        cell.setItem("\(amount) minute\(plural) ago")
                    }
                    else if deltaTime < 86400 { //less than a day
                        let amount = Int(deltaTime/3600.0)
                        let plural = amount == 1 ? "" : "s"
                        cell.setItem("\(amount) hour\(plural) ago")
                    }
                    else if deltaTime < 432000 { //less than five days
                        let amount = Int(deltaTime/86400.0)
                        let plural = amount == 1 ? "" : "s"
                        cell.setItem("\(amount) day\(plural) ago")
                    }
                    else {
                        cell.setTitle("Last played ")
                        let dateString = DateFormatter.localizedString(from: date as Date, dateStyle: .medium, timeStyle: .none)
                        cell.setItem(dateString)
                    }
                } else {
                    cell.setItem("(No recent activity)")
                }
            }
        }, tap: nil),
        
        //MARK: Most Recent Rhyme
        (identifier: "userInfo", decorate: { cell, user in
            if let cell = cell as? UserInfoCell {
                cell.setTitle("Most Recent Quiz:")
                cell.setItem("No recent activity")
                cell.setIndent(0)
                
                if let recent = user.findHighestCompletedRhyme() {
                    let index = RZQuizDatabase.getIndexForRhyme(recent)
                    cell.setItem("\(recent.name) (#\(index + 1))")
                }
            }
        }, tap: nil),
        
        //MARK: Score for Most Recent
        (identifier: "userInfo", decorate: { cell, user in
            if let cell = cell as? UserInfoCell {
                cell.setTitle("Score:")
                cell.setItem("Unknown")
                cell.setIndent(1)
                
                if let recent = user.findHighestCompletedRhyme() {
                    user.useQuizDatabase() {
                        let quizData = RZQuizDatabase.getQuizData()
                        if let score = quizData[recent.number.threeCharacterString] {
                            let splits = score.split{ $0 == ":" }
                            if let gold = Int(splits[0]), let silver = Int(splits[1]) {
                                let goldPlural = gold == 1 ? "" : "s"
                                let silverPlural = silver == 1 ? "" : "s"
                                cell.setItem("\(gold) gold coin\(goldPlural) and \(silver) silver coin\(silverPlural)")
                            } else {
                                cell.setItem(score)
                            }
                        }
                    }
                }
            }
        }, tap: nil),
        
        //MARK: Show All Scores
        (identifier: "userInfo", decorate: { cell, user in
            if let cell = cell as? UserInfoCell {
                cell.setTitle("Show All Scores")
                cell.setItem(nil)
                cell.setIndent(1)
                cell.setHasFunction(true)
            }
        }, tap: { user, settingsController in
            
            //switch to All Quiz Scores delegate
            let newDelegate = SettingsQuizScoresDelegate(user: user, settingsController: settingsController)
            settingsController.switchToDelegate(newDelegate, isBack: false, atOffset: nil)
            
        }),
        
        (identifier: "blank", decorate: { cell, user in cell.hideSeparator() }, tap: nil),
        
        //MARK: Quizes Played
        (identifier: "userInfo", decorate: { cell, user in
            if let cell = cell as? UserInfoCell {
                cell.setTitle("Quizzes Played:")
                cell.setItem("0")
                cell.setIndent(0)
                
                user.useQuizDatabase() {
                    let quizData = RZQuizDatabase.getQuizData()
                    cell.setItem("\(quizData.count)")
                }
            }
        }, tap: nil),
        
        //MARK: Questions Answered
        (identifier: "userInfo", decorate: { cell, user in
            if let cell = cell as? UserInfoCell {
                cell.setTitle("Questions Answered:")
                cell.setItem("0")
                cell.setIndent(1)
                
                user.useQuizDatabase() {
                    //"totalPhonetic" : "totalComprehension"
                    //"correctPhonetic" : "correctComprehension"
                    let questionDict = RZQuizDatabase.getPercentCorrectDict()
                    if let phonetic = questionDict["totalPhonetic"], let comp = questionDict["totalComprehension"] {
                        cell.setItem("\(phonetic + comp)")
                    }
                }
            }
        }, tap: nil),
        
        //MARK: Percent Correct
        (identifier: "userInfo", decorate: { cell, user in
            if let cell = cell as? UserInfoCell {
                cell.setTitle("Percent Correct On First Try:")
                cell.setItem("0%")
                cell.setIndent(1)
                
                user.useQuizDatabase() {
                    let questionDict = RZQuizDatabase.getPercentCorrectDict()
                    if let phonetic = questionDict["totalPhonetic"], let comp = questionDict["totalComprehension"],
                       let phoneticCorrect = questionDict["correctPhonetic"], let compCorrect = questionDict["correctComprehension"] {
                        let totalPlayed = phonetic + comp
                        let totalCorrect = phoneticCorrect + compCorrect
                        let percent = totalPlayed == 0 ? 0 : Int((CGFloat(totalCorrect) / CGFloat(totalPlayed)) * 100.0)
                        cell.setItem("\(percent)% (\(totalCorrect)/\(totalPlayed))")
                    }
                }
            }
        }, tap: nil),
        
        //MARK: Comprehension Percent Correct
        (identifier: "userInfo", decorate: { cell, user in
            if let cell = cell as? UserInfoCell {
                cell.setTitle("Comprehension Questions:")
                cell.setItem("0%")
                cell.setIndent(2)
                
                user.useQuizDatabase() {
                    let questionDict = RZQuizDatabase.getPercentCorrectDict()
                    if let comp = questionDict["totalComprehension"], let compCorrect = questionDict["correctComprehension"] {
                        let percent = comp == 0 ? 0 : Int((CGFloat(compCorrect) / CGFloat(comp)) * 100.0)
                        cell.setItem("\(percent)% (\(compCorrect)/\(comp))")
                    }
                }
            }
        }, tap: nil),
        
        //MARK: Comprehension Percent Correct
        (identifier: "userInfo", decorate: { cell, user in
            if let cell = cell as? UserInfoCell {
                cell.setTitle("Phonetics Questions:")
                cell.setItem("0%")
                cell.setIndent(2)
                
                user.useQuizDatabase() {
                    let questionDict = RZQuizDatabase.getPercentCorrectDict()
                    if let phonetic = questionDict["totalPhonetic"], let phoneticCorrect = questionDict["correctPhonetic"] {
                        let percent = phonetic == 0 ? 0 : Int((CGFloat(phoneticCorrect) / CGFloat(phonetic)) * 100.0)
                        cell.setItem("\(percent)% (\(phoneticCorrect)/\(phonetic))")
                    }
                }
            }
        }, tap: nil),
        
        //MARK: Total Coins Earned
        //MARK: Score for Most Recent
        (identifier: "userInfo", decorate: { cell, user in
            if let cell = cell as? UserInfoCell {
                cell.setTitle("Total Coins Earned:")
                cell.setItem("0 gold coins and 0 silver coins")
                cell.setIndent(1)
                
                if let recent = user.findHighestCompletedRhyme() {
                    user.useQuizDatabase() {
                        let (gold, silver) = RZQuizDatabase.getTotalMoneyEarned()
                        let goldPlural = gold == 1 ? "" : "s"
                        let silverPlural = silver == 1 ? "" : "s"
                        cell.setItem("\(gold) gold coin\(goldPlural) and \(silver) silver coin\(silverPlural)")
                    }
                }
            }
        }, tap: nil),
        
        (identifier: "blank", decorate: { cell, user in cell.hideSeparator() }, tap: nil),
        
        //MARK: Current Zoo Level
        (identifier: "userInfo", decorate: { cell, user in
            if let cell = cell as? UserInfoCell {
                cell.setTitle("Current Zoo Level:")
                cell.setItem("Herbivores (Level 1)")
                cell.setIndent(0)
                
                user.useQuizDatabase() {
                    var zooLevel = RZQuizDatabase.currentZooLevel()
                    if zooLevel == 9 { zooLevel = 8 }
                    let levelNames = ["Herbivores (Level 1)", "Birds (Level 2)", "Aquatic Animals (Level 3)",
                        "Carnivores (Level 4)", "Reptiles (Level 5)", "Primates (Level 6)",
                        "Dinosaurs (Level 7)", "Mythology (Level 8)"]
                    let currentName = levelNames[zooLevel - 1]
                    cell.setItem(currentName)
                }
            }
        }, tap: nil),
        
        //MARK: Current Balance
        (identifier: "userInfo", decorate: { cell, user in
            if let cell = cell as? UserInfoCell {
                cell.setTitle("Current Balance:")
                cell.setItem("0")
                cell.setIndent(1)
                
                user.useQuizDatabase() {
                    let balance = RZQuizDatabase.getPlayerBalance()
                    cell.setItem("\(balance)")
                }
            }
        }, tap: nil),
        
        //MARK: Animals Purchased
        (identifier: "userInfo", decorate: { cell, user in
            if let cell = cell as? UserInfoCell {
                cell.setTitle("Animals Purchased:")
                cell.setItem("0")
                cell.setIndent(1)
                
                user.useQuizDatabase() {
                    let count = RZQuizDatabase.getOwnedAnimals().count
                    cell.setItem("\(count)")
                }
            }
        }, tap: nil)
        
    ]
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SettingsUserStatisticsDelegate.cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellInfo = SettingsUserStatisticsDelegate.cells[indexPath.item]
        let row = tableView.dequeueReusableCell(withIdentifier: cellInfo.identifier, for: indexPath) 
        cellInfo.decorate?(row, self.user)
        row.backgroundColor = UIColor.clear
        return row
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let id = SettingsUserStatisticsDelegate.cells[indexPath.item].identifier
        if id == "bigUser" { return 100.0}
        if id == "blank" { return 30.0 }
        if indexPath.item == 7 { return 60.0 } //Show All Scores. (this is probaly gonna be real error prone)
        return 40.0
    }
    
    func canHighlightCell(_ index: Int) -> Bool {
        return SettingsUserStatisticsDelegate.cells[index].tap != nil
    }
    
    func processSelectedCell(_ index: Int) {
        if let tapFunction = SettingsUserStatisticsDelegate.cells[index].tap {
            tapFunction(user, settingsController)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        postNotification(RZSetTouchDelegateEnabledNotification, object: NSNumber(value: false))
        delay(0.5) {
            postNotification(RZSetTouchDelegateEnabledNotification, object: NSNumber(value: true))
        }
    }
    
}

//MARK: - Delegate for All Quiz Scores

class SettingsQuizScoresDelegate: NSObject, SettingsViewTableDelegate {
    
    let user: User
    let settingsController: SettingsViewController
    let quizData: [(rhymeName: String, score: String)] //actuall processed strings
    
    init(user: User, settingsController: SettingsViewController) {
        self.user = user
        self.settingsController = settingsController
        
        self.quizData = user.useQuizDatabaseToReturn() {
            
            var processedData: [(rhymeName: String, score: String)] = []
            var quizData = RZQuizDatabase.getQuizData()
            
            for quizIndex in 0 ..< RZQuizDatabase.count {
                let quiz = RZQuizDatabase.getRhyme(quizIndex)
                let numberString = quiz.number.threeCharacterString
                if let resultString = quizData[numberString] {
                    //turn result into string
                    let coinString : String
                    
                    let splits = resultString.components(separatedBy: ":")
                    if let gold = Int(splits[0]), let silver = Int(splits[1]) {
                        coinString = "\(gold) gold, \(silver) silver"
                    } else {
                        coinString = resultString
                    }
                    let data = (rhymeName: quiz.name + " (#\(quizIndex))", score: coinString)
                    processedData.append(data)
                    quizData.removeValue(forKey: numberString)
                }
            }
            
            return processedData
        }
        
    }
    
    func getTitle() -> String {
        return "All Quiz Scores: \(user.name)"
    }
    
    func getBackButtonImage() -> UIImage {
        return UIImage(named: "button-back")!
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        postNotification(RZSetTouchDelegateEnabledNotification, object: NSNumber(value: false))
        delay(0.5) {
            postNotification(RZSetTouchDelegateEnabledNotification, object: NSNumber(value: true))
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return quizData.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = indexPath.item
        if index == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "bigUser", for: indexPath) as! BigUserCell
            cell.decorateForUser(self.user, controller: settingsController)
            return cell
        }
        else {
            let (rhymeName, score) = quizData[index - 1]
            let cell = tableView.dequeueReusableCell(withIdentifier: "userInfoRight", for: indexPath) as! UserInfoCell
            cell.setTitle(rhymeName)
            cell.setItem(score)
            cell.setIndent(0)
            cell.makeItemResistCompression()
            cell.backgroundColor = UIColor.clear
            return cell
        }
    }
    
    func canHighlightCell(_ index: Int) -> Bool {
        return false
    }
    
    func processSelectedCell(_ index: Int) {
        return
    }
    
}

//MARK: - Delegate for Composing Data Email

class SettingsComposeEmailDelegate : NSObject, SettingsViewTableDelegate {
    
    let settingsController: SettingsViewController
    let users: [User]
    var cells: [(identifier: String, decorate: ((UITableViewCell, User) -> ())?, selected: Bool)] = [
        //start with blank cell for the top
        (identifier: "blank", decorate: { cell, user in cell.hideSeparator() }, selected: false)
    ]
    
    init(users: [User], settingsController: SettingsViewController) {
        self.users = users
        self.settingsController = settingsController
        
        for (identifier, decorate, tap) in SettingsUserStatisticsDelegate.cells {
            if tap != nil { continue } //ignore cells with functions
            if identifier != "userInfo" && identifier != "blank" { continue }
            cells.append((identifier: identifier == "userInfo" ? "userInfoCheck" : identifier, decorate: decorate, selected: false))
        }
        
        //add another blank at the end
        let blank = cells[0]
        cells.append((identifier: "blank", decorate: blank.decorate, selected: false))
        
    }
    
    func getTitle() -> String {
        return "Customize Email"
    }
    
    func getBackButtonImage() -> UIImage {
        return UIImage(named: "button-back")!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count + 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.item == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "emailHeader", for: indexPath) 
            cell.backgroundColor = UIColor.clear
            return cell
        }
        if indexPath.item == cells.count + 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "sendEmail", for: indexPath) 
            cell.backgroundColor = UIColor.clear
            return cell
        }
        
        let cellInfo = cells[indexPath.item - 1]
        let row = tableView.dequeueReusableCell(withIdentifier: cellInfo.identifier, for: indexPath) 
        cellInfo.decorate?(row, users[0])
        if let row = row as? UserInfoCheckCell {
            row.setChecked(cellInfo.selected, animated: false)
        }
        row.backgroundColor = UIColor.clear
        return row
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.item == 0 || indexPath.item == cells.count + 1 {
            return 75.0
        }
        if cells[indexPath.item - 1].identifier == "blank" {
            return 20.0
        }
        return 50.0
    }
    
    func canHighlightCell(_ index: Int) -> Bool {
        if index == 0 { return false }
        if index == cells.count + 1 { return true }
        
        if cells[index - 1].identifier == "blank" { return false }
        return true
    }
    
    func processSelectedCell(_ index: Int) {
        if index == cells.count + 1 {
            EmailManager.sendCustomEmail(
                subject: "Rhyme a Zoo Student Data",
                body: createEmailBody(),
                from: settingsController)
        }
        else if index == 0 {
            return
        }
        else {
            var cell = cells[index - 1]
            cells[index - 1] = (cell.identifier, cell.decorate, !cell.selected)
            cell = cells[index - 1]
            
            //get the row and toggle the button
            let indexPath = IndexPath(row: index, section: 0)
            if let row = settingsController.tableView.cellForRow(at: indexPath) as? UserInfoCheckCell {
                row.setChecked(cell.selected, animated: true)
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        postNotification(RZSetTouchDelegateEnabledNotification, object: NSNumber(value: false))
        delay(0.5) {
            postNotification(RZSetTouchDelegateEnabledNotification, object: NSNumber(value: true))
        }
    }
    
    func createEmailBody() -> String {
        var emailBody: String = ""
        
        //add introduction
        emailBody += "<b>Rhyme a Zoo Student Data:</b> \(settingsController.classroom.name)</br>"
        
        let now = Date()
        let dateString = DateFormatter.localizedString(from: now, dateStyle: .medium, timeStyle: .none)
        let timeString = DateFormatter.localizedString(from: now, dateStyle: .none, timeStyle: .short)
        let nowString = "\(dateString) at \(timeString)"
        emailBody += "<i>This data was generated on \(nowString).</i></br></br>"
        
        for user in users {
            //add user header
            emailBody += "<b>\(user.name)</b></br>"
            user.pullDataFromCloud()
            
            //iterate through cells
            var currentCell = 1
            
            for (identifier, decorate, selected) in cells {
                currentCell += 1
                if !selected { continue }
                
                if let cell = settingsController.tableView.dequeueReusableCell(withIdentifier: identifier) as? UserInfoCell {
                    decorate?(cell, user)
                    //create string from cell
                    let unknown = "Unknown"
                    let cellString = "\(cell.titleLabel.text?.trimmingCharacters(in: .whitespaces) ?? unknown): &nbsp;<i>\(cell.itemLabel.text ?? unknown)</i></br>"
                    emailBody += cellString
                }
            }
            
            emailBody += "</b></br>"
        }
        
        return emailBody
    }
    
}

extension SettingsViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
}


//MARK: - Custom Cells

class StudentsCell : UITableViewCell {
    
    @IBOutlet weak var label: UILabel!
    var previousUserCount = 0
    
    func decorateForUsers(_ usersArray: [User]) {
        let contentView = label.superview!
        let users = Array(usersArray.reversed()) //reverse user array since we draw it backwards
        
        label.text = users.count == 0 ? "Add Students" : "View All Students"
        
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
        let size = CGSize(width: height, height: height)
        let y = label.frame.midY - height / 2
        
        var currentX = contentView.frame.width - size.width
        var currentUser = 0
        
        while currentX > endX && currentUser < users.count {
            let origin = CGPoint(x: currentX, y: y)
            let image = UIImageView(image: users[currentUser].icon)
            image.frame = CGRect(origin: origin, size: size)
            decorateUserIcon(image)
            contentView.addSubview(image)
            downsampleImageInView(image)
            
            if previousUserCount == 0 {
                image.transform = CGAffineTransform(translationX: 0.0, y: 5.0)
            }
            
            image.alpha = 0.0
            UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .curveEaseOut, animations: {
                image.alpha = 1.0
                image.transform = CGAffineTransform(translationX: 0.0, y: 0.0)
            }, completion: nil)
            
            currentX -= size.width + 5.0
            currentUser += 1
        }
        
        previousUserCount = users.count
    }
    
}

class ToggleCell : UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var toggleSwitch: UISwitch!
    
    var setting: ClassroomSetting?
    
    func decorateForSetting(_ setting: ClassroomSetting) {
        self.setting = setting
        self.backgroundColor = UIColor.clear
        
        nameLabel.text = setting.name
        descriptionLabel.text = setting.description
        if let current = setting.currentSetting() {
            toggleSwitch.isOn = current
        }
    }
    
    @IBAction func switchToggled(_ sender: UISwitch) {
        setting?.updateSetting(sender.isOn)
        
        if let setting = setting, setting.key == RZSettingRequirePasscode.key && sender.isOn {
            //make sure all users have passcodes
            checkAllUsersHavePasscode()
        }
    }
    
}

class UserNameCell : UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var passcodeLabel: UILabel!
    
    func decorateForUser(_ user: User) {
        nameLabel.text = user.name
        icon.image = user.icon
        decorateUserIcon(icon)
        downsampleImageInView(icon)
        
        if let passcode = user.passcode, RZSettingRequirePasscode.currentSetting() == true {
            passcodeLabel.text = "passcode: \(passcode)"
            passcodeLabel.textColor = UIColor.white
            passcodeLabel.alpha = 0.5
        } else {
            if RZSettingRequirePasscode.currentSetting() == true {
                passcodeLabel.text = "no passcode set"
                passcodeLabel.textColor = UIColor.red
                passcodeLabel.alpha = 0.4
            }
            else {
                passcodeLabel.alpha = 0.0
            }
            
        }
    }
    
}

class BigUserCell : UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    var controller: SettingsViewController?
    var user: User?
    
    func decorateForUser(_ user: User, controller: SettingsViewController) {
        nameLabel.text = user.name
        icon.image = user.icon
        decorateUserIcon(icon)
        downsampleImageInView(icon)
        self.hideSeparator()
        self.controller = controller
        self.user = user
        
        self.deleteButton.isHidden = self.frame.height != 100.0
    }
    
    @IBAction func deletePressed(_ sender: AnyObject) {
        if let user = user, let controller = controller {
            //confirm with alert
            let alert = UIAlertController(title: "Delete \(user.name)?", message: "This student will lose all of their progress forever.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Nevermind", style: .default, handler: nil))
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                
                let deletingAlert = UIAlertController(title: "Deleting \(user.name)...", message: nil, preferredStyle: .alert)
                controller.present(deletingAlert, animated: true, completion: nil)
                
                RZUserDatabase.deleteLocalUser(user, deleteFromClassroom: true)
                delay(1.0) {
                    RZUserDatabase.getUsersForClassroom(controller.classroom, completion: { users in
                        guard let users = users else { return }
                        
                        deletingAlert.dismiss(animated: true, completion: nil)
                        controller.backButtonPressed(self)
                        
                        if let delegate = controller.tableView.delegate as? SettingsUsersDelegate {
                            delegate.users = users
                            controller.tableView.reloadData()
                        }
                    })
                }
                
            }))
            
            controller.present(alert, animated: true, completion: nil)
        }
    }
    
}

class UserInfoCell : UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var itemLabel: UILabel!
    @IBOutlet weak var titleLeading: NSLayoutConstraint!
    
    func setTitle(_ string: String) {
        titleLabel.text = string
        self.accessoryType = .none
    }
    
    func setItem(_ string: String?) {
        itemLabel.text = string
        itemLabel.textColor = UIColor.white
        itemLabel.alpha = 0.7
        itemLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 750.0), for: .horizontal)
    }
    
    func setIndent(_ level: Int) {
        let indent = CGFloat(level) * 30.0
        titleLeading.constant = indent
        self.layoutIfNeeded()
    }
    
    func setHasFunction(_ hasFunction: Bool) {
        self.accessoryType = hasFunction ? .disclosureIndicator : .none
    }
    
    func makeItemResistCompression() {
        itemLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 800.0), for: .horizontal)
    }
    
}

class UserInfoCheckCell : UserInfoCell {
    
    @IBOutlet weak var check: UIImageView!
    
    func setChecked(_ checked: Bool, animated: Bool) {
        check.image = UIImage(named: checked ? "button-check" : "button-cancel")
        let scale: CGFloat = checked ? 1.3 : 1.0
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let alpha: CGFloat = checked ? 1.0 : 0.75
        
        if animated {
            UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: [], animations: {
                self.check.transform = transform
                self.check.alpha = alpha
            }, completion: nil)
        }
        else {
            check.transform = transform
            self.check.alpha = alpha
        }
    }
    
    override func setItem(_ string: String?) {
        super.setItem(string)
        itemLabel.alpha = 0.0
    }
    
    override func setTitle(_ string: String) {
        if string.hasSuffix(":") {
            let truncated = string.trimmingCharacters(in: CharacterSet(charactersIn: ":"))
            super.setTitle(truncated)
        }
        else {
           super.setTitle(string)
        }
    }
    
}

extension UITableViewCell {
    func hideSeparator() {
        self.separatorInset = UIEdgeInsets.init(top: 0, left: self.frame.size.width, bottom: 0, right: 0)
    }
}

func checkAllUsersHavePasscode() {
    RZUserDatabase.getLinkedClassroom({ classroom in
        if let classroom = classroom {
            RZUserDatabase.getUsersForClassroom(classroom, completion: { users in
                var noPasscode: [User] = []
                for user in users ?? [] {
                    if user.passcode == nil {
                        noPasscode.append(user)
                    }
                }
                
                if noPasscode.count > 0 {
                    //ask if we should generate passcodes for users without them
                    let plural = noPasscode.count == 1 ? " doesn't have a passcode." : " don't have passcodes."
                    let alert = UIAlertController(title: "Passcodes Enabled", message: "...but \(noPasscode.count) user\(plural) This means anybody with access to your classroom can play on their profile. Would you like us to create passcodes for them?", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Create Passcodes", style: .default, handler: { _ in
                        
                        for user in noPasscode {
                            //generate a 4-digit passcode
                            var passcode: String = ""
                            for _ in 1...4 {
                                let digit = "\(arc4random_uniform(9))"
                                passcode = passcode + digit
                            }
                            
                            user.passcode = passcode
                            RZUserDatabase.saveUserToLinkedClassroom(user)
                        }
                        
                        //show done alert
                        let done = UIAlertController(title: "Passcodes Created", message: "All of your users now have passcodes. You can the new passcodes by tapping \"View All Students\" on this screen.", preferredStyle: .alert)
                        done.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        if let controller = SettingsUserStatisticsDelegate.settingsControllerStatic {
                            controller.present(done, animated: true, completion: nil)
                        }
                        
                    }))
                    alert.addAction(UIAlertAction(title: "Ignore", style: .destructive, handler: nil))
                    
                    if let controller = SettingsUserStatisticsDelegate.settingsControllerStatic {
                        controller.present(alert, animated: true, completion: nil)
                    }
                    
                }
            })
        }
    })
}


// MARK: - Email system

enum EmailManager {
    
    enum MailApp: String, CaseIterable {
        case system = "Apple Mail"
        case outlook = "Microsoft Outlook"
        case other = "Other..."
        
        var supported: Bool {
            switch self {
            case .system:
                return MFMailComposeViewController.canSendMail()
            case .outlook:
                return UIApplication.shared.canOpenURL(URL(string: "ms-outlook://")!)
            case .other:
                return true
            }
        }
        
        func sendEmail(with htmlBody: String,
                       named subject: String,
                       from controller: UIViewController)
        {
            switch self {
            case .system:
                let mail = MFMailComposeViewController()
                mail.setMessageBody(htmlBody, isHTML: true)
                mail.setSubject(subject)
                mail.mailComposeDelegate = controller as? MFMailComposeViewControllerDelegate
                controller.present(mail, animated: true, completion: nil)
                
            case .outlook:
                let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
                let encodedBody = htmlBody.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
                let outlookURL = URL(string: "ms-outlook://compose?subject=\(encodedSubject)&body=\(encodedBody)")!
                UIApplication.shared.open(outlookURL)
                
            case .other:
                let plaintextContents = htmlBody
                    .replacingOccurrences(of: "<b>", with: "")
                    .replacingOccurrences(of: "</b>", with: "")
                    .replacingOccurrences(of: "<i>", with: "")
                    .replacingOccurrences(of: "</i>", with: "")
                    .replacingOccurrences(of: "&nbsp;", with: "")
                    .replacingOccurrences(of: "</br>", with: "\n")
                
                controller.present(
                    UIActivityViewController(
                        activityItems: [plaintextContents],
                        applicationActivities: nil),
                    animated: true)
            }
        }
        
    }
    
    static func sendCustomEmail(subject: String, body: String, from controller: UIViewController) {
        let supportedEmailApps = MailApp.allCases.filter { $0.supported }
        if supportedEmailApps.count == 1 {
            supportedEmailApps[0].sendEmail(with: body, named: subject, from: controller)
        }
            
        else {
            let alert = UIAlertController(title: "Select Email App", message: nil, preferredStyle: .actionSheet)
            
            supportedEmailApps.forEach { emailApp in
                alert.addAction(UIAlertAction(title: emailApp.rawValue, style: .default, handler: { _ in
                    emailApp.sendEmail(with: body, named: subject, from: controller)
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            controller.present(alert, animated: true)
        }
    }
    
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromCATransitionSubtype(_ input: CATransitionSubtype) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromCATransitionType(_ input: CATransitionType) -> String {
	return input.rawValue
}
