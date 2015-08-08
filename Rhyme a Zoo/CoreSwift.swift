//  CoreSwift.swift
//
//  A collection of core Swift functions and classes
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import UIKit.UIGestureRecognizerSubclass

//MARK: - Functions

///perform the closure function after a given delay
func delay(delay: Double, closure: ()->()) {
    let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
    dispatch_after(time, dispatch_get_main_queue(), closure)
}


///play a CATransition for a UIView
func playTransitionForView(view: UIView, #duration: Double, transition transitionName: String) {
    let transition = CATransition()
    transition.duration = duration
    transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
    transition.type = transitionName
    view.layer.addAnimation(transition, forKey: nil)
}


///dimiss a stack of View Controllers until a desired controler is found
func dismissController(controller: UIViewController, untilMatch controllerCheck: (UIViewController) -> Bool) {
    if controllerCheck(controller) {
        return //we made it to our destination
    }
    
    let superController = controller.presentingViewController
    controller.dismissViewControllerAnimated(false, completion: {
        if let superController = superController {
            dismissController(superController, untilMatch: controllerCheck)
        }
    })
}


///sorts any [UIView]! by view.tag
func sortOutletCollectionByTag<T : UIView>(inout collection: [T]!) {
    collection = (collection as NSArray).sortedArrayUsingDescriptors([NSSortDescriptor(key: "tag", ascending: true)]) as! [T]
}


///animates a back and forth shake
func shakeView(view: UIView) {
    let animations : [CGFloat] = [20.0, -20.0, 10.0, -10.0, 3.0, -3.0, 0]
    for i in 0 ..< animations.count {
        let frameOrigin = CGPointMake(view.frame.origin.x + animations[i], view.frame.origin.y)
        
        UIView.animateWithDuration(0.1, delay: NSTimeInterval(0.1 * Double(i)), options: nil, animations: {
           view.frame.origin = frameOrigin
        }, completion: nil)
    }
}


///converts a String dictionary to a String array
func dictToArray(dict: [String : String]) -> [String] {
    var array: [String] = []
    
    for item in dict {
        let first = item.0.stringByReplacingOccurrencesOfString("~", withString: "|(#)|", options: nil, range: nil)
        let second = item.1.stringByReplacingOccurrencesOfString("~", withString: "|(#)|", options: nil, range: nil)
        let combined = "\(first)~\(second)"
        array.append(combined)
    }
    
    return array
}

///converts an array created by the dictToArray: function to the original dictionary
func arrayToDict(array: [String]) -> [String : String] {
    var dict: [String : String] = [:]
    
    for item in array {
        let splits = split(item){ $0 == "~" }
        let first = splits[0].stringByReplacingOccurrencesOfString("|(#)|", withString: "~", options: nil, range: nil)
        let second = splits[1].stringByReplacingOccurrencesOfString("|(#)|", withString: "~", options: nil, range: nil)
        dict.updateValue(second, forKey: first)
    }
    
    return dict
}


///short-form function to run a block synchronously on the main queue
func sync(closure: () -> ()) {
    dispatch_sync(dispatch_get_main_queue(), closure)
}

///short-form function to run a block asynchronously on the main queue
func async(closure: () -> ()) {
    dispatch_async(dispatch_get_main_queue(), closure)
}


///open to this app's iOS Settings
func openSettings() {
    UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
}


func iPad() -> Bool {
    return UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad
}


//MARK: - Classes

///A touch gesture recognizer that sends events on both .Began (down) and .Ended (up)
class UITouchGestureRecognizer : UIGestureRecognizer {
    
    override func touchesBegan(touches: Set<NSObject>!, withEvent event: UIEvent!) {
        super.touchesBegan(touches, withEvent: event)
        self.state = .Began
    }
    
    override func touchesMoved(touches: Set<NSObject>!, withEvent event: UIEvent!) {
        super.touchesMoved(touches, withEvent: event)
        self.state = .Began
    }
    
    override func touchesEnded(touches: Set<NSObject>!, withEvent event: UIEvent!) {
        super.touchesEnded(touches, withEvent: event)
        self.state = .Ended
    }
    
}

///A basic class to manage Location access
class LocationManager : NSObject, CLLocationManagerDelegate {
    
    var waitingForAuthorization: [(completion: (CLLocation) -> (), failure: LocationFailureReason -> ())] = []
    var waitingForUpdate: [(completion: (CLLocation) -> (), failure: LocationFailureReason -> ())] = []
    var manager = CLLocationManager()
    
    ///Manager must be kept as a strong reference at the class-level.
    init(accuracy: CLLocationAccuracy) {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = accuracy
    }
    
    func getCurrentLocation(completion: (CLLocation) -> (), failure: LocationFailureReason -> () ) {
        let auth = CLLocationManager.authorizationStatus()
        if auth == .Restricted || auth == .Denied {
            failure(.PermissionsDenied)
            return
        }
        
        if auth == .NotDetermined {
            waitingForAuthorization.append(completion: completion, failure: failure)
            manager.requestWhenInUseAuthorization()
            return
        }
        
        updateLocationIfEnabled(completion, failure: failure)
        
    }
    
    func getCurrentLocation(completion: (CLLocation) -> ()) {
        getCurrentLocation(completion, failure: { error in })
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        for (completion, failure) in waitingForAuthorization {
            if status == .AuthorizedWhenInUse {
                updateLocationIfEnabled(completion, failure: failure)
            }
            else {
                failure(.PermissionsDenied)
            }
        }
        waitingForAuthorization = []
    }
    
    private func updateLocationIfEnabled(completion: (CLLocation) -> (), failure: LocationFailureReason -> ()) {
        if !CLLocationManager.locationServicesEnabled() {
            failure(.LocationServicesDisabled)
            return
        }
        
        waitingForUpdate.append(completion: completion, failure: failure)
        manager.startUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if let location = locations[0] as? CLLocation {
            for (completion, _) in waitingForUpdate {
                completion(location)
            }
        }
        waitingForUpdate = []
        manager.stopUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        for (_, failure) in waitingForUpdate {
            failure(.Error(error))
        }
        waitingForUpdate = []
        manager.stopUpdatingLocation()
    }
    
}

enum LocationFailureReason {
    case PermissionsDenied
    case LocationServicesDisabled
    case Error(NSError)
}

//MARK: - Standard Library Extensions

extension Array {
    ///Returns a copy of the array in random order
    func shuffled() -> [T] {
        var list = self
        for i in 0..<(list.count - 1) {
            let j = Int(arc4random_uniform(UInt32(list.count - i))) + i
            swap(&list[i], &list[j])
        }
        return list
    }
}

extension Int {
    ///Converts an integer to a standardized three-character string. 1 -> 001. 99 -> 099. 123 -> 123.
    func threeCharacterString() -> String {
        let start = "\(self)"
        let length = count(start)
        if length == 1 { return "00\(start)" }
        else if length == 2 { return "0\(start)" }
        else { return start }
    }
}
