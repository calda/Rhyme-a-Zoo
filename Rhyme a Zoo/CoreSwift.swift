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
    
    enum FailureReason {
        case PermissionsDenied
        case LocationServicesDisabled
        case Error(NSError)
    }
    
    var waitingForAuthorization: [(completion: (CLLocation) -> (), failure: ((FailureReason) -> ())?)] = []
    var waitingForUpdate: [(completion: (CLLocation) -> (), failure: ((FailureReason) -> ())?)] = []
    var manager = CLLocationManager()
    
    ///Manager must be kept as a strong reference at the class-level.
    init(accuracy: CLLocationAccuracy) {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = accuracy
    }
    
    func getCurrentLocation(completion: (CLLocation) -> (), failure: ((FailureReason) -> ())? ) {
        let auth = CLLocationManager.authorizationStatus()
        if auth == .Restricted || auth == .Denied {
            failure?(.PermissionsDenied)
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
        getCurrentLocation(completion, failure: nil)
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        for (completion, failure) in waitingForAuthorization {
            if status == .AuthorizedWhenInUse {
                updateLocationIfEnabled(completion, failure: failure)
            }
            else {
                failure?(.PermissionsDenied)
            }
        }
        waitingForAuthorization = []
    }
    
    private func updateLocationIfEnabled(completion: (CLLocation) -> (), failure: ((FailureReason) -> ())?) {
        if !CLLocationManager.locationServicesEnabled() {
            failure?(.LocationServicesDisabled)
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
            failure?(.Error(error))
        }
        waitingForUpdate = []
        manager.stopUpdatingLocation()
    }
    
}








