//
//  BaseService.swift
//  OpenSkyTrack
//
//  Created by Mehmet Özkan on 31.05.2025.
//

import Foundation
import Alamofire

protocol BaseServiceProtocol {
    func send<T: BaseRequest>(
        _ request: T,
        onSuccess: @escaping (T.Response) -> Void,
        onError: @escaping (Error) -> Void
    )
}

/// Handles all network operations for the OpenSky API
/// - Note: This service uses Alamofire for network requests
/// - Important: All requests require an internet connection
final class BaseService: BaseServiceProtocol {
    static let shared = BaseService()

    private init() { }

    private func generateRequestId() -> String {
        return UUID().uuidString
    }

    /// Sends a network request
    /// - Parameters:
    ///   - request: The request to send
    ///   - onSuccess: Called when request succeeds
    ///   - onError: Called when request fails
    func send<T: BaseRequest>(
        _ request: T,
        onSuccess: @escaping (T.Response) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        // Check network connectivity first
        guard NetworkReachabilityManager()?.isReachable == true else {
            onError(NetworkError.offline)
            return
        }

        guard var urlRequest = request.asURLRequest else {
            onError(NetworkError.invalidRequest)
            return
        }

        // Add X-Request-ID header
        let requestId = generateRequestId()
        urlRequest.setValue(requestId, forHTTPHeaderField: "X-Request-ID")

        // Log the request with request ID
        NetworkLogger.logRequest(urlRequest, requestId: requestId)

        AF.request(urlRequest)
            .validate(statusCode: 200..<300)
            .responseData { response in
            // Log the response with request ID
            NetworkLogger.logResponse(
                response: response.response,
                data: response.data,
                error: response.error,
                requestId: requestId
            )

            switch response.result {
            case .success(let data):
                do {
                    let decodedResponse = try JSONDecoder().decode(T.Response.self, from: data)
                    onSuccess(decodedResponse)
                } catch {
                    onError(NetworkError.decodingError)
                }
            case .failure:
                let statusCode = response.response?.statusCode ?? -1

                // Try to decode API error if present
                if let data = response.data {
                    do {
                        let apiError = try JSONDecoder().decode(APIError.self, from: data)
                        onError(NetworkError.httpError(statusCode: statusCode, apiError: apiError))
                        return
                    } catch {
                        print("⚠️ API Error decoding failed: \(error)")
                        if let rawResponse = String(data: data, encoding: .utf8) {
                            print("📄 Raw response: \(rawResponse)")
                        }
                    }
                }

                // If we couldn't decode API error, just return the status code
                onError(NetworkError.httpError(statusCode: statusCode, apiError: nil))
            }
        }
    }
}

