//
//  CalendarCondition.swift
//  
//
//  Created by viwii on 2019/9/10.
//

#if canImport(EventKit)

import Foundation
import EventKit

public extension OperationError.UserInfoKey {
    
    static let ekEntityTypeKey = OperationError.UserInfoKey("EKEntityType")
}

/// A condition for verifying access to the user's calendar.
public struct CalendarCondition: OperationCondition {
    
    public static let name = "Calendar"
    public static let isMutuallyExclusive = false
    
    public let entityType: EKEntityType
    
    public init(entityType: EKEntityType) {
        self.entityType = entityType
    }
    
    public func dependency(for operation: AnyOperation) -> Operation? {
        PermissionOperation(entityType: entityType)
    }
    
    public func evaluate(for operation: AnyOperation, completion: @escaping (Result<Void, NSError>) -> Void) {
        switch EKEventStore.authorizationStatus(for: entityType) {
        case .authorized:
            completion(.success(()))
        default:
            // We are not authorized to access entities of this type.
            let error = NSError(
                code: .conditionFailed,
                userInfos: [
                    .operationConditionKey : CalendarCondition.name,
                    .ekEntityTypeKey : entityType.rawValue
                ]
            )
            completion(.failure(error))
        }
    }
}

/**
    `EKEventStore` takes a while to initialize, so we should create
    one and then keep it around for future use, instead of creating
    a new one every time a `CalendarPermissionOperation` runs.
*/
private let SharedEventStore = EKEventStore()

fileprivate extension CalendarCondition {
    
    class PermissionOperation: AnyOperation {
        
        let entityType: EKEntityType
        
        init(entityType: EKEntityType) {
            self.entityType = entityType
            super.init()
            addCondition(AlertPresentation())
        }
        
        override func execute() {
            let status = EKEventStore.authorizationStatus(for: entityType)
            
            switch status {
            case .notDetermined:
                DispatchQueue.main.async {
                    SharedEventStore.requestAccess(to: self.entityType) { (granted, error) in
                        self.finish()
                    }
                }
            default:
                finish()
            }
        }
    }
}

#endif
