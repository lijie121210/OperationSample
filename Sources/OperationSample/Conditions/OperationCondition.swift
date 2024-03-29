//
//  OperationCondition.swift
//  
//
//  Created by viwii on 2019/9/8.
//

import Foundation

extension Result where Success == Void, Failure == NSError {
    
    var error: NSError? {
        if case let .failure(error) = self {
            return error
        }
        return nil
    }
}

/**
    A protocol for defining conditions that must be satisfied in order for an
    operation to begin execution.
*/
public protocol OperationCondition {
    
    /**
        The name of the condition. This is used in userInfo dictionaries of `.ConditionFailed`
        errors as the value of the `OperationConditionKey` key.
    */
    static var name: String { get }
    
    /**
        Specifies whether multiple instances of the conditionalized operation may
        be executing simultaneously.
    */
    static var isMutuallyExclusive: Bool { get }
    
    /**
        Some conditions may have the ability to satisfy the condition if another
        operation is executed first. Use this method to return an operation that
        (for example) asks for permission to perform the operation
        
        - parameter operation: The `Operation` to which the Condition has been added.
        - returns: An `NSOperation`, if a dependency should be automatically added. Otherwise, `nil`.
        - note: Only a single operation may be returned as a dependency. If you
            find that you need to return multiple operations, then you should be
            expressing that as multiple conditions. Alternatively, you could return
            a single `GroupOperation` that executes multiple operations internally.
    */
    func dependency(for operation: AnyOperation) -> Operation?
    
    /// Evaluate the condition, to see if it has been satisfied or not.
    func evaluate(for operation: AnyOperation, completion: @escaping (Result<Void, NSError>) -> Void)
}
