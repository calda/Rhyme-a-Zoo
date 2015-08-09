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
var RZCurrentUser: User = User(emptyUserWithName: "DEFAULT USER // YOU SHOULD NEVER SEE THIS", iconName: "angry.jpg")
let RZUsersKey = "com.hearatale.raz.users"
let RZClassroomIDKey = "com.hearatale.raz.classroom"
let RZClassroomPasscodeKey = "com.hearatale.raz.classroom.passcode"

class UserDatabase {
    
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
    
    func deleteLocalUser(user: User, deleteFromClassroom: Bool) {
        let userString = user.toUserString()
        
        if var userStrings = data.stringArrayForKey(RZUsersKey) as? [String] {
            if let indexToRemove = find(userStrings, userString) {
                userStrings.removeAtIndex(indexToRemove)
                data.setValue(userStrings, forKey: RZUsersKey)
            }
        }
        
        if !deleteFromClassroom { return }
        
        //also delete from the cloud if applicable
        getLinkedClassroom({ classroom in
            
            if let classroom = classroom, record = user.record {
                let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [record.recordID])
                operation.modifyRecordsCompletionBlock = { _, _, error in
                    if error != nil {
                        println(error)
                    }
                }
                self.cloud.addOperation(operation)
            }
        
        })
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
        
