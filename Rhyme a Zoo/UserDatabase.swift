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
var RZCurrentUser: User = User(name: "default user", iconName: "angry.jpg")
let RZUsersKey = "com.hearatale.raz.users"
let RZClassroomIDKey = "com.hearatale.raz.classroom"

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
            userStrings.append(user.toUserString())
        }
        userStrings.append(user.toUserString())
        data.setValue(userStrings, forKey: RZUsersKey)
    }
    
    func deleteLocalUser(user: User) {
        let userString = user.toUserString()
        
        if var userStrings = data.stringArrayForKey(RZUsersKey) as? [String] {
            if let indexToRemove = find(userStrings, userString) {
                userStrings.removeAtIndex(indexToRemove)
                data.setValue(userStrings, forKey: RZUsersKey)
            }
        }
    }
    
    func changeLocalUserIcon(user immutableUser: User, newIcon: String) {
        var user = immutableUser
        let oldUserString = user.toUserString()
        user.iconName = newIcon
        user.icon = UIImage(named: newIcon)!
        let newUserString = user.toUserString()
        
        if var userStrings = data.stringArrayForKey(RZUsersKey) as? [String] {
            if let indexToSwitch = find(userStrings, oldUserString) {
                userStrings[indexToSwitch] = newUserString
                data.setValue(userStrings, forKey: RZUsersKey)
            }
        }
    }
    
    //MARK: - CloudKit School management
    
    let cloud = CKContainer.defaultContainer().publicCloudDatabase
    
    func createClassroomNamed(name: String, location: CLLocation, passcode: String) {
        let record = CKRecord(recordType: "Classroom")
        record.setObject(name, forKey: "Name")
        record.setObject(passcode, forKey: "Passcode")
        record.setObject(location, forKey: "Location")
        cloud.saveRecord(record, completionHandler: nil)
    }
    
    func linkToClassroom(classroom: Classroom) {
        
    }
    
    func getNearbyClassrooms(location: CLLocation, completion: [Classroom] -> ()) {
        let predicate = NSPredicate(format: "distanceToLocation:fromLocation:(Location, %@) < 8047", location) //within 5 miles
        let query = CKQuery(recordType: "Classroom", predicate: predicate)
        query.sortDescriptors = [CKLocationSortDescriptor(key: "Location", relativeLocation: location)]
        cloud.performQuery(query, inZoneWithID: nil, completionHandler: classroomQueryCompletionHandler(completion))
    }
    
    func getClassroomsMatchingText(text: String, location: CLLocation?, completion: [Classroom] -> ()) {
        let predicate = NSPredicate(format: "Name BEGINSWITH %@", text)
        let query = CKQuery(recordType: "Classroom", predicate: predicate)
        if let location = location {
            query.sortDescriptors = [CKLocationSortDescriptor(key: "Location", relativeLocation: location)]
        }
        cloud.performQuery(query, inZoneWithID: nil, completionHandler: classroomQueryCompletionHandler(completion))
    }
    
    private func classroomQueryCompletionHandler(completion: [Classroom] -> ()) -> ([AnyObject]!, NSError!) -> () {
        
        func classroomQueryCompletionHandler(results: [AnyObject]!, error: NSError!) {
            if let records = results as? [CKRecord] {
                var classrooms: [Classroom] = []
                for record in records {
                    classrooms.append(Classroom(record: record))
                }
                
                completion(classrooms)
            }
            else {
                completion([])
            }
        }
        
        return classroomQueryCompletionHandler
    }
    
    
}

class User {
    
    let name: String
    var icon: UIImage?
    var iconName: String
    let ID: String
    
    var record: CKRecord?
    
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
    
    //init?(record: CKRecord) {
        //TODO: implement reading from a record
    //}
    
    func toUserString() -> String {
        return name + "~" + ID + "~" + iconName
    }
    
    func updateRecord() -> CKRecord {
        let actualUser = RZCurrentUser
        RZCurrentUser = self
        
        let record = self.record ?? CKRecord(recordType: "User")!
        record.setObject(dictToArray(RZQuizDatabase.getQuizData()), forKey: "QuizData")
        //TODO: Add Classroom reference
        record.setObject(RZQuizDatabase.getFavorites(), forKey: "Favorites")
        record.setObject(RZQuizDatabase.getPlayerBalance(), forKey: "Balanace")
        record.setObject(RZQuizDatabase.getOwnedAnimals(), forKey: "OwnedAnimals")
        record.setObject(RZQuizDatabase.currentZooLevel(), forKey: "ZooLevel")
        record.setObject(RZQuizDatabase.currentLevel(), forKey: "QuizLevel")
        record.setObject(RZQuizDatabase.getKeeperString(), forKey: "Zookeeper")
        
        
        RZCurrentUser = actualUser
        return record
    }
    
    
    
}

class Classroom {
    
    let record: CKRecord
    let name: String
    let location: CLLocation
    let passcode: String
    
    init(record: CKRecord) {
        self.record = record
        name = record.valueForKey("Name") as! String
        location = record.valueForKey("Location") as! CLLocation
        passcode = record.valueForKey("Passcode") as! String
    }
    
}
