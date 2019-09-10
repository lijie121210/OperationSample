//
//  File.swift
//  
//
//  Created by viwii on 2019/9/10.
//

#if os(iOS) && canImport(Photos)

import Foundation
import Photos

/// A condition for verifying access to the user's Photos library.
public struct PhotosCondition: OperationCondition {
    
    public static let name = "Photos"
    public static let isMutuallyExclusive = false
    
    public func dependency(for operation: AnyOperation) -> Operation? {
        PermissionOperation()
    }
    
    public func evaluate(for operation: AnyOperation, completion: @escaping (Result<Void, NSError>) -> Void) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            completion(.success(()))
        default:
            let error = NSError(code: .conditionFailed, userInfos: [.operationConditionKey : PhotosCondition.name])
            completion(.failure(error))
        }
    }
    
}

fileprivate extension PhotosCondition {
    
    /**
        A private `Operation` that will request access to the user's Photos, if it
        has not already been granted.
    */
    class PermissionOperation: AnyOperation {
        
        override init() {
            super.init()
            
            addCondition(AlertPresentation())
        }
        
        override func execute() {
            switch PHPhotoLibrary.authorizationStatus() {
            case .notDetermined:
                DispatchQueue.main.async {
                    PHPhotoLibrary.requestAuthorization { (status) in
                        self.finish()
                    }
                }
            default:
                finish()
            }
        }
    }
}

#endif
