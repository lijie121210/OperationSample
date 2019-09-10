//
//  BlockObserver.swift
//  
//
//  Created by viwii on 2019/9/9.
//

import Foundation

/**
    The `BlockObserver` is a way to attach arbitrary blocks to significant events
    in an `Operation`'s lifecycle.
*/
public struct BlockObserver: OperationObserver {
    
    // MARK: Properties
    
    private let startHandler: ((AnyOperation) -> Void)?
    private let produceHandler: ((AnyOperation, Operation) -> Void)?
    private let finishHandler: ((AnyOperation, [NSError]) -> Void)?
    
    init(startHandler: ((AnyOperation) -> Void)? = nil, produceHandler: ((AnyOperation, Operation) -> Void)? = nil, finishHandler: ((AnyOperation, [NSError]) -> Void)? = nil) {
        self.startHandler = startHandler
        self.produceHandler = produceHandler
        self.finishHandler = finishHandler
    }
    
    // MARK: OperationObserver
    
    public func operationDidStart(_ operation: AnyOperation) {
        startHandler?(operation)
    }
    
    public func operation(_ operation: AnyOperation, didProduceOperation newOperation: Operation) {
        produceHandler?(operation, newOperation)
    }
    
    public func operation(_ operation: AnyOperation, didFinishWithErrors errors: [NSError]) {
        finishHandler?(operation, errors)
    }
}
