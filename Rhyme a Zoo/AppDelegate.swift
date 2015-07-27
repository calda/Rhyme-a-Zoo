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


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        //save the time that the app was closed
        let time = NSDate()
        data.setValue(time, forKey: RZAppClosedTimeKey)
    }

    func applicationDidBecomeActive(application: UIApplication) {
        //check if more than five minutes have passed since the app was closed
        if let closedTime = data.valueForKey(RZAppClosedTimeKey) as? NSDate {
            let currentTime = NSDate()
            let diff = currentTime.timeIntervalSinceDate(closedTime)
            //FIXME: change to 300
            if diff > 300 { //300 seconds = 5 minutes
                //return to home if only one user
                //return to User screen if users > 1 || users == 0
                
                func controllerIsHome(viewController: UIViewController) -> Bool {
                    return viewController is MainViewController
                }
                
                func controllerIsUser(viewController: UIViewController) -> Bool {
                    return viewController is UsersViewController
                }
                
                let userCount = RZUserDatabase.getLocalUsers().count
                let controllerCheck: (UIViewController) -> Bool = (userCount == 1 ? controllerIsHome : controllerIsUser)
                
                //find the top controller
                var topController: UIViewController?
                
                if let window = self.window, let root = window.rootViewController {
                    topController = root
                    while topController!.presentedViewController != nil {
                        topController = topController!.presentedViewController
                    }
                }
                
                if let topController = topController {
                    //close all of the controllers until we're back to the desired controller
                    //where controllerCheck(...) == true
                    dismissController(topController, untilMatch: controllerCheck)
                }
            }
        }
    }

}