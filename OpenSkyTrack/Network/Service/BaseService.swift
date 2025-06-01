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
/// This service is responsible for:
/// - Making HTTP requests to the OpenSky Network API
/// - Handling request/response logging
/// - Managing request IDs for tracking
/// - Validating network connectivity
/// - Processing responses and errors
final class BaseService: BaseServiceProtocol {
    // MARK: - Singleton Instance
    
    /// Shared instance for singleton access
    static let shared = BaseService()

    /// Private initializer to enforce singleton pattern
    private init() { }

    // MARK: - Helper Methods
    
    /// Generates a unique request ID for tracking network requests
    /// - Returns: A UUID string to identify the request
    private func generateRequestId() -> String {
        return UUID().uuidString
    }

    // MARK: - Network Operations
    
    /// Sends a network request and handles the response
    /// - Parameters:
    ///   - request: The request to send, conforming to BaseRequest protocol
    ///   - onSuccess: Callback for successful response with decoded data
    ///   - onError: Callback for any errors that occur during the request
    /// - Important: This method checks for network connectivity before sending the request
    /// - Note: All requests are logged using NetworkLogger for debugging purposes
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

        // Prepare URL request with all necessary components
        guard var urlRequest = request.asURLRequest else {
            onError(NetworkError.invalidRequest)
            return
        }

        // Add request tracking header
        let requestId = generateRequestId()
        urlRequest.setValue(requestId, forHTTPHeaderField: "X-Request-ID")

        // Log outgoing request
        NetworkLogger.logRequest(urlRequest, requestId: requestId)

        // Send request using Alamofire
        AF.request(urlRequest)
            .validate(statusCode: 200..<300)
            .responseData { response in
                // Log incoming response
                NetworkLogger.logResponse(
                    response: response.response,
                    data: response.data,
                    error: response.error,
                    requestId: requestId
                )

                // Process response
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

