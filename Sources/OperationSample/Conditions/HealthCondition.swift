//
//  HealthCondition.swift
//  
//
//  Created by viwii on 2019/9/10.
//

#if os(iOS) && canImport(HealthKit) && canImport(UIKit)

import Foundation
import HealthKit
import UIKit

public extension OperationError.UserInfoKey {
    
    static let healthDataAvailable = OperationError.UserInfoKey("HealthDataAvailable")
    static let unauthorizedShareTypesKey = OperationError.UserInfoKey("UnauthorizedShareTypes")

}

public struct HealthCondition: OperationCondition {
    
    public static let name = "Health"
    public static let isMutuallyExclusive = false
    
    public let shareTypes: Set<HKSampleType>
    public let readTypes: Set<HKSampleType>
    
    /**
        The designated initializer.
        
        - parameter typesToWrite: An array of `HKSampleType` objects, indicating
            the kinds of data you wish to save to HealthKit.

        - parameter typesToRead: An array of `HKSampleType` objects, indicating
            the kinds of data you wish to read from HealthKit.
    */
    public init(typesToWrite w: Set<HKSampleType>, read r: Set<HKSampleType>) {
        shareTypes = w
        readTypes = r
    }
    
    public func dependency(for operation: AnyOperation) -> Operation? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }
        guard !shareTypes.isEmpty || !readTypes.isEmpty else { return nil }
        return PermissionOperation(typesToWrite: shareTypes, read: readTypes)
    }
    
    public func evaluate(for operation: AnyOperation, completion: @escaping (Result<Void, NSError>) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            failed(unauthorizedShareTypes: shareTypes, completion: completion)
            return
        }
        
        let store = HKHealthStore()
        
        /*
            Note that we cannot check to see if access to the "typesToRead"
            has been granted or not, as that is sensitive data. For example,
            a person with diabetes may choose to not allow access to Blood Glucose
            data, and the fact that this request has denied is itself an indicator
            that the user may have diabetes.
            
            Thus, we can only check to see if we've been given permission to
            write data to HealthKit.
        */
        let unauthorizedShareTypes = shareTypes.filter { store.authorizationStatus(for: $0) != .sharingAuthorized }
        
        if unauthorizedShareTypes.isEmpty {
            completion(.success(()))
        } else {
            failed(unauthorizedShareTypes: unauthorizedShareTypes, completion: completion)
        }
    }
    
    private func failed(unauthorizedShareTypes: Set<HKSampleType>, completion: (Result<Void, NSError>) -> Void) {
        let error = NSError(
            code: .conditionFailed,
            userInfos: [
                .operationConditionKey : HealthCondition.name,
                .healthDataAvailable : HKHealthStore.isHealthDataAvailable(),
                .unauthorizedShareTypesKey : unauthorizedShareTypes
            ]
        )
        completion(.failure(error))
    }
}

fileprivate extension HealthCondition {
    
    /**
        A private `Operation` that will request access to the user's health data, if
        it has not already been granted.
    */
    class PermissionOperation: AnyOperation {
        
        let shareTypes: Set<HKSampleType>
        let readTypes: Set<HKSampleType>
        
        init(typesToWrite w: Set<HKSampleType>, read r: Set<HKSampleType>) {
            shareTypes = w
            readTypes = r
            
            super.init()
            
            addCondition(MutuallyExclusive<PermissionOperation>())
            addCondition(MutuallyExclusive<UIViewController>())
            addCondition(AlertPresentation())
        }
        
        override func execute() {
            DispatchQueue.main.async {
                let store = HKHealthStore()
                /*
                    This method is smart enough to not re-prompt for access if access
                    has already been granted.
                */
                
                store.requestAuthorization(toShare: self.shareTypes, read: self.readTypes) { (granted, error) in
                    self.finish()
                }
            }
        }
    }
}

#endif
