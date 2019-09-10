//
//  RemoteNotificationCondition.swift
//  
//
//  Created by viwii on 2019/9/10.
//

#if os(iOS) && canImport(UIKit)

import Foundation
import UIKit

private let RemoteNotificationQueue = AnyOperationQueue()

private extension NSNotification.Name {
    
    static let APNSNotification = NSNotification.Name("RemoteNotificationPermissionNotification")
}

public struct RemoteNotificationCondition: OperationCondition {
    
    fileprivate typealias RegistrationResult = Result<Data, NSError>

    public static let name = "RemoteNotification"
    public static let isMutuallyExclusive = false
    
    public static func receive(notificationToken token: Data) {
        NotificationCenter.default.post(name: .APNSNotification, object: nil, userInfo: ["token":token])
    }
    
    public static func failToRegister(with error: NSError) {
        NotificationCenter.default.post(name: .APNSNotification, object: nil, userInfo: ["error":error])
    }
    
    public let application: UIApplication
    
    public init(application: UIApplication) {
        self.application = application
    }
    
    public func dependency(for operation: AnyOperation) -> Operation? {
        PermissionOperation(application: application) { (_) in }
    }
    
    public func evaluate(for operation: AnyOperation, completion: @escaping (Result<Void, NSError>) -> Void) {
        /*
            Since evaluation requires executing an operation, use a private operation
            queue.
        */
        let operation = PermissionOperation(application: application) { (result) in
            switch result {
            case .success(_):
                completion(.success(()))
            case .failure(let underlyingError):
                let error = NSError(
                    code: .conditionFailed,
                    userInfos: [
                        .operationConditionKey : RemoteNotificationCondition.name,
                        .underlyingErrorKey : underlyingError
                    ]
                )
                completion(.failure(error))
            }
        }
        RemoteNotificationQueue.addOperation(operation)
    }
}

private extension RemoteNotificationCondition {
    
    /**
        A private `Operation` to request a push notification token from the `UIApplication`.
        
        - note: This operation is used for *both* the generated dependency **and**
            condition evaluation, since there is no "easy" way to retrieve the push
            notification token other than to ask for it.

        - note: This operation requires you to call either `RemoteNotificationCondition.didReceiveNotificationToken(_:)` or
            `RemoteNotificationCondition.didFailToRegister(_:)` in the appropriate
            `UIApplicationDelegate` method, as shown in the `AppDelegate.swift` file.
    */
    class PermissionOperation: AnyOperation {
        
        let application: UIApplication
        private let handler: (RegistrationResult) -> Void
        
        init(application: UIApplication, handler: @escaping (RegistrationResult) -> Void) {
            self.application = application
            self.handler = handler
            
            super.init()
            
            /*
                This operation cannot run at the same time as any other remote notification
                permission operation.
            */
            addCondition(MutuallyExclusive<PermissionOperation>())
        }
        
        override func execute() {
            DispatchQueue.main.async {
                let center = NotificationCenter.default
                center.addObserver(self, selector: #selector(self.receive(_:)), name: .APNSNotification, object: nil)
                self.application.registerForRemoteNotifications()
            }
        }
        
        @objc private func receive(_ notification: Notification) {
            NotificationCenter.default.removeObserver(self)
            
            guard let userInfo = notification.userInfo else {
                fatalError("Received a notification without a token and without an error.")
            }
            
            if let token = userInfo["token"] as? Data {
                handler(.success(token))
            } else if let error = userInfo["error"] as? NSError {
                handler(.failure(error))
            } else {
                fatalError("Received a notification without a token and without an error.")
            }
            
            finish()
        }
    }
}

#endif
