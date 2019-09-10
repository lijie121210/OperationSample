//
//  OperationObserver.swift
//  
//
//  Created by viwii on 2019/9/8.
//

import Foundation

/**
    The protocol that types may implement if they wish to be notified of significant
    operation lifecycle events.
*/
public protocol OperationObserver {
    
    /// Invoked immediately prior to the `Operation`'s `execute()` method.
    func operationDidStart(_ operation: AnyOperation)
    
    /// Invoked when `Operation.produceOperation(_:)` is executed.
    func operation(_ operation: AnyOperation, didProduceOperation newOperation: Operation)
    
    /**
        Invoked as an `Operation` finishes, along with any errors produced during
        execution (or readiness evaluation).
    */
    func operation(_ operation: AnyOperation, didFinishWithErrors: [NSError])
    
}
