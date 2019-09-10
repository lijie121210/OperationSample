//
//  UIUserNotificationSettingsExtensions.swift
//  
//
//  Created by viwii on 2019/9/9.
//

#if os(iOS)

import Foundation
import UIKit

public extension UIUserNotificationSettings {
    
    /// Check to see if one Settings object is a superset of another Settings object.
    func contains(_ settins: UIUserNotificationSettings) -> Bool {
        // our types must contain all of the other types
        if !types.contains(settins.types) {
            return false
        }
        
        let otherCategories = settins.categories ?? []
        let myCategories = categories ?? []
        
        return myCategories.isSuperset(of: otherCategories)
    }
    
    /**
        Merge two Settings objects together. `UIUserNotificationCategories` with
        the same identifier are considered equal.
    */
    func merging(by settings: UIUserNotificationSettings) -> UIUserNotificationSettings {
        let mergedTypes = types.union(settings.types)
        let myCategories = categories ?? []
        
        var existingCategoriesByIdentifier = Dictionary(myCategories) { $0.identifier }
        
        let newCategories = settings.categories ?? []
        let newCategoriesByIdentifier = Dictionary(newCategories) { $0.identifier }
        
        existingCategoriesByIdentifier.append(contentOf: newCategoriesByIdentifier)
        
        return UIUserNotificationSettings(types: mergedTypes, categories: Set(existingCategoriesByIdentifier.values))
    }
}

#if canImport(UserNotifications)

import UserNotifications

@available(iOS 10.0, *)
public extension UNNotificationSettings {
    /*
    /// Check to see if one Settings object is a superset of another Settings object.
    func contains(_ settins: UNNotificationSettings) -> Bool {
        
    }
    
    /**
        Merge two Settings objects together. `UIUserNotificationCategories` with
        the same identifier are considered equal.
    */
    func merging(by settings: UNNotificationSettings) -> UNNotificationSettings {
    }
     */
}

#endif

#endif

