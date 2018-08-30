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
func delay(_ delay: Double, closure: @escaping ()->()) {
    let time = DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
    DispatchQueue.main.asyncAfter(deadline: time, execute: closure)
}


///play a CATransition for a UIView
func playTransitionForView(_ view: UIView, duration: Double, transition transitionName: String) {
    playTransitionForView(view, duration: duration, transition: transitionName, subtype: nil)
}

///play a CATransition for a UIView
func playTransitionForView(_ view: UIView, duration: Double, transition transitionName: String, subtype: String?) {
    let subtype = subtype
    let transition = CATransition()
    transition.duration = duration
    transition.timingFunction = CAMediaTimingFunction(name: .easeOut)
    transition.type = convertToCATransitionType(transitionName)
    
    //run fix for transition subtype
    //subtypes don't take device orientation into account
    //let orientation = UIApplication.shared.statusBarOrientation
    //if orientation == .LandscapeLeft || orientation == .PortraitUpsideDown {
        //if subtype == kCATransitionFromLeft { subtype = kCATransitionFromRight }
        //else if subtype == kCATransitionFromRight { subtype = kCATransitionFromLeft }
        //else if subtype == kCATransitionFromTop { subtype = kCATransitionFromBottom }
        //else if subtype == kCATransitionFromBottom { subtype = kCATransitionFromTop }
    //}
    
    transition.subtype = convertToOptionalCATransitionSubtype(subtype)
    view.layer.add(transition, forKey: nil)
}

///dimiss a stack of View Controllers until a desired controler is found
func dismissController(_ controller: UIViewController, untilMatch controllerCheck: @escaping (UIViewController) -> Bool) {
    if controllerCheck(controller) {
        return //we made it to our destination
    }
    
    let superController = controller.presentingViewController
    controller.dismiss(animated: false, completion: {
        if let superController = superController {
            dismissController(superController, untilMatch: controllerCheck)
        }
    })
}

///get the top most view controller of the current Application
func getTopController(_ application: UIApplicationDelegate) -> UIViewController? {
    //find the top controller
    var topController: UIViewController?
    
    if let window = application.window, let root = window!.rootViewController {
        topController = root
        while topController!.presentedViewController != nil {
            topController = topController!.presentedViewController
        }
    }
    
    return topController
}

///sorts any [UIView]! by view.tag
func sortOutletCollectionByTag<T : UIView>(_ collection: inout [T]) {
    collection = (collection as NSArray).sortedArray(using: [NSSortDescriptor(key: "tag", ascending: true)]) as! [T]
}


///animates a back and forth shake
func shakeView(_ view: UIView) {
    let animations : [CGFloat] = [20.0, -20.0, 10.0, -10.0, 3.0, -3.0, 0]
    for i in 0 ..< animations.count {
        let frameOrigin = CGPoint(x: view.frame.origin.x + animations[i], y: view.frame.origin.y)
        
        UIView.animate(withDuration: 0.1, delay: TimeInterval(0.1 * Double(i)), options: [], animations: {
           view.frame.origin = frameOrigin
        }, completion: nil)
    }
}


///converts a String dictionary to a String array
func dictToArray(_ dict: [String : String]) -> [String] {
    var array: [String] = []
    
    for item in dict {
        let first = item.0.replacingOccurrences(of: "~", with: "|(#)|", options: [], range: nil)
        let second = item.1.replacingOccurrences(of: "~", with: "|(#)|", options: [], range: nil)
        let combined = "\(first)~\(second)"
        array.append(combined)
    }
    
    return array
}

///converts an array created by the dictToArray: function to the original dictionary
func arrayToDict(_ array: [String]) -> [String : String] {
    var dict: [String : String] = [:]
    
    for item in array {
        let splits = item.components(separatedBy: "~")
        let first = splits[0].replacingOccurrences(of: "|(#)|", with: "~", options: [], range: nil)
        let second = splits[1].replacingOccurrences(of: "|(#)|", with: "~", options: [], range: nil)
        dict.updateValue(second, forKey: first)
    }
    
    return dict
}


///short-form function to run a block synchronously on the main queue
func sync(_ closure: () -> ()) {
    DispatchQueue.main.sync(execute: closure)
}

///short-form function to run a block asynchronously on the main queue
func async(_ closure: @escaping () -> ()) {
    DispatchQueue.main.async(execute: closure)
}


///open to this app's iOS Settings
func openSettings() {
    UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
}


///returns trus if the current device is an iPad
func iPad() -> Bool {
    return UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
}


///a more succinct function call to post a notification
func postNotification(_ name: String, object: AnyObject?) {
    NotificationCenter.default.post(name: Notification.Name(rawValue: name), object: object, userInfo: nil)
}

