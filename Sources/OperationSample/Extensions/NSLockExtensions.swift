//
//  File.swift
//  
//
//  Created by viwii on 2019/9/8.
//

import Foundation

extension NSLock {
    
    func withCriticalScope<T>(block: () -> T) -> T {
        lock()
        let value = block()
        unlock()
        return value
    }
}
