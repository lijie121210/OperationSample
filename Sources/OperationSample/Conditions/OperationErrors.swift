//
//  OperationErrors.swift
//  
//
//  Created by viwii on 2019/9/8.
//

import Foundation

public let OperationErrorDomain = "com.OperationErrors"

public enum OperationError: Error {
    
    public static let domain = OperationErrorDomain
    
    public enum Code: Int {
        case conditionFailed = 1
        case executionFailed = 2
    }
    
    public struct UserInfoKey : Hashable, Equatable, RawRepresentable {
        
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

public extension OperationError.UserInfoKey {
    
    static let operationConditionKey = OperationError.UserInfoKey("OperationCondition")
    static let underlyingErrorKey = OperationError.UserInfoKey(NSUnderlyingErrorKey)
}

public extension NSError {
    convenience init(code: OperationError.Code, userInfo dict: [String: Any]? = nil) {
        self.init(domain: OperationErrorDomain, code: code.rawValue, userInfo: dict)
    }
    
    convenience init(code: OperationError.Code, userInfos: [OperationError.UserInfoKey: Any]) {
        var dicts = [String : Any]()
        for (key, value) in userInfos {
            dicts[key.rawValue] = value
        }
        self.init(domain: OperationErrorDomain, code: code.rawValue, userInfo: dicts)
    }
}

// This makes it easy to compare an `NSError.code` to an `OperationErrorCode`.
public func ==(lhs: Int, rhs: OperationError.Code) -> Bool {
    return lhs == rhs.rawValue
}

public func ==(lhs: OperationError.Code, rhs: Int) -> Bool {
    return lhs.rawValue == rhs
}
