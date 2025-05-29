//
//  MockBaseService.swift
//  OpenSkyTrack
//
//  Created by Mehmet Özkan on 29.05.2025.
//

import Foundation

class MockBaseService: BaseServiceProtocol {
    var shouldReturnError = false
    var mockFlightResponse: FlightResponse?

    func send<T>(_ request: T, onSuccess: @escaping (T.Response) -> Void, onError: @escaping (any Error) -> Void) where T: BaseRequest {
        if shouldReturnError {
            let error = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock Error"])
            onError(error)
        } else if let response = mockFlightResponse as? T.Response {
            onSuccess(response)
        }
    }
}
