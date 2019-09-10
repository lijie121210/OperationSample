//
//  NegatedCondition.swift
//  
//
//  Created by viwii on 2019/9/9.
//

import Foundation

public extension OperationError.UserInfoKey {
    
    static let negatedConditionKey = OperationError.UserInfoKey("NegatedCondition")
}

public struct NegatedCondition<T> : OperationCondition where T : OperationCondition {
    
    public let condition: T

    public init(condition: T) {
        self.condition = condition
    }
    
    // MARK: OperationCondition
    
    public static var name: String { "Not<\(T.name)>" }
    
    public static var isMutuallyExclusive: Bool { T.isMutuallyExclusive }
    
    public func dependency(for operation: AnyOperation) -> Operation? {
        condition.dependency(for: operation)
    }
    
    public  func evaluate(for operation: AnyOperation, completion: @escaping (Result<Void, NSError>) -> Void) {
        condition.evaluate(for: operation) { (result) in
            switch result {
            case .success(_):
                let error = NSError(
                    code: .conditionFailed,
                    userInfos: [
                        .operationConditionKey : NegatedCondition.name,
                        .negatedConditionKey : T.name
                    ]
                )
                completion(.failure(error))
            case .failure(_):
                completion(.success(()))
            }
        }
    }
}
