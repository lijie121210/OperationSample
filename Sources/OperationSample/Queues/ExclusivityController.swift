//
//  ExclusivityController.swift
//  
//
//  Created by viwii on 2019/9/9.
//

import Foundation

/**
    `ExclusivityController` is a singleton to keep track of all the in-flight
    `Operation` instances that have declared themselves as requiring mutual exclusivity.
    We use a singleton because mutual exclusivity must be enforced across the entire
    app, regardless of the `OperationQueue` on which an `Operation` was executed.
*/
open class ExclusivityController {
    
    public static let `default` = ExclusivityController()
    
    private let serialQueue = DispatchQueue(label: "Operations.ExclusivityController")
    private var operations = [String : [AnyOperation]]()
    
    private init() { }
    
    /// Registers an operation as being mutually exclusive
    public func addOperation(_ op: AnyOperation, categories: [String]) {
        /*
            This needs to be a synchronous operation.
            If this were async, then we might not get around to adding dependencies
            until after the operation had already begun, which would be incorrect.
        */
        serialQueue.sync {
            for category in categories {
                self.noqueue_addOperation(op, category: category)
            }
        }
    }
    
    public func removeOperation(_ op: AnyOperation, categories: [String]) {
        serialQueue.async {
            for category in categories {
                self.noqueue_removeOperation(op, category: category)
            }
        }
    }
    
    // MARK: Operation Management

    private func noqueue_addOperation(_ op: AnyOperation, category: String) {
        var operationsWithThisCategory = operations[category] ?? []
        
        if let last = operationsWithThisCategory.last {
            op.addDependency(last)
        }
        
        operationsWithThisCategory.append(op)
        operations[category] = operationsWithThisCategory
    }
    
    private func noqueue_removeOperation(_ op: AnyOperation, category: String) {
        let matchingOperations = operations[category]
        
        guard var operationsWithThisCategory = matchingOperations,
            let index = operationsWithThisCategory.firstIndex(of: op) else {
            return
        }

        operationsWithThisCategory.remove(at: index)
        operations[category] = operationsWithThisCategory
    }
}
