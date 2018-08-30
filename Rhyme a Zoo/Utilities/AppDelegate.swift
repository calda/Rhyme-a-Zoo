//
//  AppDelegate.swift
//  Rhyme a Zoo
//
//  Created by Cal on 6/28/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import UIKit

let RZAppClosedTimeKey = "com.hearatale.raz.AppClosedTime"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        //save the time that the app was closed
        let time = Date()
        data.setValue(time, forKey: RZAppClosedTimeKey)
        
        RZUserDatabase.saveCurrentUserToLinkedClassroom()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        RZCurrentUser.pullDataFromCloud()
        
        //check if more than five minutes have passed since the app was closed
        if let closedTime = data.value(forKey: RZAppClosedTimeKey) as? Date {
            let currentTime = Date()
            let diff = currentTime.timeIntervalSince(closedTime)
            //FIXME: change to 300
            if diff > 300 { //300 seconds = 5 minutes
                //return to home if only one user
                //return to User screen if users > 1 || users == 0
                
                func controllerIsHome(_ viewController: UIViewController) -> Bool {
                    return viewController is MainViewController
                }
                
                func controllerIsUser(_ viewController: UIViewController) -> Bool {
                    return viewController is UsersViewController
                }
                
                let userCount = RZUserDatabase.getLocalUsers().count
                let controllerCheck: (UIViewController) -> Bool = (userCount == 1 ? controllerIsHome : controllerIsUser)
                
                if let topController = getTopController(self) {
                    //close all of the controllers until we're back to the desired controller
                    //where controllerCheck(...) == true
                    dismissController(topController, untilMatch: controllerCheck)
                }
            }
        }
    }

}
