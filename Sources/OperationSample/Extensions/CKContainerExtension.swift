//
//  CKContainerExtension.swift
//  
//
//  Created by viwii on 2019/9/8.
//

import Foundation
import CloudKit

public extension CKContainer {
    
    /**
        Verify that the current user has certain permissions for the `CKContainer`,
        and potentially requesting the permission if necessary.
        
        - parameter permission: The permissions to be verified on the container.

        - parameter shouldRequest: If this value is `true` and the user does not
            have the passed `permission`, then the user will be prompted for it.

        - parameter completion: A closure that will be executed after verification
            completes. The `NSError` passed in to the closure is the result of either
            retrieving the account status, or requesting permission, if either
            operation fails. If the verification was successful, this value will
        be `nil`.
    */
    func verify(_ permission: CKContainer_Application_Permissions, requestingIfNecessary shouldRequest: Bool = false, completion: @escaping (NSError?) -> Void) {
        __container(container: self, verifyAccountStatus: permission, shouldRequest: shouldRequest, completion: completion)
    }
}

/**
    Make these helper functions instead of helper methods, so we don't pollute
    `CKContainer`.
*/
private func __container(container: CKContainer, verifyAccountStatus permission: CKContainer_Application_Permissions, shouldRequest: Bool, completion: @escaping (NSError?) -> Void) {
    container.accountStatus { (status, error) in
        guard status == .available else {
            let e = permissionError(from: error, defaultCode: CKError.Code.notAuthenticated.rawValue)
            completion(e)
            return
        }
        if permission != [] {
            __container(container: container, verify: permission, shouldRequest: shouldRequest, completion: completion)
        } else {
            completion(nil)
        }
    }
}

private func __container(container: CKContainer, verify permission: CKContainer_Application_Permissions, shouldRequest: Bool, completion: @escaping (NSError?) -> Void) {
    container.status(forApplicationPermission: permission) { (status, error) in
        if status == .granted {
            completion(nil)
            return
        }
        
        if status == .initialState && shouldRequest {
            __container(container: container, request: permission, completion: completion)
            return
        }
        
        let e = permissionError(from: error, defaultCode: CKError.Code.permissionFailure.rawValue)
        completion(e)
    }
}

private func __container(container: CKContainer, request permission: CKContainer_Application_Permissions, completion: @escaping (NSError?) -> Void) {
    DispatchQueue.main.async {
        container.requestApplicationPermission(permission) { (status, error) in
            if status == .granted {
                completion(nil)
            } else {
                let e = permissionError(from: error, defaultCode: CKError.Code.permissionFailure.rawValue)
                completion(e)
            }
        }
    }
}

private func permissionError(from error: Error?, defaultCode: Int) -> NSError {
    var e = NSError(domain: CKErrorDomain, code: defaultCode, userInfo: nil)
    if let error = error as? CKError {
        e = NSError(domain: CKErrorDomain, code: error.code.rawValue, userInfo: error.userInfo)
    }
    if let error = error as NSError? {
        e = error
    }
    return e
}
