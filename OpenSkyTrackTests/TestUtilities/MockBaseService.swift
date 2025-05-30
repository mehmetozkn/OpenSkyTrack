//
//  MockBaseService.swift
//  OpenSkyTrack
//
//  Created by Mehmet Özkan on 29.05.2025.
//

import Foundation

final class MockBaseService: BaseServiceProtocol {
    var shouldReturnError = false
    var mockResponse: Any?

    func send<T>(_ request: T, onSuccess: @escaping (T.Response) -> Void, onError: @escaping (any Error) -> Void) where T: BaseRequest {
        if shouldReturnError {
            let error = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock Error Return"])
            onError(error)
        } else if let response = mockResponse as? T.Response {
            onSuccess(response)
        } else {
            let error = NSError(domain: "Test", code: 2, userInfo: [NSLocalizedDescriptionKey: "Mock response type mismatch"])
            onError(error)
        }
    }
}

