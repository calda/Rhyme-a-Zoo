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
var RZCurrentUser: User = User(emptyUserWithName: "default user", iconName: "angry.jpg")
let RZUsersKey = "com.hearatale.raz.users"
let RZClassroomIDKey = "com.hearatale.raz.classroom"

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
        self.currentClassroom = classroom
    }
    
    func unlinkClassroom() {
        data.setValue(nil, forKey: RZClassroomIDKey)
        currentClassroom = nil
    }
    
    func getLinkedClassroom(completion: (Classroom?) -> ()) {
        if let classroom = currentClassroom {
            completion(classroom)
        }
        if let classroomName = data.stringForKey(RZClassroomIDKey) {
            let recordID = CKRecordID(recordName: classroomName)
            cloud.fetchRecordWithID(recordID, completionHandler: { record, error in
                println(error)
                if record != nil {
                    let classroom = Classroom(record: record)
                    sync() {
                        completion(classroom)
                    }
                } else {
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
                    let saveOperation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
                    self.cloud.addOperation(saveOperation)
                }
            }
        })
    }
    
}

class User {
    
    let name: String
    var icon: UIImage?
    var iconName: String
    let ID: String
    
    var record: CKRecord?
    
    init(emptyUserWithName name: String, iconName: String) {
        self.name = name
        self.iconName = iconName
        self.icon = UIImage(named: iconName)!
        ID = name + "\(arc4random_uniform(10000))"
    }
    
    ///creates a new user with a unique ID
    init(name: String, iconName: String) {
        self.name = name
        self.iconName = iconName
        self.icon = UIImage(named: iconName)!
        ID = name + "\(arc4random_uniform(10000))"
        RZUserDatabase.saveUserToLinkedClassroom(self)
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
        self.record = record
    }
    
    func toUserString() -> String {
        return name + "~" + ID + "~" + iconName
    }
    
    func getUpdatedRecord(classroom: Classroom) -> CKRecord? {
        let actualUser = RZCurrentUser
        RZCurrentUser = self
        
        if let record = self.record {
            record.setObject(toUserString(), forKey: "UserString")
            record.setObject(dictToArray(RZQuizDatabase.getQuizData()), forKey: "QuizData")
            record.setObject(CKReference(record: classroom.record, action: CKReferenceAction.DeleteSelf), forKey: "Classroom")
            record.setObject(RZQuizDatabase.getFavorites(), forKey: "Favorites")
            record.setObject(RZQuizDatabase.getPlayerBalance(), forKey: "Balance")
            record.setObject(RZQuizDatabase.getOwnedAnimals(), forKey: "OwnedAnimals")
            record.setObject(RZQuizDatabase.currentZooLevel(), forKey: "ZooLevel")
            record.setObject(RZQuizDatabase.currentLevel(), forKey: "QuizLevel")
            record.setObject(RZQuizDatabase.getKeeperString(), forKey: "Zookeeper")
        }
        
        RZCurrentUser = actualUser
        return record
    }
    
    func pullDataFromCloud() -> Bool {
        if let record = record {
            
            let quizData = record.valueForKey("QuizData") as! [String]
            let favorites = record.valueForKey("Favorites") as! [Int]
            let balance = record.valueForKey("Balance") as! Double
            let ownedAnimals = record.valueForKey("OwnedAnimals") as! [String]
            let zooLevel = record.valueForKey("ZooLevel") as! Int
            let quizLevel = record.valueForKey("QuizLevel") as! Int
            let keeperString = record.valueForKey("Zookeeper") as! String
            
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
            
            RZCurrentUser = actualUser
            return true
            
        }
        else {
            return false
        }
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