        RZUserDatabase.saveCurrentUserToLinkedClassroom()
    }
    
    //MARK: - CloudKit School management
    
    let cloud = CKContainer.defaultContainer().publicCloudDatabase
    private var currentClassroom: Classroom?
    
    func createClassroomNamed(name: String, location: CLLocation, passcode: String, completion: ((Classroom?) -> ())?) {
        
        let record = CKRecord(recordType: "Classroom")
        record.setObject(name, forKey: "Name")
        record.setObject(passcode, forKey: "Passcode")
        record.setObject(location, forKey: "Location")
        cloud.saveRecord(record, completionHandler: { record, error in
            if record == nil {
                sync() {
                    completion?(nil)
                }
                return
            }
            let classroom = Classroom(record: record)
            sync() {
                completion?(classroom)

            }
        })
    }
    
    func linkToClassroom(classroom: Classroom) {
        let name = classroom.record.recordID.recordName
        data.setValue(name, forKey: RZClassroomIDKey)
        data.setValue(classroom.passcode, forKey: RZClassroomPasscodeKey)
        self.currentClassroom = classroom
    }
    
    func hasLinkedClassroom() -> Bool {
        return data.valueForKey(RZClassroomIDKey) != nil
    }
    
    func unlinkClassroom() {
        //remove all classroom users
        let users = RZUserDatabase.getLocalUsers()
        for user in users {
            RZUserDatabase.deleteLocalUser(user, deleteFromClassroom: false)
        }
        
        data.setValue(nil, forKey: RZClassroomIDKey)
        data.setValue(nil, forKey: RZClassroomPasscodeKey)
        currentClassroom = nil
    }
    
    func getLinkedClassroom(completion: (Classroom?) -> ()) {
        if let classroom = currentClassroom {
            completion(classroom)
            return
        }
        
        getLinkedClassroomFromCloud(completion)
    }
    
    func getLinkedClassroomPasscode() -> String? {
        return data.stringForKey(RZClassroomPasscodeKey)
    }
    
    func getLinkedClassroomFromCloud(completion: (Classroom?) -> ()) {
        if let classroomName = data.stringForKey(RZClassroomIDKey) {
            let recordID = CKRecordID(recordName: classroomName)
            cloud.fetchRecordWithID(recordID, completionHandler: { record, error in
                if error != nil { println(error) }
                if record != nil {
                    let classroom = Classroom(record: record)
                    self.currentClassroom = classroom
                    sync() {
                        completion(classroom)
                    }
                } else {
                    
                    if error != nil && error.code == 11 {
                        //11 = "Unknown Item" (11/2003)
                        //classroom was not in cloud, meaning the classroom was deleted on another device
                        RZUserDatabase.unlinkClassroom()
                    }
                    
                    sync() {
                        completion(nil)
                    }
                }
            })
        }
        else {
            completion(nil)
        }
    }
    
    func userLoggedIn(completion: Bool -> ()) {
        CKContainer.defaultContainer().accountStatusWithCompletionHandler({ status, error in
            sync() {
                completion(status == .Available)
            }
        })
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
        } else {
            query.sortDescriptors = [NSSortDescriptor(key: "Name", ascending: true)]
        }
        cloud.performQuery(query, inZoneWithID: nil, completionHandler: classroomQueryCompletionHandler(completion))
    }
    
    private func classroomQueryCompletionHandler(completion: [Classroom] -> ()) -> ([AnyObject]!, NSError!) -> () {
        
        func classroomQueryCompletionHandler(results: [AnyObject]!, error: NSError!) {
            
            if error != nil {
                println(error)
            }
            
            if let records = results as? [CKRecord] {
                var classrooms: [Classroom] = []
                for record in records {
                    classrooms.append(Classroom(record: record))
                }
                
                sync() {
                    completion(classrooms)
                }
                
            }
            else {
                sync() {
                    completion([])
                }
                
            }
        }
        
        return classroomQueryCompletionHandler
    }
    
    func saveClassroom(classroom: Classroom) {
        let record = classroom.getUpdatedRecord()
        let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        operation.modifyRecordsCompletionBlock = { _, _, error in
            if error != nil {
                println(error)
            }
        }
        self.cloud.addOperation(operation)
    }
    
    func refreshLinkedClassroomData(completion: ((classroom: Classroom, changesFound: Bool) -> ())?) {
        if let currentClassroom = self.currentClassroom {
            getLinkedClassroomFromCloud({ classroom in
                if let classroom = classroom {
                    let previousModified = currentClassroom.record.modificationDate.timeIntervalSince1970
                    let currentModified = classroom.record.modificationDate.timeIntervalSince1970
                    completion?(classroom: classroom, changesFound: currentModified > previousModified)
                }
            })
        }
    }
    
    func deleteClassroom(classroom: Classroom) {
        let record = classroom.getUpdatedRecord()
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [record.recordID])
        operation.modifyRecordsCompletionBlock = { _, _, error in
            if error != nil {
                println(error)
            }
        }
        self.cloud.addOperation(operation)
    }
    
    //MARK: - CloudKit User Management
    
    func getUsersForClassroom(classroom: Classroom, completion: [User] -> ()) {
        let predicate = NSPredicate(format: "Classroom = %@", classroom.record.recordID)
        let query = CKQuery(recordType: "User", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "UserString", ascending: true)]
        cloud.performQuery(query, inZoneWithID: nil, completionHandler: { results, error in
            
            var users: [User] = []
            
            if let records = results as? [CKRecord] {
                for record in records {
                    if let user = User(record: record) {
                        users.append(user)
                    }
                }
            }
            
            sync() {
                completion(users)
            }
            
            
        })
    }
    
    func saveCurrentUserToLinkedClassroom() {
        saveUserToLinkedClassroom(RZCurrentUser)
    }
    
    func saveUserToLinkedClassroom(user: User) {
        getLinkedClassroom({ classroom in
            if let classroom = classroom {
                if let record = user.getUpdatedRecord(classroom) {
                    let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
                    operation.modifyRecordsCompletionBlock = { _, _, error in
                        if error != nil {
                            println(error)
                        }
                    }
                    self.cloud.addOperation(operation)
                }
            }
        })
    }
    
    func saveNewUserToLinkedClassroom(newUser: User) {
        //make sure the user doesn't already exist
        RZUserDatabase.getLinkedClassroom({ classroom in
            if let classroom = classroom {
                RZUserDatabase.getUsersForClassroom(classroom, completion: { users in
                    
                    for user in users {
                        if user.ID == newUser.ID {
                            //the user already exists in the classroom
                            //make sure the record doesn't get duplicated
                            newUser.record = user.record
                            break
                        }
                    }
                    
                    if let record = newUser.getUpdatedRecord(classroom) {
                        newUser.record = record
                        RZUserDatabase.saveUserToLinkedClassroom(newUser)
                    }
                    
                    
                })
            }
        })
    }
    
    func refreshUser(user: User) {
        if let currentRecord = user.record {
            cloud.fetchRecordWithID(currentRecord.recordID, completionHandler: { record, error in
                if record != nil {
                    let previousModified = currentRecord.modificationDate.timeIntervalSince1970
                    let currentModified = record.modificationDate.timeIntervalSince1970
                    if currentModified > previousModified {
                        user.record = record
                        user.pullDataFromCloud()
                    }
                }
            })
        }
    }
    
}

