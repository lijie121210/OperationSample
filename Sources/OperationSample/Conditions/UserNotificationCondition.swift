//
//  UserNotificationCondition.swift
//  
//
//  Created by viwii on 2019/9/10.
//

#if os(iOS) && canImport(UIKit)

import Foundation
import UIKit

public extension OperationError.UserInfoKey {
    
    static let currentUNSettings = OperationError.UserInfoKey("CurrentUserNotificationSettings")
    static let desiredUNSettings = OperationError.UserInfoKey("DesiredUserNotificationSettings")

}


/**
    A condition for verifying that we can present alerts to the user via
    `UILocalNotification` and/or remote notifications.
*/
public struct UserNotificationCondition: OperationCondition {
    
    public enum Behavior {
        /// Merge the new `UIUserNotificationSettings` with the `currentUserNotificationSettings`.
        case merge
        
        /// Replace the `currentUserNotificationSettings` with the new `UIUserNotificationSettings`.
        case replace
    }
    
    public static let name = "UserNotification"
    public static let isMutuallyExclusive = false
    
    public var settings: UIUserNotificationSettings
    public let application: UIApplication
    public var behavior: Behavior
    
    /**
        The designated initializer.
        
        - parameter settings: The `UIUserNotificationSettings` you wish to be
            registered.

        - parameter application: The `UIApplication` on which the `settings` should
            be registered.

        - parameter behavior: The way in which the `settings` should be applied
            to the `application`. By default, this value is `.Merge`, which means
            that the `settings` will be combined with the existing settings on the
            `application`. You may also specify `.Replace`, which means the `settings`
            will overwrite the exisiting settings.
    */
    public init(settings: UIUserNotificationSettings, application: UIApplication, behavior: Behavior = .merge) {
        self.settings = settings
        self.application = application
        self.behavior = behavior
    }
    
    public func dependency(for operation: AnyOperation) -> Operation? {
        PermisstionOperation(settings: settings, application: application, behavior: behavior)
    }
    
    public func evaluate(for operation: AnyOperation, completion: @escaping (Result<Void, NSError>) -> Void) {
        if let current = application.currentUserNotificationSettings, current.contains(settings) {
            completion(.success(()))
            return
        }
        
        let error = NSError(
            code: .conditionFailed,
            userInfos: [
                .operationConditionKey : UserNotificationCondition.name,
                .currentUNSettings : application.currentUserNotificationSettings ?? NSNull(),
                .desiredUNSettings : settings
            ]
        )
        completion(.failure(error))
    }
}

private extension UserNotificationCondition {
    
    class PermisstionOperation: AnyOperation {
        
        let settings: UIUserNotificationSettings
        let application: UIApplication
        let behavior: UserNotificationCondition.Behavior
        
        init(settings: UIUserNotificationSettings, application: UIApplication, behavior: Behavior) {
            self.settings = settings
            self.application = application
            self.behavior = behavior
            
            super.init()

            addCondition(AlertPresentation())
        }
        
        override func execute() {
            DispatchQueue.main.async {
                
                let settingsToRegister: UIUserNotificationSettings
                
                switch (self.application.currentUserNotificationSettings, self.behavior) {
                case (let cs?, .merge) :
                    settingsToRegister = cs.merging(by: self.settings)
                default:
                    settingsToRegister = self.settings
                }
                
                self.application.registerUserNotificationSettings(settingsToRegister)
            }
        }
    }
}

#endif
