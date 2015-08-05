//
//  SettingsViewController.swift
//  Rhyme a Zoo
//
//  Created by Cal on 8/3/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import Foundation
import UIKit

class SettingsViewController : UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {
    
    var classroom: Classroom!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var touchRecognizer: UITouchGestureRecognizer!
    var updateTimer: NSTimer?
    
    override func viewWillAppear(animated: Bool) {
        tableView.contentInset = UIEdgeInsets(top: 70.0, left: 0.0, bottom: 0.0, right: 0.0)
        updateTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "updateSettings", userInfo: nil, repeats: true)
    }
    
    func updateSettings() {
        RZUserDatabase.refreshLinkedClassroomData({ classroom, dataChanged in
            if dataChanged {
                self.classroom = classroom
                self.tableView.reloadData()
            }
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        updateTimer?.invalidate()
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
        ("statistics", .Function(function: nil)),
        ("toggle", .Toggle(setting: RZSettingRequirePasscode)),
        ("toggle", .Toggle(setting: RZSettingUserCreation)),
        ("toggle", .Toggle(setting: RZSettingPhoneticsOnly)),
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
        
        if cell.identifier == "toggle" {
            let row = tableView.dequeueReusableCellWithIdentifier(cell.identifier, forIndexPath: indexPath) as! ToggleCell
            if let setting = cell.type.getSetting() {
                row.decorateForSetting(setting)
            }
            return row
        }
        
        return tableView.dequeueReusableCellWithIdentifier(cell.identifier, forIndexPath: indexPath) as! UITableViewCell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let cell = cells[indexPath.item]
        if cell.identifier == "statistics" {
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
                
                if sender.state == .Ended {
                    
                    //call function for cell
                    if let function = cell.type.getFunction() {
                        function(self)
                    }
                    
                }
                else {
                    if cell.type.getFunction() != nil {
                        animateSelection(index)
                    }
                }
            }
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        touchRecognizer.enabled = false
        animateSelection(nil)
        delay(0.5) {
            self.touchRecognizer.enabled = true
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
    
    @IBAction func backButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
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
            self.view.userInteractionEnabled = false
            delay(2.0) {
                //show alert then dismiss
                let alert = UIAlertController(title: "This device has been removed from \"\(classroomName)\"", message: "", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { _ in
                    self.dismissViewControllerAnimated(true, completion: nil)
                }))
                self.presentViewController(alert, animated: true, completion: nil)
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
                self.view.userInteractionEnabled = false
                delay(2.0) {
                    let deletedAlert = UIAlertController(title: "Deleted \"\(classroomName)\"", message: nil, preferredStyle: .Alert)
                    deletedAlert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { _ in
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }))
                    self.presentViewController(deletedAlert, animated: true, completion: nil)
                }
            })
        
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    
}

//MARK: - Toggle Cell

class ToggleCell : UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var toggleSwitch: UISwitch!
    
    var setting: ClassroomSetting?
    
    func decorateForSetting(setting: ClassroomSetting) {
        self.setting = setting
        
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