class User {
    
    let name: String
    var icon: UIImage?
    var iconName: String
    let ID: String
    var passcode: String?

    var record: CKRecord?
    
    init(emptyUserWithName name: String, iconName: String) {
        self.name = name
        self.iconName = iconName
        self.icon = UIImage(named: iconName)!
        self.ID = name + "\(arc4random_uniform(10000))"
    }
    
    ///creates a new user with a unique ID
    init(name: String, iconName: String) {
        self.name = name
        self.iconName = iconName
        self.icon = UIImage(named: iconName)!
        self.ID = name + "\(arc4random_uniform(10000))"
        RZUserDatabase.saveNewUserToLinkedClassroom(self)
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
    
    convenience init?(record: CKRecord) {
        let userString = record.valueForKey("UserString") as! String
        self.init(fromString: userString)
        self.passcode = record.valueForKey("Passcode") as? String
        self.record = record
    }
    
    func toUserString() -> String {
        return name + "~" + ID + "~" + iconName
    }
    
    func getUpdatedRecord(classroom: Classroom) -> CKRecord? {
        //keep the default user from propegating up into the cloud
        if self.name == "DEFAULT USER // YOU SHOULD NEVER SEE THIS" { return nil }
        
        let actualUser = RZCurrentUser
        RZCurrentUser = self
        
        let record: CKRecord
        if let selfRecord = self.record {
            record = selfRecord
        } else {
            record = CKRecord(recordType: "User")
        }
        record.setObject(toUserString(), forKey: "UserString")
        record.setObject(self.passcode, forKey: "Passcode")
        record.setObject(dictToArray(RZQuizDatabase.getQuizData()), forKey: "QuizData")
        record.setObject(CKReference(record: classroom.record, action: CKReferenceAction.DeleteSelf), forKey: "Classroom")
        record.setObject(RZQuizDatabase.getFavorites(), forKey: "Favorites")
        record.setObject(RZQuizDatabase.getPlayerBalance(), forKey: "Balance")
        record.setObject(RZQuizDatabase.getOwnedAnimals(), forKey: "OwnedAnimals")
        record.setObject(RZQuizDatabase.currentZooLevel(), forKey: "ZooLevel")
        record.setObject(RZQuizDatabase.currentLevel(), forKey: "QuizLevel")
        record.setObject(RZQuizDatabase.getKeeperString(), forKey: "Zookeeper")
        record.setObject(RZQuizDatabase.getTotalMoneyEarnedArray(), forKey: "TotalMoneyEarned")
        record.setObject("\(RZQuizDatabase.hasWatchedWelcomeVideo())", forKey: "HasWatchedWelcomeVideo")
        
        RZCurrentUser = actualUser
        return record
    }
    
    func pullDataFromCloud() -> Bool {
        if let record = record {
            
            let quizData = record.valueForKey("QuizData") as! [String]
            let favorites = record.valueForKey("Favorites") as? [Int] ?? []
            let balance = record.valueForKey("Balance") as? Double ?? 0
            let ownedAnimals = record.valueForKey("OwnedAnimals") as? [String] ?? []
            let zooLevel = record.valueForKey("ZooLevel") as? Int ?? 1
            let quizLevel = record.valueForKey("QuizLevel") as? Int ?? 1
            let keeperString = record.valueForKey("Zookeeper") as? String ?? "boy~1"
            let totalMoneyEarned = record.valueForKey("TotalMoneyEarned") as? [String] ?? []
            let hasWatchedWelcomeVideo = record.valueForKey("HasWatchedWelcomeVideo") as? String ?? "false"
            
            let actualUser = RZCurrentUser
            RZCurrentUser = self
            
            //save to database
            RZQuizDatabase.setQuizData(arrayToDict(quizData))
            RZQuizDatabase.setFavorites(favorites)
            RZQuizDatabase.setPlayerBalance(balance)
            RZQuizDatabase.setOwnedAnimals(ownedAnimals)
            RZQuizDatabase.setZooLevel(zooLevel)
            RZQuizDatabase.setQuizLevel(quizLevel)
            RZQuizDatabase.setKeeperWithString(keeperString)
            RZQuizDatabase.setTotalMoneyEarnedFromArray(totalMoneyEarned)
            RZQuizDatabase.setHasWatchedWelcomeVideo(hasWatchedWelcomeVideo == "true")
            
            RZCurrentUser = actualUser
            return true
            
        }
        else {
            return false
        }
    }
    
}

//MARK: - Classroom Settings

let RZSettingPhoneticsOnly = ClassroomSetting("Only Show Phonetics Questions", "Students will not be quizzed on rhyme comprehension.", false)
let RZSettingRequirePasscode = ClassroomSetting("Require Student Passcodes", "Students will have to type their passcode to play.", true)
let RZSettingUserCreation = ClassroomSetting("Allow students to create new Users", "Students will be able to create new user accounts.", false)
let RZSettingSkipVideos = ClassroomSetting("Allow students to skip videos", "Students will be able to skip videos, possibly missing important info.", false)

let RZClassroomSettings = [RZSettingRequirePasscode, RZSettingUserCreation, RZSettingPhoneticsOnly, RZSettingSkipVideos]

struct ClassroomSetting {
    
