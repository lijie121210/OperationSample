//
//  OperationConditionEvaluator.swift
//  
//
//  Created by viwii on 2019/9/8.
//

import Foundation

public struct OperationConditionEvaluator {
    
    static func evaluate(conditions: [OperationCondition], operation: AnyOperation, completion: @escaping ([NSError]) -> Void) {
        // Check conditions.

        let conditionGroup = DispatchGroup()
        
        var results = Array<Result<Void, NSError>?>(repeating: nil, count: conditions.count)
        
        // Ask each condition to evaluate and store its result in the "results" array.
        for (index, condition) in conditions.enumerated() {
            conditionGroup.enter()
            condition.evaluate(for: operation) { (r) in
                results[index] = r
                conditionGroup.leave()
            }
        }
        
        // After all the conditions have evaluated, this block will execute.
        conditionGroup.notify(queue: .global()) {
            // Aggregate the errors that occurred, in order.
            var failures = results.compactMap { $0?.error }
            
            // If any of the conditions caused this operation to be cancelled, check for that.
            if operation.isCancelled {
                failures.append(NSError(code: .conditionFailed))
            }
            
            completion(failures)
        }
    }
}


