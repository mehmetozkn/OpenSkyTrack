//
//  NetworkErrorEnum.swift
//  OpenSkyTrack
//
//  Created by Mehmet Özkan on 30.05.2025.
//

import Foundation

/// Represents various types of network-related errors that can occur during API operations
enum NetworkError: LocalizedError {
    /// The request could not be created or is invalid
    case invalidRequest

    /// The response received from the server is invalid or could not be processed
    case invalidResponse

    /// An HTTP error occurred with a specific status code and optional API error details
    /// - Parameters:
    ///   - statusCode: The HTTP status code received
    ///   - apiError: Optional structured error information from the API
    case httpError(statusCode: Int, apiError: APIError?)

    /// The response data could not be decoded into the expected format
    case decodingError

    /// No internet connection is available
    case offline

    /// A human-readable description of the error
    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "Invalid request"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(_, let apiError):
            if let apiError = apiError {
                return apiError.message
            }
            return "An unexpected error occurred"
        case .decodingError:
            return "Failed to decode response"
        case .offline:
            return "No internet connection available"
        }
    }
}