///Asynchonrously ownsamples the image view's image to match the view's size
func downsampleImageInView(_ imageView: UIImageView) {
    async() {
        let newSize = imageView.frame.size
        let screenScale = UIScreen.main.scale
        let scaleSize = CGSize(width: newSize.width * screenScale, height: newSize.height * screenScale)
        
        if let original = imageView.image, original.size.width > scaleSize.width {
            UIGraphicsBeginImageContext(scaleSize)
            let context = UIGraphicsGetCurrentContext()
            context?.interpolationQuality = CGInterpolationQuality.high
            context?.setShouldAntialias(true)
            original.draw(in: CGRect(origin: CGPoint.zero, size: scaleSize))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            DispatchQueue.main.async(execute: {
                imageView.image = newImage
            })
        }
    }
}

///Converts a URL to a CSV into an array of all of the lines in the CSV.
func csvToArray(_ url: URL) -> [String] {
    let string = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    return string.components(separatedBy: "\r\n")
}


///Crops an image to a circle (if square) or an oval (if rectangular)
func cropImageToCircle(_ image: UIImage) -> UIImage {
    UIGraphicsBeginImageContext(image.size)
    let context = UIGraphicsGetCurrentContext()
    
    let radius = image.size.width / 2
    let imageCenter = CGPoint(x: image.size.width / 2, y: image.size.height / 2)
    context?.beginPath()
    context?.addArc(center: imageCenter, radius: radius, startAngle: 0, endAngle: CGFloat(2 * Double.pi), clockwise: false)
    context?.closePath()
    context?.clip()
    
    context?.scaleBy(x: image.scale, y: image.scale)
    image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))
    
    let cropped = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return cropped!
    
}

//MARK: - Classes

///A touch gesture recognizer that sends events on both .Began (down) and .Ended (up)
class UITouchGestureRecognizer : UIGestureRecognizer {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        self.state = .began
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        self.state = .began
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        self.state = .ended
    }
    
}

///A basic class to manage Location access
class LocationManager : NSObject, CLLocationManagerDelegate {
    
    var waitingForAuthorization: [(completion: (CLLocation) -> (), failure: (LocationFailureReason) -> ())] = []
    var waitingForUpdate: [(completion: (CLLocation) -> (), failure: (LocationFailureReason) -> ())] = []
    var manager = CLLocationManager()
    
    ///Manager must be kept as a strong reference at the class-level.
    init(accuracy: CLLocationAccuracy) {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = accuracy
    }
    
    func getCurrentLocation(_ completion: @escaping (CLLocation) -> (), failure: @escaping (LocationFailureReason) -> () ) {
        let auth = CLLocationManager.authorizationStatus()
        if auth == .restricted || auth == .denied {
            failure(.permissionsDenied)
            return
        }
        
        if auth == .notDetermined {
            waitingForAuthorization.append((completion: completion, failure: failure))
            manager.requestWhenInUseAuthorization()
            return
        }
        
        updateLocationIfEnabled(completion, failure: failure)
        
    }
    
    func getCurrentLocation(_ completion: @escaping (CLLocation) -> ()) {
        getCurrentLocation(completion, failure: { error in })
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        for (completion, failure) in waitingForAuthorization {
            if status == .authorizedWhenInUse {
                updateLocationIfEnabled(completion, failure: failure)
            }
            else {
                failure(.permissionsDenied)
            }
        }
        waitingForAuthorization = []
    }
    
    fileprivate func updateLocationIfEnabled(_ completion: @escaping (CLLocation) -> (), failure: @escaping (LocationFailureReason) -> ()) {
        if !CLLocationManager.locationServicesEnabled() {
            failure(.locationServicesDisabled)
            return
        }
        
        waitingForUpdate.append((completion: completion, failure: failure))
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            for (completion, _) in waitingForUpdate {
                completion(location)
            }
        }
        waitingForUpdate = []
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        for (_, failure) in waitingForUpdate {
            failure(.error(error as NSError))
        }
        waitingForUpdate = []
        manager.stopUpdatingLocation()
    }
    
}

enum LocationFailureReason {
    case permissionsDenied
    case locationServicesDisabled
    case error(NSError)
}

///Standard Stack data structure

struct Stack<T> {
    
    var array : [T] = []
    
    mutating func push(_ push: T) {
        array.append(push)
    }
    
    mutating func pop() -> T? {
        if array.count == 0 { return nil }
        let count = array.count
        let pop = array[count - 1]
        array.removeLast()
        return pop
    }
    
    var count: Int {
        return array.count
    }
    
}

//MARK: - Standard Library Extensions

extension Int {
    ///Converts an integer to a standardized three-character string. 1 -> 001. 99 -> 099. 123 -> 123.
    var threeCharacterString: String {
        let start = "\(self)"
        if start.count == 1 { return "00\(start)" }
        else if start.count == 2 { return "0\(start)" }
        else { return start }
    }
}

extension NSObject {
    ///Short-hand function to register a notification observer
    func observeNotification(_ name: String, selector: Selector) {
        NotificationCenter.default.addObserver(self, selector: selector, name: NSNotification.Name(rawValue: name), object: nil)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToCATransitionType(_ input: String) -> CATransitionType {
	return CATransitionType(rawValue: input)
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalCATransitionSubtype(_ input: String?) -> CATransitionSubtype? {
	guard let input = input else { return nil }
	return CATransitionSubtype(rawValue: input)
}
