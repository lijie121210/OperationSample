//
//  LocationOperation.swift
//  
//
//  Created by viwii on 2019/9/9.
//

#if canImport(CoreLocation)

import Foundation
import CoreLocation

/**
    `LocationOperation` is an `Operation` subclass to do a "one-shot" request to
    get the user's current location, with a desired accuracy. This operation will
    prompt for `WhenInUse` location authorization, if the app does not already
    have it.
*/
open class LocationOperation: AnyOperation, CLLocationManagerDelegate {
    
    // MARK: Properties

    private var manager: CLLocationManager?
    private let accuracy: CLLocationAccuracy
    private let handler: (CLLocation) -> Void
    
    // MARK: Initialization
    
    init(accuracy: CLLocationAccuracy, handler: @escaping (CLLocation) -> Void) {
        self.accuracy = accuracy
        self.handler = handler
        super.init()
        
    }
}

#endif
