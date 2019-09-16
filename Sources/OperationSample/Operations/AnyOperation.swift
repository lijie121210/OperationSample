//
//  AnyOperation.swift
//  
//
//  Created by viwii on 2019/9/8.
//

import Foundation

/**
    The subclass of `NSOperation` from which all other operations should be derived.
    This class adds both Conditions and Observers, which allow the operation to define
    extended readiness requirements, as well as notify many interested parties
    about interesting operation state changes
*/
open class AnyOperation: Operation {
    
    // MARK: KVO - Registering Dependent Keys
    //
    // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueObserving/Articles/KVODependentKeys.html#//apple_ref/doc/uid/20002179-SW3
    //
    
    class func keyPathsForValuesAffectingIsReady() -> Set<String> {
        return ["state"]
    }
    
    class func keyPathsForValuesAffectingIsExecuting() -> Set<String> {
        return ["state"]
    }
    
    class func keyPathsForValuesAffectingIsFinished() -> Set<String> {
        return ["state"]
    }
    
    open class override func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
        
        switch key {
        case "isReady", "isExecuting", "isFinished":
            keyPaths.insert("state")
        default:
            break
        }
        
        return keyPaths
    }
    
    open var isUserInitiated: Bool {
        get { qualityOfService == .userInitiated }
        set {
            assert(state < .executing, "Cannot modify userInitiated after execution has begun.")
            qualityOfService = newValue ? QualityOfService.userInitiated : .default
        }
    }
    
    private var _internalErrors = [NSError]()
    
    /// A lock to guard reads and writes to the `_state` property
    private let _stateLock = NSLock()
    
    /// Private storage for the `state` property that will be KVO observed.
    private var _state = State.initialized
    
    private var state: State {
        get { _stateLock.withCriticalScope { _state } }
        set(newState) {
            /*
                It's important to note that the KVO notifications are NOT called from inside
                the lock. If they were, the app would deadlock, because in the middle of
                calling the `didChangeValueForKey()` method, the observers try to access
                properties like "isReady" or "isFinished". Since those methods also
                acquire the lock, then we'd be stuck waiting on our own lock. It's the
                classic definition of deadlock.
            */
            willChangeValue(forKey: "state")
            
            _stateLock.withCriticalScope { () -> Void in
                guard _state != .finished else {
                    return
                }
                
                assert(_state.canTransition(to: newState), "Performing invalid state transition.")
                
                _state = newState
            }
            
            didChangeValue(forKey: "state")
        }
    }
    
    /**
        Indicates that the Operation can now begin to evaluate readiness conditions,
        if appropriate.
    */
    open func willEnqueue() {
        state = .pending
    }
    
    open override var isReady: Bool {
        switch state {
        case .initialized: return isCancelled
        case .pending:
            // If the operation has been cancelled, "isReady" should return true
            guard !isCancelled else { return true }
            
            // If super isReady, conditions can be evaluated
            if super.isReady {
                evaluateConditions()
            }
            
            // Until conditions have been evaluated, "isReady" returns false
            return false
        case .ready: return super.isReady || isCancelled
        default: return false
        }
    }
    
    open override var isExecuting: Bool { return state == .executing }
    
    open override var isFinished: Bool { return state == .finished }
    
    private func evaluateConditions() {
        assert(state == .pending && !isCancelled, "evaluateConditions() was called out-of-order")
        
        state = .evaluatingConditions
        
        OperationConditionEvaluator.evaluate(conditions: conditions, operation: self) { [weak self] (failures) in
            self?._internalErrors.append(contentsOf: failures)
            self?.state = .ready
        }
    }
    
    // MARK: Observers and Conditions

    private(set) var conditions = [OperationCondition]()
    
    open func addCondition(_ condition: OperationCondition) {
        assert(state < .evaluatingConditions, "Cannot modify conditions after execution has begun.")
        conditions.append(condition)
    }
    
    private(set) var observers = [OperationObserver]()
    
    open func addObserver(_ observer: OperationObserver) {
        assert(state < .executing, "Cannot modify observers after execution has begun.")
        observers.append(observer)
    }
    
    open override func addDependency(_ op: Operation) {
        assert(state < .executing, "Dependencies cannot be modified after execution has begun.")
        super.addDependency(op)
    }
    
    // MARK: Execution and Cancellation
    
    final public override func start() {
        // NSOperation.start() contains important logic that shouldn't be bypassed.
        super.start()
        
        if isCancelled {
            finish()
        }
    }
    
    final public override func main() {
        assert(state == .ready, "This operation must be performed on an operation queue.")
        
        guard _internalErrors.isEmpty, isCancelled == false else {
            finish()
            return
        }
        
        state = .executing
        
        for observer in observers {
            observer.operationDidStart(self)
        }
        
        execute()
    }
    
    /**
        `execute()` is the entry point of execution for all `Operation` subclasses.
        If you subclass `Operation` and wish to customize its execution, you would
        do so by overriding the `execute()` method.
        
        At some point, your `Operation` subclass must call one of the "finish"
        methods defined below; this is how you indicate that your operation has
        finished its execution, and that operations dependent on yours can re-evaluate
        their readiness state.
    */
    open func execute() {
        print("\(self) must override `execute()`.")
        
        finish()
    }
    
    open func cancel(with error: NSError?) {
        if let error = error {
            _internalErrors.append(error)
        }
        cancel()
    }
    
    final public func produceOperation(_ operation: Operation) {
        for observer in observers {
            observer.operation(self, didProduceOperation: operation)
        }
    }
    
    // MARK: Finishing
    
    /**
        A private property to ensure we only notify the observers once that the
        operation has finished.
    */
    private var hasFinishedAlready = false
    
    /**
        Most operations may finish with a single error, if they have one at all.
        This is a convenience method to simplify calling the actual `finish()`
        method. This is also useful if you wish to finish with an error provided
        by the system frameworks. As an example, see `DownloadEarthquakesOperation`
        for how an error from an `NSURLSession` is passed along via the
        `finishWithError()` method.
    */
    final public func finish(with error: NSError?) {
        if let error = error {
            finish(errors: [error])
        } else {
            finish()
        }
    }
    
    final public func finish(errors: [NSError] = []) {
        guard !hasFinishedAlready else {
            return
        }
        
        hasFinishedAlready = true
        state = .finishing
        
        let combinedErrors = _internalErrors + errors
        finished(errors: combinedErrors)
        
        for observer in observers {
            observer.operation(self, didFinishWithErrors: combinedErrors)
        }
        
        state = .finished
    }
    
    /**
        Subclasses may override `finished(_:)` if they wish to react to the operation
        finishing with errors. For example, the `LoadModelOperation` implements
        this method to potentially inform the user about an error when trying to
        bring up the Core Data stack.
    */
    open func finished(errors: [NSError]) {
        
    }
    
    final public override func waitUntilFinished() {
        /*
            Waiting on operations is almost NEVER the right thing to do. It is
            usually superior to use proper locking constructs, such as `dispatch_semaphore_t`
            or `dispatch_group_notify`, or even `NSLocking` objects. Many developers
            use waiting when they should instead be chaining discrete operations
            together using dependencies.
            
            To reinforce this idea, invoking `waitUntilFinished()` will crash your
            app, as incentive for you to find a more appropriate way to express
            the behavior you're wishing to create.
        */
        fatalError("Waiting on operations is an anti-pattern. Remove this ONLY if you're absolutely sure there is No Other Way™.")
    }
    
}

