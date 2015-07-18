//
//  UserDatabase.swift
//  Rhyme a Zoo
//
//  Created by Cal on 7/17/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import Foundation
import UIKit

let RZUserDatabase = UserDatabase()
var RZCurrentUser: User = User(name: "default", iconName: "angry.jpg")
let RZUsersKey = "com.hearatale.raz.users"

struct UserDatabase {
    
    func getUsers() -> [User] {
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
    
    func addUser(user: User) {
        var users = getUsers()
        var userStrings: [String] = []
        
        for user in users {
            userStrings.append(user.toString())
        }
        userStrings.append(user.toString())
        data.setValue(userStrings, forKey: RZUsersKey)
    }
    
}

struct User {
    
    let name: String
    let icon: UIImage?
    let iconName: String
    
    init(name: String, iconName: String) {
        self.name = name
        self.iconName = iconName
        self.icon = UIImage(named: iconName)!
    }
    
    init?(fromString string: String) {
        let splits = split(string){ $0 == "~" }
        if splits.count != 2 { return nil }
        name = splits[0]
        iconName = splits[1]
        icon = UIImage(named: iconName)
    }
    
    func toString() -> String {
        return name + "~" + iconName
    }
    
}