//
//  CloudContainerCondition.swift
//  
//
//  Created by viwii on 2019/9/10.
//

#if canImport(CloudKit)

import Foundation
import CloudKit

public extension OperationError.UserInfoKey {
    
    static let ckContainerKey = OperationError.UserInfoKey("CKContainer")
}

/// A condition describing that the operation requires access to a specific CloudKit container.
public struct CloudContainerCondition: OperationCondition {
    
    /*
        CloudKit has no problem handling multiple operations at the same time
        so we will allow operations that use CloudKit to be concurrent with each
        other.
    */
    public static let isMutuallyExclusive = false
    public static let name = "CloudContainer"
    

    // this is the container to which you need access.
    public let container: CKContainer
    
    public let permission: CKContainer_Application_Permissions
    
    public init(container: CKContainer, permission: CKContainer_Application_Permissions = []) {
        self.container = container
        self.permission = permission
    }
    
    public func dependency(for operation: AnyOperation) -> Operation? {
        PermissionOperation(container: container, permission: permission)
    }
    
    public func evaluate(for operation: AnyOperation, completion: @escaping (Result<Void, NSError>) -> Void) {
        container.verify(permission, requestingIfNecessary: false) { (error) in
            if let error = error {
                let e = NSError(
                    code: .conditionFailed,
                    userInfos: [
                        .operationConditionKey : CloudContainerCondition.name,
                        .ckContainerKey : self.container,
                        .underlyingErrorKey : error
                    ]
                )
                completion(.failure(e))
            } else {
                completion(.success(()))
            }
        }
    }
}

fileprivate extension CloudContainerCondition {
    
    /**
        This operation asks the user for permission to use CloudKit, if necessary.
        If permission has already been granted, this operation will quickly finish.
    */
    class PermissionOperation: AnyOperation {
        
        let container: CKContainer
        let permission: CKContainer_Application_Permissions
        
        init(container: CKContainer, permission: CKContainer_Application_Permissions) {
            self.container = container
            self.permission = permission
            super.init()
            
            if !permission.isEmpty {
                /*
                    Requesting non-zero permissions means that this potentially presents
                    an alert, so it should not run at the same time as anything else
                    that presents an alert.
                */
                addCondition(AlertPresentation())
            }
        }
        
        override func execute() {
            container.verify(permission, requestingIfNecessary: true) { (error) in
                self.finish(with: error)
            }
        }
    }
}

#endif
