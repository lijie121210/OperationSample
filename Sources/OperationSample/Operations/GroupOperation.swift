//
//  GroupOperation.swift
//  
//
//  Created by viwii on 2019/9/9.
//

import Foundation

/**
    A subclass of `Operation` that executes zero or more operations as part of its
    own execution. This class of operation is very useful for abstracting several
    smaller operations into a larger operation. As an example, the `GetEarthquakesOperation`
    is composed of both a `DownloadEarthquakesOperation` and a `ParseEarthquakesOperation`.

    Additionally, `GroupOperation`s are useful if you establish a chain of dependencies,
    but part of the chain may "loop". For example, if you have an operation that
    requires the user to be authenticated, you may consider putting the "login"
    operation inside a group operation. That way, the "login" operation may produce
    subsequent operations (still within the outer `GroupOperation`) that will all
    be executed before the rest of the operations in the initial chain of operations.
*/
open class GroupOperation: AnyOperation {
    private let internalQueue = AnyOperationQueue()
    private let startingOperation = BlockOperation { }
    private let finishingOperation = BlockOperation { }
    private var aggregatedErrors = [NSError]()
    
    public init(_ operations: [Operation]) {
        super.init()
        
        internalQueue.isSuspended = true
        internalQueue.delegate = self
        internalQueue.addOperation(startingOperation)
        
        for op in operations {
            internalQueue.addOperation(op)
        }
    }
    
    public convenience init(operations: Operation...) {
        self.init(operations)
    }
    
    open override func cancel() {
        internalQueue.cancelAllOperations()
        super.cancel()
    }
    
    open override func execute() {
        internalQueue.isSuspended = false
        internalQueue.addOperation(finishingOperation)
    }
    
    open func addOperation(_ operation: Operation) {
        internalQueue.addOperation(operation)
    }
    
    /**
        Note that some part of execution has produced an error.
        Errors aggregated through this method will be included in the final array
        of errors reported to observers and to the `finished(_:)` method.
    */
    final public func aggregateError(_ error: NSError) {
        aggregatedErrors.append(error)
    }
    
    open func operation(_ op: Operation, didFinishWithErrors errors: [NSError]) {
        // For use by subclassers.
    }
}

extension GroupOperation: AnyOperationQueueDelegate {
    
    final func operationQueue(_ queue: AnyOperationQueue, willAddOperation operation: Operation) {
        assert(!finishingOperation.isFinished && !finishingOperation.isExecuting, "cannot add new operations to a group after the group has completed")
        
        /*
            Some operation in this group has produced a new operation to execute.
            We want to allow that operation to execute before the group completes,
            so we'll make the finishing operation dependent on this newly-produced operation.
        */
        if operation !== finishingOperation {
            finishingOperation.addDependency(operation)
        }
        
        /*
            All operations should be dependent on the "startingOperation".
            This way, we can guarantee that the conditions for other operations
            will not evaluate until just before the operation is about to run.
            Otherwise, the conditions could be evaluated at any time, even
            before the internal operation queue is unsuspended.
        */
        if operation !== startingOperation {
            operation.addDependency(startingOperation)
        }
    }
    
    final func operationQueue(_ queue: AnyOperationQueue, operation: Operation, didFinishWithErrors errors: [NSError]) {
        aggregatedErrors.append(contentsOf: errors)
        
        if operation === finishingOperation {
            internalQueue.isSuspended = true
            finish(errors: aggregatedErrors)
            return
        }
        
        if operation !== startingOperation {
            self.operation(operation, didFinishWithErrors: errors)
        }
    }
}
