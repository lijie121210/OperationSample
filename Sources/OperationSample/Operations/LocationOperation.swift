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
    
    public init(accuracy: CLLocationAccuracy, handler: @escaping (CLLocation) -> Void) {
        self.accuracy = accuracy
        self.handler = handler
        
        super.init()
        
        addCondition(LocationCondition(usage: .whenInUse))
        addCondition(MutuallyExclusive<CLLocationManager>())
    }
    
    open override func execute() {
        DispatchQueue.main.async {
            /*
                `CLLocationManager` needs to be created on a thread with an active
                run loop, so for simplicity we do this on the main queue.
            */
            let manager = CLLocationManager()
            manager.desiredAccuracy = self.accuracy
            manager.delegate = self
            manager.startUpdatingLocation()
            
            self.manager = manager
        }
    }
    
    open override func cancel() {
        DispatchQueue.main.async {
            self.stopLocationUpdates()
            super.cancel()
        }
    }
    
    private func stopLocationUpdates() {
        manager?.stopUpdatingLocation()
        manager = nil
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last(where: { $0.horizontalAccuracy <= accuracy }) else {
            return
        }
        
        stopLocationUpdates()
        handler(location)
        finish()
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        stopLocationUpdates()
        finish(with: error as NSError)
    }
}

#endif
