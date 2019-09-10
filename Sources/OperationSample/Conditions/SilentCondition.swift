//
//  SilentCondition.swift
//  
//
//  Created by viwii on 2019/9/9.
//

import Foundation

public struct SilentCondition<T>: OperationCondition where T: OperationCondition {
    
    public let condition: T
    
    public init(_ condition: T) {
        self.condition = condition
    }
    
    // MARK: OperationCondition
    
    public static var name: String { "Silent<\(T.name)>" }
    
    public static var isMutuallyExclusive: Bool { T.isMutuallyExclusive }
    
    public func dependency(for operation: AnyOperation) -> Operation? {
        nil
    }
    
    public func evaluate(for operation: AnyOperation, completion: @escaping (Result<Void, NSError>) -> Void) {
        condition.evaluate(for: operation, completion: completion)
    }
}
