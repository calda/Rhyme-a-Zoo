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
    
    override func viewWillAppear(_ animated: Bool) {
        if users.count == 0 { collectionView.alpha = 0.0 }
        else { decorateForLoadedUsers() }
        viewAppearingAnimated = animated
        classroomLabel.isHidden = true
        classroomIcon.isHidden = true
        activityIndicator.isHidden = animated
        
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
        self.activityIndicator.isHidden = false
        
        //present welcome view if there are no users
        //present main view if there is only one user
        //but stay on this view if there is a linked classroom
        RZUserDatabase.getLinkedClassroom() { classroom in
            if let classroom = classroom {
                if let allowUserCreation = RZSettingUserCreation.currentSetting() {
                    self.allowUserCreation = allowUserCreation
                }
                
                self.classroomLabel.isHidden = false
                self.classroomLabel.titleLabel!.text = classroom.name
                self.classroomLabel.setTitle(classroom.name, for: .normal)
                self.classroomIcon.isHidden = false
                self.coverGradient.alpha = 0.0
                self.collectionViewPosition.constant = 30.0
                UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: [], animations: {
                    self.view.layoutIfNeeded()
                    self.classroomLabel.alpha = 1.0
                    self.classroomIcon.alpha = 1.0
                }, completion: nil)
                
                //get users
                RZUserDatabase.getUsersForClassroom(classroom, completion: { users in
                    guard let users = users else {
                        self.connectionIssues(duringLoad: true)
                        return
                    }
                    
                    self.cloudUsers = true
                    self.users = users
                    self.activityIndicator.isHidden = true
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
                self.activityIndicator.isHidden = true
                
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
                
                UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: [], animations: {
                    self.reloadButton.alpha = 0.0
                }, completion: nil)
                
            }
            
        }
        
        delay(10.0) {
            //if it takes more than ten seconds to load the users
            if !self.classroomLinked {
                self.connectionIssues(duringLoad: true)
            }
            
        }
    }
    
    func connectionIssues(duringLoad: Bool) {
        let alert = UIAlertController(title: "We're having trouble connecting to the internet.", message: " Classrooms require an internet connection.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Try Again", style: .default, handler: { _ in
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
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
            openSettings()
            delay(1.0) {
                self.present(alert, animated: true, completion: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "Leave Classroom", style: .destructive, handler: { _ in
            
            //confirm with passcode
            if let passcode = RZUserDatabase.getLinkedClassroomPasscode() {
                
                requestPasscode(passcode, description: "Verify passcode to leave classroom on this device.", currentController: self) { success in
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
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK: - Setting up the View Controller
    
    func decorateForLoadedUsers() {
        if users.count == 0 && !cloudUsers {
            coverGradient.alpha = 1.0
        }
        
        if iPad() && displayOffset == 1.0 {
            collectionViewArea.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        } else {
            collectionViewArea.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }
        
        //calculate height of collectionView and width of cells
        let screenHeight = UIScreen.main.bounds.height
        let notCollection = screenHeight - (10 + (screenHeight / 4.5) + 10)
        let collectionHeight = (notCollection * 0.75) / displayOffset
        let iconHeight = collectionHeight - 29
        let cellWidth = iconHeight + 15
        let userCount = CGFloat(users.count + (allowUserCreation ? 1 : 0))
        let widthInUse = cellWidth * CGFloat(ceil(userCount / displayOffset))
        
        //center collection view if full width is not used
        let screenWidth = UIScreen.main.bounds.width
        if widthInUse < screenWidth {
            let diff = screenWidth - widthInUse
            collectionWidth.constant = -diff
            self.view.layoutIfNeeded()
            collectionView.isScrollEnabled = false
            collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        } else {
            collectionView.isScrollEnabled = true
            collectionWidth.constant = 0
            self.view.layoutIfNeeded()
            collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        
        //turn off clipping on the collection view
        collectionView.clipsToBounds = false
        
        //animate
        if collectionView.alpha == 0.0 {
            collectionView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            UIView.animate(withDuration: 0.7, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: [], animations: {
                self.collectionView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }, completion: nil)
            
            UIView.animate(withDuration: 0.3, animations: {
                self.collectionView.alpha = 1.0
            }) 
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        viewAppeared = true
        if classroomLinked {
            readyToChangeViews()
        }
    }
    
    func readyToChangeViews() {
        if coverGradient.alpha == 1.0 {
            if users.count == 0 { //present welcome view if there are no users
                let welcome = UIStoryboard(name: "User", bundle: nil).instantiateViewController(withIdentifier: "welcome") 
                self.present(welcome, animated: false, completion: nil)
            }
            else if users.count == 1 && !cloudUsers && !viewAppearingAnimated { //present main view if there is only one user
                RZCurrentUser = RZUserDatabase.getLocalUsers()[0]
                let home = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()!
                self.present(home, animated: false, completion: nil)
            } else {
                coverGradient.alpha = 0.0
            }
            
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        coverGradient.alpha = 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = users.count + (allowUserCreation ? 1 : 0)
        if count == 0 && cloudUsers {
            //classroom has not been set up yet
            showTeacherIntro()
        }
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == users.count { //add user button as last cell
            return collectionView.dequeueReusableCell(withReuseIdentifier: "add", for: indexPath) 
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "user", for: indexPath) as! UserCell
        let user = users[indexPath.item]
        cell.decorate(user, height: collectionView.frame.height  / displayOffset)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.frame.height / displayOffset
        let iconHeight = height - 29
        let width = iconHeight + 15
        return CGSize(width: width, height: height)
    }
    
    //MARK: - Selection of Cells
    
    func checkUserPasscode(_ user: User) {
        if let passcode = user.passcode, RZSettingRequirePasscode.currentSetting() == true {
            requestPasscode(passcode, description: "Enter the passcode for \(user.name)", currentController: self, forKids: true, completion: { success in
                if success {
                    self.logInToUser(user)
                }
            })
        }
        else {
            logInToUser(user)
        }
    }
    
    func logInToUser(_ user: User) {
        RZCurrentUser = user
        user.pullDataFromCloud()
        let mainMenu = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()!
        self.present(mainMenu, animated: true, completion: nil)
        
        if !RZUserDatabase.hasLinkedClassroom() { return }
        
        //make sure the classroom still exists
        RZUserDatabase.getLinkedClassroomFromCloud({ classroom in
            if classroom == nil {
                
                //if we aren't linked to a classroom now, that means the classroom really was deleted on another device
                if !RZUserDatabase.hasLinkedClassroom() {
                    let alert = UIAlertController(title: "Your classroom was just deleted on another device.", message: "You will now be logged out.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                        mainMenu.dismiss(animated: true, completion: nil)
                    }))
                    mainMenu.present(alert, animated: true, completion: nil)
                }
                    
                else {
                    //other option is that the internet is no longer available
                    mainMenu.dismiss(animated: true, completion: {
                        self.collectionView.alpha = 0.0
                        self.connectionIssues(duringLoad: false)
                    })
                    
                }
                
                
            }
        })
    }
    
    var pannedDuringTouch = false
    
    @IBAction func touchRecognized(_ sender: UITouchGestureRecognizer) {
        let touch = sender.location(in: self.view)
        
        if sender.state == .began {
            pannedDuringTouch = false
        }
        
        for cell in collectionView.visibleCells {
            let screenFrame = cell.superview!.convert(cell.frame, to: self.view)
            if screenFrame.contains(touch) && !pannedDuringTouch {
                if sender.state == .ended {
                    //select the cell
                    deselectCell(cell)
                    if let cell = cell as? UserCell {
                        if let user = cell.user, !pannedDuringTouch {
                            checkUserPasscode(user)
                        }
                    }
                    else {
                        //is Add User cell
                        let newUser = UIStoryboard(name: "User", bundle: nil).instantiateViewController(withIdentifier: "newUser") as! NewUserViewController
                        self.present(newUser, animated: true, completion: nil)
                    }
                } else {
                    selectCell(cell)
                }
            } else {
                deselectCell(cell)
            }
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    //deselect all cells when the view scrolls
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        pannedDuringTouch = true
        
        for cell in collectionView.visibleCells {
            deselectCell(cell)
        }
    }
    
    func selectCell(_ cell: UICollectionViewCell) {
        let scale: CGFloat = iPad() ? 1.05 : 1.1
        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: [], animations: {
            cell.transform = CGAffineTransform(scaleX: scale, y: scale)
        }, completion: nil)
    }
    
    func deselectCell(_ cell: UICollectionViewCell) {
        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: [], animations: {
            cell.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }, completion: nil)
    }
    
    //MARK: Unwind Segue
    @IBAction func returnToUsers(_ segue: UIStoryboardSegue) { }
    
    //MARK: Other User Interaction
    
    @IBAction func openClassroomSettings(_ sender: UIButton) {
        RZUserDatabase.getLinkedClassroom({ classroom in
        
            if let classroom = classroom {
                requestPasscode(classroom.passcode, description: "Passcode for \(classroom.name)", currentController: self, completion: { success in
                    guard success else { return }
                    
                    let settings = UIStoryboard(name: "User", bundle: nil).instantiateViewController(withIdentifier: "classroomSettings") as! SettingsViewController
                    settings.classroom = classroom
                    self.present(settings, animated: true, completion: nil)
                })
            }
            
        })
    }
    
    @IBAction func reloadUsers(_ sender: UIButton) {
        self.loadUsers()
        self.activityIndicator.isHidden = false
    }
    
    func showTeacherIntro() {
        let alert1 = UIAlertController(title: "Welcome to Rhyme a Zoo!", message: "You can access settings for your Classroom at any time by tapping its name at the bottom left corner of the screen.", preferredStyle: .alert)
        alert1.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
        
            //show second alert
            let alert2 = UIAlertController(title: "Add Students?", message: "Now you can add students to your Classroom. It's easy, as long as you have a list of names.", preferredStyle: .alert)
            alert2.addAction(UIAlertAction(title: "Open Student Settings", style: .default, handler: { _ in self.switchToAddStudents() }))
            alert2.addAction(UIAlertAction(title: "Do This Later", style: .destructive, handler: nil))
            self.present(alert2, animated: true, completion: nil)
            
        }))
        
        self.present(alert1, animated: true, completion: nil)
    }
    
    func switchToAddStudents() {
        RZUserDatabase.getLinkedClassroom({ classroom in
            if let classroom = classroom {
                //present settings controller
                let settings = UIStoryboard(name: "User", bundle: nil).instantiateViewController(withIdentifier: "classroomSettings") as! SettingsViewController
                settings.classroom = classroom
                self.present(settings, animated: true, completion: nil)
                
                //switch to users delegate
                delay(0.6) {
                    let delegate = SettingsUsersDelegate(settings)
                    settings.switchToDelegate(delegate, isBack: false, atOffset: nil)
                }
            }
        })
    }
    
}

class UserCell : UICollectionViewCell {
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var name: UILabel!
    var user: User?
    
    func decorate(_ user: User, height: CGFloat) {
        self.user = user
        name.text = user.name
        icon.image = user.icon
        decorateUserIcon(icon, height: height)
    }
    
}
