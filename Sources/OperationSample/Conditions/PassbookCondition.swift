//
//  PassbookCondition.swift
//  
//
//  Created by viwii on 2019/9/10.
//

#if os(iOS) && canImport(PassKit)

import Foundation
import PassKit

/// A condition for verifying that Passbook exists and is accessible.
public struct PassbookCondition: OperationCondition {
    
    public static let name = "Passbook"
    public static let isMutuallyExclusive = false
    
    public init() { }
    
    public func dependency(for operation: AnyOperation) -> Operation? {
        /*
            There's nothing you can do to make Passbook available if it's not
            on your device.
        */
        nil
    }
    
    public func evaluate(for operation: AnyOperation, completion: @escaping (Result<Void, NSError>) -> Void) {
        if PKPassLibrary.isPassLibraryAvailable() {
            completion(.success(()))
        } else {
            let error = NSError(
                code: .conditionFailed,
                userInfos: [.operationConditionKey : PassbookCondition.name]
            )
            completion(.failure(error))
        }
    }
    
}

#endif
