//
//  BlockOperation.swift
//  
//
//  Created by viwii on 2019/9/8.
//

import Foundation

/// A closure type that takes a closure as its parameter.
public typealias AnyOperationBlock = (@escaping () -> Void) -> Void

/// A sublcass of `Operation` to execute a closure.
open class AnyBlockOperation: AnyOperation {
    
    private let block: AnyOperationBlock?

    /**
        The designated initializer.

        - parameter block: The closure to run when the operation executes. This
            closure will be run on an arbitrary queue. The parameter passed to the
            block **MUST** be invoked by your code, or else the `BlockOperation`
            will never finish executing. If this parameter is `nil`, the operation
            will immediately finish.
    */
    public init(block: AnyOperationBlock? = nil) {
        self.block = block
        super.init()
    }

    /**
        A convenience initializer to execute a block on the main queue.

        - parameter mainQueueBlock: The block to execute on the main queue. Note
            that this block does not have a "continuation" block to execute (unlike
            the designated initializer). The operation will be automatically ended
            after the `mainQueueBlock` is executed.
    */
    public convenience init(mainQueueBlock: @escaping () -> Void) {
        self.init(block: { continuation in
            DispatchQueue.main.async {
                mainQueueBlock()
                continuation()
            }
        })
    }

    open override func execute() {
        guard let block = block else {
            finish()
            return
        }
        
        block { [weak self] in
            self?.finish()
        }
    }
}
