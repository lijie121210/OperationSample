//
//  DelayOperation.swift
//  
//
//  Created by viwii on 2019/9/9.
//

import Foundation

open class DelayOperation: AnyOperation {
    
    private enum Delay {
        case interval(TimeInterval)
        case date(Date)
        
        var timeInterval: TimeInterval {
            switch self {
            case .interval(let t): return t
            case .date(let d): return d.timeIntervalSinceNow
            }
        }
    }
    
    private let delay: Delay
    
    public init(_ timeInterval: TimeInterval) {
        delay = .interval(timeInterval)
        super.init()
    }
    
    public init(_ untilDate: Date) {
        delay = .date(untilDate)
        super.init()
    }
    
    open override func execute() {
        let interval = delay.timeInterval
        
        guard interval > 0 else {
            finish()
            return
        }
        
        let when = DispatchTime.now() + interval
        DispatchQueue.global().asyncAfter(deadline: when) {
            // If we were cancelled, then finish() has already been called.
            if !self.isCancelled {
                self.finish()
            }
        }
    }
    
    open override func cancel() {
        super.cancel()
        
        // Cancelling the operation means we don't want to wait anymore.
        self.finish()
    }
}
