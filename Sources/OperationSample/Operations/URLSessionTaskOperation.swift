//
//  URLSessionTaskOperation.swift
//  
//
//  Created by viwii on 2019/9/9.
//

import Foundation

private var URLSessionTasksOperationKVOContext = 0
private let URLSessionTasksOperationKVOKeyPath = "state"

/**
    `URLSessionTaskOperation` is an `Operation` that lifts an `NSURLSessionTask`
    into an operation.

    Note that this operation does not participate in any of the delegate callbacks \
    of an `NSURLSession`, but instead uses Key-Value-Observing to know when the
    task has been completed. It also does not get notified about any errors that
    occurred during execution of the task.

    An example usage of `URLSessionTaskOperation` can be seen in the `DownloadEarthquakesOperation`.
*/
open class URLSessionTaskOperation: AnyOperation {
    
    public let task: URLSessionTask
    
    public init(task: URLSessionTask) {
        assert(task.state == .suspended, "Tasks must be suspended.")
        
        self.task = task
        super.init()
    }
    
    open override func execute() {
        assert(task.state == .suspended, "Task was resumed by something other than \(self).")
        
        task.addObserver(self, forKeyPath: URLSessionTasksOperationKVOKeyPath, options: [], context: &URLSessionTasksOperationKVOContext)
        task.resume()
    }
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &URLSessionTasksOperationKVOContext, keyPath == URLSessionTasksOperationKVOKeyPath else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        if let obj = object as? URLSessionTask, obj === task, task.state == .completed {
            task.removeObserver(self, forKeyPath: URLSessionTasksOperationKVOKeyPath)
            finish()
        }
    }
    
    open override func cancel() {
        task.cancel()
        super.cancel()
    }
}
