//
//  ReachabilityCondition.swift
//  
//
//  Created by viwii on 2019/9/9.
//

#if canImport(SystemConfiguration)

import Foundation
import SystemConfiguration

public extension OperationError.UserInfoKey {
    
    static let reachabilityHostKey = OperationError.UserInfoKey("Host")
}

/**
    This is a condition that performs a very high-level reachability check.
    It does *not* perform a long-running reachability check, nor does it respond to changes in reachability.
    Reachability is evaluated once when the operation to which this is attached is asked about its readiness.
*/
public struct ReachabilityCondition: OperationCondition {
    
    public static let name = "Reachability"
    public static let isMutuallyExclusive = false
    
    public let host: URL
    
    public init(_ host: URL) {
        self.host = host
    }
    
    public func dependency(for operation: AnyOperation) -> Operation? {
        nil
    }
    
    public func evaluate(for operation: AnyOperation, completion: @escaping (Result<Void, NSError>) -> Void) {
        Reachability.request(url: host) { (reachable) in
            if reachable {
                completion(.success(()))
                return
            }
            
            let error = NSError(
                code: .conditionFailed,
                userInfos: [
                    .operationConditionKey : ReachabilityCondition.name,
                    .reachabilityHostKey : self.host
                ]
            )
            completion(.failure(error))
        }
    }
}

extension ReachabilityCondition {
    
    /// A private singleton that maintains a basic cache of `SCNetworkReachability` objects.
    fileprivate class Reachability {
        
        static var refs = [String: SCNetworkReachability]()
        static let queue = DispatchQueue(label: "Operations.Reachability")
            
        static func request(url: URL, handler: @escaping (Bool) -> Void) {
            guard let host = url.host else {
                handler(false)
                return
            }
            
            queue.async {
                var nullableRef = self.refs[host]
                if nullableRef == nil {
                    nullableRef = host.withCString { SCNetworkReachabilityCreateWithName(nil, $0) }
                }
                
                guard let ref = nullableRef else {
                    handler(false)
                    return
                }
                
                self.refs[host] = ref
                
                var reachable = false
                var flags: SCNetworkReachabilityFlags = []
                if SCNetworkReachabilityGetFlags(ref, &flags) {
                    /*
                        Note that this is a very basic "is reachable" check.
                        Your app may choose to allow for other considerations,
                        such as whether or not the connection would require
                        VPN, a cellular connection, etc.
                    */
                    reachable = flags.contains(.reachable)
                }
                handler(reachable)
            }
        }
    }
}

#endif
