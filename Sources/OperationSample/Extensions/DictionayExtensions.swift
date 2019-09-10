//
//  DictionaryExtensions.swift
//  
//
//  Created by viwii on 2019/9/8.
//

import Foundation

extension Dictionary {
    /**
        It's not uncommon to want to turn a sequence of values into a dictionary,
        where each value is keyed by some unique identifier. This initializer will
        do that.
        
        - parameter sequence: The sequence to be iterated

        - parameter keyMapper: The closure that will be executed for each element in
            the `sequence`. The return value of this closure, if there is one, will
            be used as the key for the value in the `Dictionary`. If the closure
            returns `nil`, then the value will be omitted from the `Dictionary`.
    */
    init<S>(_ sequence: S, keyMapper: (Value) -> Key?) where S: Sequence, S.Element == Value {
        self.init()
        
        for item in sequence {
            if let key = keyMapper(item) {
                self[key] = item
            }
        }
    }
    
    mutating func append(contentOf sequence: Dictionary<Key, Value>) {
        for (key, value) in sequence {
            self[key] = value
        }
    }
}