    let name: String
    var key: String {
        return name
    }
    let description: String
    let byDefault: Bool
    
    init(_ name: String, _ description: String, _ byDefault: Bool) {
        self.name = name
        self.description = description
        self.byDefault = byDefault
    }
    
    func currentSetting() -> Bool? {
        //settings are only relevant if there is a connected classroom
        if !RZUserDatabase.hasLinkedClassroom() { return nil }
        
        if let setting = data.stringForKey(self.key) {
            return setting == "true"
        }
        
        //return default if there is nothing set
        return byDefault
    }
    
    func updateSetting(new: Bool) {
        data.setValue("\(new)", forKey: self.key)
        
        RZUserDatabase.getLinkedClassroom({ classroom in
            if let classroom = classroom {
                RZUserDatabase.saveClassroom(classroom)
            }
        })
    }
    
    func updateSettingFromCloud(newString: String) {
        data.setValue(newString, forKey: self.key)
    }
    
}

class Classroom {
    
    let record: CKRecord
    let name: String
    let location: CLLocation
    var passcode: String
    
    init(record: CKRecord) {
        self.record = record
        name = record.valueForKey("Name") as! String
        location = record.valueForKey("Location") as! CLLocation
        passcode = record.valueForKey("Passcode") as! String
        
        //load settings
        if let settingsArray = record.valueForKey("Settings") as? [String] {
            let cloudSettings = arrayToDict(settingsArray)
            for setting in RZClassroomSettings {
                if let userInput = cloudSettings[setting.name] {
                    setting.updateSettingFromCloud(userInput)
                }
            }
        }
        
    }
    
    func getUpdatedRecord() -> CKRecord {
        record.setObject(passcode, forKey: "Passcode")
        
        //create settings dictionary
        var cloudSettings: [String : String] = [:]
        for setting in RZClassroomSettings {
            if let current = setting.currentSetting() {
                cloudSettings.updateValue("\(current)", forKey: setting.name)
            }
        }
        
        let settingsArray = dictToArray(cloudSettings)
        record.setObject(settingsArray, forKey: "Settings")
        
        return record
    }
    
}
