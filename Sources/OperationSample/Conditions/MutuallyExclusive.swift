//
//  MutuallyExclusive.swift
//  
//
//  Created by viwii on 2019/9/9.
//

import Foundation

/// A generic condition for describing kinds of operations that may not execute concurrently.
public struct MutuallyExclusive<T>: OperationCondition {
    
    public static var name: String {
        return "MutuallyExclusive<\(T.self)>"
    }

    public static var isMutuallyExclusive: Bool {
        return true
    }
    
    public init() { }
    
    public func dependency(for operation: AnyOperation) -> Operation? {
        return nil
    }
    
    public func evaluate(for operation: AnyOperation, completion: (Result<Void, NSError>) -> Void) {
        completion(.success(()))
    }
}

/**
    The purpose of this enum is to simply provide a non-constructible
    type to be used with `MutuallyExclusive<T>`.
*/
public enum Alert { }


/// A condition describing that the targeted operation may present an alert.
public typealias AlertPresentation = MutuallyExclusive<Alert>
