//
//  LocationCondition.swift
//  
//
//  Created by viwii on 2019/9/9.
//

#if canImport(CoreLocation)

import Foundation
import CoreLocation

public extension OperationError.UserInfoKey {
    
    static let locationServicesEnabledKey = OperationError.UserInfoKey("CLLocationServicesEnabled")
    static let authorizationStatusKey = OperationError.UserInfoKey("CLAuthorizationStatus")
}

public extension LocationCondition {
    
    /**
        Declare a new enum instead of using `CLAuthorizationStatus`, because that
        enum has more case values than are necessary for our purposes.
    */
    enum Usage {
        case whenInUse
        case always
    }
}

/// A condition for verifying access to the user's location.
public struct LocationCondition: OperationCondition {
    
    public static let name = "Location"
    public static let isMutuallyExclusive = false
    
    public let usage: Usage
    
    public init(usage: Usage) {
        self.usage = usage
    }
    
    public func dependency(for operation: AnyOperation) -> Operation? {
        LocationPermissionOperation(usage: usage)
    }
    
    public func evaluate(for operation: AnyOperation, completion: (Result<Void, NSError>) -> Void) {
        let enabled = CLLocationManager.locationServicesEnabled()
        let actual = CLLocationManager.authorizationStatus()
        
        var error: NSError?
        
        // There are several factors to consider when evaluating this condition
        switch (enabled, usage, actual) {
        case (true, _, .authorizedAlways):
            // The service is enabled, and we have "Always" permission -> condition satisfied.
            break
        case (true, .whenInUse, .authorizedWhenInUse):
            /*
                The service is enabled, and we have and need "WhenInUse"
                permission -> condition satisfied.
            */
            break
        default:
            /*
                Anything else is an error. Maybe location services are disabled,
                or maybe we need "Always" permission but only have "WhenInUse",
                or maybe access has been restricted or denied,
                or maybe access hasn't been request yet.
                
                The last case would happen if this condition were wrapped in a `SilentCondition`.
            */
            error = NSError(
                code: .conditionFailed,
                userInfos: [
                    .operationConditionKey : LocationCondition.name,
                    .locationServicesEnabledKey : enabled,
                    .authorizationStatusKey : Int(actual.rawValue)
                ]
            )
        }
        
        if let e = error {
            completion(.failure(e))
        } else {
            completion(.success(()))
        }
    }
}

public extension LocationCondition.Usage {
    
    var infoKey: String {
        switch self {
            case .whenInUse: return "NSLocationWhenInUseUsageDescription"
            case .always: return "NSLocationAlwaysUsageDescription"
        }
    }
}

/**
    A private `Operation` that will request permission to access the user's location,
    if permission has not already been granted.
*/
private class LocationPermissionOperation: AnyOperation {
    
    let usage: LocationCondition.Usage
    var manager: CLLocationManager?
    
    init(usage: LocationCondition.Usage) {
        self.usage = usage
        super.init()
        
        /*
            This is an operation that potentially presents an alert so it should
            be mutually exclusive with anything else that presents an alert.
        */
        addCondition(AlertPresentation())
    }
    
    override func execute() {
        /*
            Not only do we need to handle the "Not Determined" case, but we also
            need to handle the "upgrade" (.WhenInUse -> .Always) case.
        */
        switch (CLLocationManager.authorizationStatus(), usage) {
        case (.notDetermined, _), (.authorizedWhenInUse, .always):
            DispatchQueue.main.async {
                self.requestPermission()
            }
        default:
            finish()
        }
    }
    
    private func requestPermission() {
        manager = CLLocationManager()
        manager?.delegate = self
        
        switch usage {
            case .whenInUse:
                manager?.requestWhenInUseAuthorization()
            case .always:
                manager?.requestAlwaysAuthorization()
        }
        
        let key = usage.infoKey

        // This is helpful when developing the app.
        
        assert(Bundle.main.object(forInfoDictionaryKey: key) != nil, "Requesting location permission requires the \(key) key in your Info.plist")
    }
}

extension LocationPermissionOperation: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if manager == self.manager, isExecuting, status != .notDetermined {
            finish()
        }
    }
}

#endif
