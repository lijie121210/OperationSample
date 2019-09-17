//
//  AnyOperationQueue.swift
//  
//
//  Created by viwii on 2019/9/9.
//

import Foundation

/**
    The delegate of an `OperationQueue` can respond to `Operation` lifecycle
    events by implementing these methods.

    In general, implementing `OperationQueueDelegate` is not necessary; you would
    want to use an `OperationObserver` instead. However, there are a couple of
    situations where using `OperationQueueDelegate` can lead to simpler code.
    For example, `GroupOperation` is the delegate of its own internal
    `OperationQueue` and uses it to manage dependencies.
*/
@objc protocol AnyOperationQueueDelegate: NSObjectProtocol {
    @objc optional func operationQueue(_ queue: AnyOperationQueue, willAddOperation operation: Operation)
    @objc optional func operationQueue(_ queue: AnyOperationQueue, operation: Operation, didFinishWithErrors errors: [NSError])
}

/**
    `OperationQueue` is an `NSOperationQueue` subclass that implements a large
    number of "extra features" related to the `Operation` class:
    
    - Notifying a delegate of all operation completion
    - Extracting generated dependencies from operation conditions
    - Setting up dependencies to enforce mutual exclusivity
*/
open class AnyOperationQueue: OperationQueue {
    
    weak var delegate: AnyOperationQueueDelegate?
    
    open override func addOperation(_ op: Operation) {
        defer {
            self.delegate?.operationQueue?(self, willAddOperation: op)
            super.addOperation(op)
        }
        
        guard let operation = op as? AnyOperation else {
            /*
                For regular `NSOperation`s, we'll manually call out to the queue's
                delegate we don't want to just capture "operation" because that
                would lead to the operation strongly referencing itself and that's
                the pure definition of a memory leak.
            */
            op.addCompletionBlock { [weak self, weak op] in
                guard let queue = self, let operation = op else {
                    return
                }
                queue.delegate?.operationQueue?(queue, operation: operation, didFinishWithErrors: [])
            }
            return
        }
        
        // Set up a `BlockObserver` to invoke the `OperationQueueDelegate` method.
        let delegate = BlockObserver(startHandler: nil, produceHandler: { [weak self] (oldOp, newOp) in
            self?.addOperation(newOp)
        }) { [weak self] (newOp, errors) in
            guard let self = self else { return }
            self.delegate?.operationQueue?(self, operation: newOp, didFinishWithErrors: errors)
        }
        
        operation.addObserver(delegate)
        
        // Extract any dependencies needed by this operation.
        let dependencies = operation.conditions.compactMap {
            $0.dependency(for: operation)
        }
        
        for dependency in dependencies {
            operation.addDependency(dependency)
            self.addOperation(dependency)
        }
        
        /*
            With condition dependencies added, we can now see if this needs
            dependencies to enforce mutual exclusivity.
        */
        let concurrencyCategories: [String] = operation.conditions.compactMap {
            type(of: $0).isMutuallyExclusive ? "\($0.self)" : nil
        }
        
        if !concurrencyCategories.isEmpty {
            // Set up the mutual exclusivity dependencies.
            let exclusivityController = ExclusivityController.default
            exclusivityController.addOperation(operation, categories: concurrencyCategories)
            
            let blockObserver = BlockObserver(startHandler: nil, produceHandler: nil) { (oper, _) in
                exclusivityController.removeOperation(oper, categories: concurrencyCategories)
            }
            operation.addObserver(blockObserver)
        }
        
        /*
            Indicate to the operation that we've finished our extra work on it
            and it's now it a state where it can proceed with evaluating conditions,
            if appropriate.
        */
        operation.willEnqueue()
    }
    
    open override func addOperations(_ ops: [Operation], waitUntilFinished wait: Bool) {
        /*
            The base implementation of this method does not call `addOperation()`,
            so we'll call it ourselves.
        */
        for op in ops {
            addOperation(op)
        }
        if wait {
            for op in ops {
                op.waitUntilFinished()
            }
        }
    }
}
