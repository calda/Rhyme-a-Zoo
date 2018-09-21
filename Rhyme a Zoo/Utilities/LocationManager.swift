//
//  LocationManager.swift
//  Rhyme a Zoo
//
//  Created by Cal Stephens on 9/5/18.
//  Copyright © 2018 Cal Stephens. All rights reserved.
//

import CoreLocation

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
            failure(.error(error))
        }
        waitingForUpdate = []
        manager.stopUpdatingLocation()
    }
    
}

enum LocationFailureReason {
    case permissionsDenied
    case locationServicesDisabled
    case error(Error)
}

