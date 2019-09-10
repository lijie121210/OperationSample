//
//  TimeoutObserver.swift
//  
//
//  Created by viwii on 2019/9/9.
//

import Foundation

/**
    `TimeoutObserver` is a way to make an `Operation` automatically time out and
    cancel after a specified time interval.
*/
public struct TimeoutObserver: OperationObserver {
    
    // MARK: Properties
    
    static let timeoutKey = "Timeout"
    
    private let timeout: TimeInterval
    
    // MARK: Initialization

    init(_ timeout: TimeInterval) {
        self.timeout = timeout
    }
    
    // MARK: OperationObserver

    public func operationDidStart(_ operation: AnyOperation) {
        let t = timeout
        // When the operation starts, queue up a block to cause it to time out.
        let when = DispatchTime.now() + t
        DispatchQueue.global().asyncAfter(deadline: when) {
            /*
                Cancel the operation if it hasn't finished and hasn't already
                been cancelled.
            */
            guard !operation.isFinished && !operation.isCancelled else {
                return
            }
            let error = NSError(code: .executionFailed, userInfo: [TimeoutObserver.timeoutKey:t])
            operation.cancel(with: error)
        }
    }
    
    public func operation(_ operation: AnyOperation, didProduceOperation newOperation: Operation) {
        
    }
    
    public func operation(_ operation: AnyOperation, didFinishWithErrors: [NSError]) {
        
    }
}

