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
        
        if let userStrings = data.stringArray(forKey: RZUsersKey) {
            for userString in userStrings {
                if let user = User(fromString: userString) {
                    users.append(user)
                }
            }
        }
        
        return users
    }
    
    func addLocalUser(_ user: User) {
        let users = getLocalUsers()
        var userStrings: [String] = []
        
        for user in users {
            userStrings.append(user.toUserString())
        }
        userStrings.append(user.toUserString())
        data.setValue(userStrings, forKey: RZUsersKey)
    }
    
    func deleteLocalUser(_ user: User, deleteFromClassroom: Bool) {
        let userString = user.toUserString()
        
        if var userStrings = data.stringArray(forKey: RZUsersKey) {
            if let indexToRemove = userStrings.index(of: userString) {
                userStrings.remove(at: indexToRemove)
                data.setValue(userStrings, forKey: RZUsersKey)
            }
        }
        
        if !deleteFromClassroom { return }
        
        //also delete from the cloud if applicable
        getLinkedClassroom({ classroom in
            
            if classroom != nil, let record = user.record {
                let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [record.recordID])
                operation.modifyRecordsCompletionBlock = { _, _, error in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                }
                self.cloud.add(operation)
            }
        
        })
    }
    
    func changeLocalUserIcon(user: User, newIcon: String) {
        let oldUserString = user.toUserString()
        user.iconName = newIcon
        user.icon = UIImage(named: newIcon)!
        let newUserString = user.toUserString()
        
        if var userStrings = data.stringArray(forKey: RZUsersKey) {
            if let indexToSwitch = userStrings.index(of: oldUserString) {
                userStrings[indexToSwitch] = newUserString
                data.setValue(userStrings, forKey: RZUsersKey)
            }
        }
        
        RZUserDatabase.saveCurrentUserToLinkedClassroom()
    }
    
    //MARK: - CloudKit School management
    
    let cloud = CKContainer.default().publicCloudDatabase
    fileprivate var currentClassroom: Classroom?
    
    func createClassroomNamed(_ name: String, location: CLLocation, passcode: String, completion: ((Classroom?) -> ())?) {
        
        let record = CKRecord(recordType: "Classroom")
        record.setObject(name as CKRecordValue, forKey: "Name")
        record.setObject(passcode as CKRecordValue, forKey: "Passcode")
        record.setObject(location, forKey: "Location")
        cloud.save(record, completionHandler: { record, error in
            guard let record = record else {
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
    
    func linkToClassroom(_ classroom: Classroom) {
        let name = classroom.record.recordID.recordName
        data.setValue(name, forKey: RZClassroomIDKey)
        data.setValue(classroom.passcode, forKey: RZClassroomPasscodeKey)
        self.currentClassroom = classroom
    }
    
    func hasLinkedClassroom() -> Bool {
        return data.value(forKey: RZClassroomIDKey) != nil
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
    
    func getLinkedClassroom(_ completion: @escaping (Classroom?) -> ()) {
        if let classroom = currentClassroom {
            completion(classroom)
            return
        }
        
        getLinkedClassroomFromCloud(completion)
    }
    
    func getLinkedClassroomPasscode() -> String? {
        return data.string(forKey: RZClassroomPasscodeKey)
    }
    
    func getLinkedClassroomFromCloud(_ completion: @escaping (Classroom?) -> ()) {
        if let classroomName = data.string(forKey: RZClassroomIDKey) {
            let recordID = CKRecord.ID(recordName: classroomName)
            cloud.fetch(withRecordID: recordID, completionHandler: { record, error in
                if let error = error { print(error.localizedDescription) }
                if let record = record {
                    let classroom = Classroom(record: record)
                    self.currentClassroom = classroom
                    sync() {
                        completion(classroom)
                    }
                } else {
                    
                    if let error = error, (error as NSError).code == 11 {
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
    
    func userLoggedIn(_ completion: @escaping (Bool) -> ()) {
        CKContainer.default().accountStatus(completionHandler: { status, error in
            sync() {
                completion(status == .available)
            }
        })
    }
    
    func getNearbyClassrooms(_ location: CLLocation, completion: @escaping ([Classroom]) -> ()) {
        let predicate = NSPredicate(format: "distanceToLocation:fromLocation:(Location, %@) < 8047", location) //within 5 miles
        let query = CKQuery(recordType: "Classroom", predicate: predicate)
        query.sortDescriptors = [CKLocationSortDescriptor(key: "Location", relativeLocation: location)]
        cloud.perform(query, inZoneWith: nil, completionHandler: classroomQueryCompletionHandler(reverseResults: false, completion: completion) as! ([CKRecord]?, Error?) -> Void)
    }
    
    func getClassroomsMatchingText(_ text: String, location: CLLocation?, completion: @escaping ([Classroom]) -> ()) {
        let predicate = NSPredicate(format: "Name BEGINSWITH %@", text)
        let query = CKQuery(recordType: "Classroom", predicate: predicate)
        if let location = location {
            query.sortDescriptors = [CKLocationSortDescriptor(key: "Location", relativeLocation: location)]
        } else {
            query.sortDescriptors = [NSSortDescriptor(key: "Name", ascending: true)]
        }
        cloud.perform(query, inZoneWith: nil, completionHandler: classroomQueryCompletionHandler(reverseResults: false, completion: completion) as! ([CKRecord]?, Error?) -> Void)
    }
    
    fileprivate func classroomQueryCompletionHandler(reverseResults: Bool, completion: @escaping ([Classroom]) -> ()) -> ([CKRecord]?, NSError?) -> () {
        
        func classroomQueryCompletionHandler(_ results: [CKRecord]?, error: NSError?) {
            
            if let error = error {
                print(error.localizedDescription)
            }
            
            if let records = results {
                var classrooms: [Classroom] = []
                for record in records {
                    classrooms.append(Classroom(record: record))
                }
                
                if reverseResults {
                    classrooms = Array(classrooms.reversed())
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
    
    func saveClassroom(_ classroom: Classroom) {
        let record = classroom.getUpdatedRecord()
        let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        operation.modifyRecordsCompletionBlock = { _, _, error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
        self.cloud.add(operation)
    }
    
    func refreshLinkedClassroomData(_ completion: ((_ classroom: Classroom, _ changesFound: Bool) -> ())?) {
        if let currentClassroom = self.currentClassroom {
            getLinkedClassroomFromCloud({ classroom in
                if let classroom = classroom {
                    let previousModified = (currentClassroom.record.modificationDate ?? .distantPast).timeIntervalSince1970
                    let currentModified = (classroom.record.modificationDate ?? .distantPast) .timeIntervalSince1970
                    completion?(classroom, currentModified > previousModified)
                }
            })
        }
    }
    
    func deleteClassroom(_ classroom: Classroom) {
        let record = classroom.getUpdatedRecord()
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [record.recordID])
        operation.modifyRecordsCompletionBlock = { _, _, error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
        self.cloud.add(operation)
    }
    
    //MARK: - CloudKit User Management
    
    func getUsersForClassroom(_ classroom: Classroom, completion: @escaping ([User]) -> ()) {
        let predicate = NSPredicate(format: "Classroom = %@", classroom.record.recordID)
        let query = CKQuery(recordType: "User", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "UserString", ascending: true)]
        cloud.perform(query, inZoneWith: nil, completionHandler: { results, error in
            
            var users: [User] = []
            
            if let records = results {
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
    
    func saveUserToLinkedClassroom(_ user: User) {
        getLinkedClassroom({ classroom in
            if let classroom = classroom {
                if let record = user.getUpdatedRecord(classroom) {
                    let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
                    operation.modifyRecordsCompletionBlock = { _, _, error in
                        if let error = error {
                            print(error.localizedDescription)
                        }
                    }
                    self.cloud.add(operation)
                }
            }
        })
    }
    
    func saveNewUserToLinkedClassroom(_ newUser: User) {
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
    
    func refreshUser(_ user: User) {
        if let currentRecord = user.record {
            cloud.fetch(withRecordID: currentRecord.recordID, completionHandler: { record, error in
                if let record = record {
                    let previousModified = (currentRecord.modificationDate ?? .distantPast).timeIntervalSince1970
                    let currentModified = (record.modificationDate ?? .distantPast).timeIntervalSince1970
                    if currentModified > previousModified {
                        user.record = record
                        user.pullDataFromCloud()
                    }
                }
            })
        }
    }
    
}

class User : NSObject {
    
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
        super.init()
        RZUserDatabase.saveNewUserToLinkedClassroom(self)
    }
    
    ///creates a new user with a unique ID
    init(name: String, iconName: String, passcode: String?) {
        self.name = name
        self.iconName = iconName
        self.icon = UIImage(named: iconName)!
        self.ID = name + "\(arc4random_uniform(10000))"
        self.passcode = passcode
        super.init()
        RZUserDatabase.saveNewUserToLinkedClassroom(self)
    }
    
    
    init?(fromString string: String) {
        let splits = string.components(separatedBy: "~")
        if splits.count != 3 {
            name = ""
            iconName = ""
            ID = ""
            super.init()
            return nil
        }
        name = splits[0]
        ID = splits[1]
        iconName = splits[2]
        icon = UIImage(named: iconName)
        super.init()
    }
    
    convenience init?(record: CKRecord) {
        let userString = record.value(forKey: "UserString") as! String
        self.init(fromString: userString)
        self.passcode = record.value(forKey: "Passcode") as? String
        self.record = record
    }
    
    func toUserString() -> String {
        return name + "~" + ID + "~" + iconName
    }
    
    func dateLastModified() -> Date? {
        let modified = record?.modificationDate
        let created = record?.creationDate
        //let's not count creation as a modification
        return created == modified ? nil : modified
    }
    
    func getUpdatedRecord(_ classroom: Classroom) -> CKRecord? {
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
        
        record.setObject(toUserString() as CKRecordValue, forKey: "UserString")
        record.setObject(self.passcode! as CKRecordValue, forKey: "Passcode")
        record.setObject(dictToArray(RZQuizDatabase.getQuizData()) as CKRecordValue, forKey: "QuizData")
        record.setObject(CKRecord.Reference(record: classroom.record, action: .deleteSelf), forKey: "Classroom")
        record.setObject(RZQuizDatabase.getFavorites() as CKRecordValue, forKey: "Favorites")
        record.setObject(RZQuizDatabase.getPlayerBalance() as CKRecordValue, forKey: "Balance")
        record.setObject(RZQuizDatabase.getOwnedAnimals() as CKRecordValue, forKey: "OwnedAnimals")
        record.setObject(RZQuizDatabase.currentZooLevel() as CKRecordValue, forKey: "ZooLevel")
        record.setObject(RZQuizDatabase.currentLevel() as CKRecordValue, forKey: "QuizLevel")
        record.setObject(RZQuizDatabase.getKeeperString() as CKRecordValue, forKey: "Zookeeper")
        record.setObject(RZQuizDatabase.getTotalMoneyEarnedArray() as CKRecordValue, forKey: "TotalMoneyEarned")
        record.setObject("\(RZQuizDatabase.hasWatchedWelcomeVideo())" as CKRecordValue, forKey: "HasWatchedWelcomeVideo")
        record.setObject(RZQuizDatabase.getPercentCorrectArray() as CKRecordValue, forKey: "PercentCorrect")
        
        RZCurrentUser = actualUser
        return record
    }
    
    @discardableResult
    func pullDataFromCloud() -> Bool {
        if let record = record {
            
            //get from CKRecord
            let quizData = record.value(forKey: "QuizData") as? [String] ?? []
            let favorites = record.value(forKey: "Favorites") as? [Int] ?? []
            let balance = record.value(forKey: "Balance") as? Double ?? 0
            let ownedAnimals = record.value(forKey: "OwnedAnimals") as? [String] ?? []
            let zooLevel = record.value(forKey: "ZooLevel") as? Int ?? 1
            let quizLevel = record.value(forKey: "QuizLevel") as? Int ?? 1
            let keeperString = record.value(forKey: "Zookeeper") as? String ?? "boy~1"
            let totalMoneyEarned = record.value(forKey: "TotalMoneyEarned") as? [String] ?? []
            let hasWatchedWelcomeVideo = record.value(forKey: "HasWatchedWelcomeVideo") as? String ?? "false"
            let percentCorrect = record.value(forKey: "PercentCorrect") as? [String] ?? []
            
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
            RZQuizDatabase.setPercentCorrectArray(percentCorrect)
            
            RZCurrentUser = actualUser
            return true
            
        }
        else {
            return false
        }
    }
    
    func useQuizDatabase(_ function: () -> ()) {
        let actualUser = RZCurrentUser
        RZCurrentUser = self
        function()
        RZCurrentUser = actualUser
    }
    
    func useQuizDatabaseToReturn<T>(_ function: () -> (T)) -> T {
        let actualUser = RZCurrentUser
        RZCurrentUser = self
        let willReturn = function()
        RZCurrentUser = actualUser
        return willReturn
    }
    
    func findHighestCompletedRhyme() -> Rhyme? {
        return useQuizDatabaseToReturn() {
            var highestRhyme: Rhyme?
            var highestIndex: Int = 0
            
            for (numberString, _) in RZQuizDatabase.getQuizData() {
                if let number = Int(numberString) {
                    let rhyme = Rhyme(number)
                    let index = RZQuizDatabase.getIndexForRhyme(rhyme)
                    if index > highestIndex {
                        highestRhyme = rhyme
                        highestIndex = index
                    }
                }
            }
            
            return highestRhyme
        }
    }
    
}

//MARK: - Classroom Settings

let RZSettingRequirePasscode = ClassroomSetting("Require Student Passcodes", "Students will have to type their passcode to play.", true)
let RZSettingUserCreation = ClassroomSetting("Allow students to create new Users", "Students will be able to create new user accounts.", false)
let RZSettingSkipVideos = ClassroomSetting("Allow students to skip videos", "Students will be able to skip videos, possibly missing important info.", true)

let RZClassroomSettings = [RZSettingRequirePasscode, RZSettingUserCreation, RZSettingSkipVideos]

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
        
        if let setting = data.string(forKey: self.key) {
            return setting == "true"
        }
        
        //return default if there is nothing set
        return byDefault
    }
    
    func updateSetting(_ new: Bool) {
        data.setValue("\(new)", forKey: self.key)
        
        RZUserDatabase.getLinkedClassroom({ classroom in
            if let classroom = classroom {
                RZUserDatabase.saveClassroom(classroom)
            }
        })
    }
    
    func updateSettingFromCloud(_ newString: String) {
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
        name = record.value(forKey: "Name") as! String
        location = record.value(forKey: "Location") as! CLLocation
        passcode = record.value(forKey: "Passcode") as! String
        
        //load settings
        if let settingsArray = record.value(forKey: "Settings") as? [String] {
            let cloudSettings = arrayToDict(settingsArray)
            for setting in RZClassroomSettings {
                if let userInput = cloudSettings[setting.name] {
                    setting.updateSettingFromCloud(userInput)
                }
            }
        }
        
    }
    
    func getUpdatedRecord() -> CKRecord {
        record.setObject(passcode as CKRecordValue, forKey: "Passcode")
        
        //create settings dictionary
        var cloudSettings: [String : String] = [:]
        for setting in RZClassroomSettings {
            if let current = setting.currentSetting() {
                cloudSettings.updateValue("\(current)", forKey: setting.name)
            }
        }
        
        let settingsArray = dictToArray(cloudSettings)
        record.setObject(settingsArray as CKRecordValue, forKey: "Settings")
        
        return record
    }
    
}
