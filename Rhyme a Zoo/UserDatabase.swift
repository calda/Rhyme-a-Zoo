//
//  UserDatabase.swift
//  Rhyme a Zoo
//
//  Created by Cal on 7/17/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import CloudKit

let RZUserDatabase = UserDatabase()
var RZCurrentUser: User = User(name: "default", iconName: "angry.jpg")
let RZUsersKey = "com.hearatale.raz.users"

struct UserDatabase {
    
    //MARK: - Local User Management
    
    func getLocalUsers() -> [User] {
        var users: [User] = []
        
        if let userStrings = data.stringArrayForKey(RZUsersKey) as? [String] {
            for userString in userStrings {
                if let user = User(fromString: userString) {
                    users.append(user)
                }
            }
        }
        
        return users
    }
    
    func addLocalUser(user: User) {
        var users = getLocalUsers()
        var userStrings: [String] = []
        
        for user in users {
            userStrings.append(user.toString())
        }
        userStrings.append(user.toString())
        data.setValue(userStrings, forKey: RZUsersKey)
    }
    
    func deleteLocalUser(user: User) {
        let userString = user.toString()
        
        if var userStrings = data.stringArrayForKey(RZUsersKey) as? [String] {
            if let indexToRemove = find(userStrings, userString) {
                userStrings.removeAtIndex(indexToRemove)
                data.setValue(userStrings, forKey: RZUsersKey)
            }
        }
    }
    
    func changeLocalUserIcon(user immutableUser: User, newIcon: String) {
        var user = immutableUser
        let oldUserString = user.toString()
        user.iconName = newIcon
        user.icon = UIImage(named: newIcon)!
        let newUserString = user.toString()
        
        if var userStrings = data.stringArrayForKey(RZUsersKey) as? [String] {
            if let indexToSwitch = find(userStrings, oldUserString) {
                userStrings[indexToSwitch] = newUserString
                data.setValue(userStrings, forKey: RZUsersKey)
            }
        }
    }
    
    //MARK: - CloudKit School management
    
    let cloud = CKContainer.defaultContainer().publicCloudDatabase
    
    func createClassroomNamed(name: String, location: CLLocation, passcode: Int) {
        let record = CKRecord(recordType: "Classroom")
        record.setObject(name, forKey: "Name")
        record.setObject(1234, forKey: "Passcode")
        record.setObject(location, forKey: "Location")
        cloud.saveRecord(record, completionHandler: nil)
    }
    
}

class User {
    
    let name: String
    var icon: UIImage?
    var iconName: String
    let ID: String
    
    ///creates a new user with a unique ID
    init(name: String, iconName: String) {
        self.name = name
        self.iconName = iconName
        self.icon = UIImage(named: iconName)!
        ID = name + "\(arc4random_uniform(10000))"
    }
    
    init?(fromString string: String) {
        let splits = split(string){ $0 == "~" }
        if splits.count != 3 {
            name = ""
            iconName = ""
            ID = ""
            return nil
        }
        name = splits[0]
        ID = splits[1]
        iconName = splits[2]
        icon = UIImage(named: iconName)
    }
    
    func toString() -> String {
        return name + "~" + ID + "~" + iconName
    }
    
}