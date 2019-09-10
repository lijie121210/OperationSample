//
//  NoCancelledDependencies.swift
//  
//
//  Created by viwii on 2019/9/9.
//

import Foundation

public extension OperationError.UserInfoKey {
    
    static let cancelledDependenciesKey = OperationError.UserInfoKey("CancelledDependencies")
}

/**
    A condition that specifies that every dependency must have succeeded.
    If any dependency was cancelled, the target operation will be cancelled as
    well.
*/
public struct NoCancelledDependencies: OperationCondition {
    
    public static let name = "NoCancelledDependencies"
    public static let isMutuallyExclusive = false
    
    init() { }
    
    public func dependency(for operation: AnyOperation) -> Operation? {
        nil
    }
    
    public func evaluate(for operation: AnyOperation, completion: (Result<Void, NSError>) -> Void) {
        // Verify that all of the dependencies executed.
        let cancelled = operation.dependencies.filter { $0.isCancelled }
        
        guard !cancelled.isEmpty else {
            completion(.success(()))
            return
        }
        
        // At least one dependency was cancelled; the condition was not satisfied.
        let error = NSError(
            code: .conditionFailed,
            userInfos: [
                .operationConditionKey : NoCancelledDependencies.name,
                .cancelledDependenciesKey : cancelled
            ]
        )
        completion(.failure(error))
    }
}