fileprivate extension AnyOperation {
    
    enum State: Int, Equatable, CaseIterable {
        
        /// The initial state of an `Operation`.
        case initialized
        
        /// The `Operation` is ready to begin evaluating conditions.
        case pending
        
        /// The `Operation` is evaluating conditions.
        case evaluatingConditions
        
        /**
            The `Operation`'s conditions have all been satisfied, and it is ready
            to execute.
        */
        case ready
        
        /// The `Operation` is executing.
        case executing
        
        /**
            Execution of the `Operation` has finished, but it has not yet notified
            the queue of this.
        */
        case finishing
        
        /// The `Operation` has finished executing.
        case finished
        
        func canTransition(to targetState: State) -> Bool {
            switch (self, targetState) {
            case (.initialized, .pending): return true
            case (.pending, .evaluatingConditions): return true
            case (.evaluatingConditions, .ready): return true
            case (.ready, .executing): return true
            case (.ready, .finishing): return true
            case (.executing, .finishing): return true
            case (.finishing, .finished): return true
            default: return false
            }
        }
    }
}

extension AnyOperation.State: Comparable {
    static func < (lhs: AnyOperation.State, rhs: AnyOperation.State) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    static func <= (lhs: AnyOperation.State, rhs: AnyOperation.State) -> Bool {
        return lhs.rawValue <= rhs.rawValue
    }
    
    static func > (lhs: AnyOperation.State, rhs: AnyOperation.State) -> Bool {
        return lhs.rawValue > rhs.rawValue
    }
    
    static func >= (lhs: AnyOperation.State, rhs: AnyOperation.State) -> Bool {
        return lhs.rawValue >= rhs.rawValue
    }
}


