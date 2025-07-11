//
//  NetworkErrorEnum.swift
//  OpenSkyTrack
//
//  Created by Mehmet Özkan on 30.05.2025.
//

import Foundation

enum NetworkError: LocalizedError {
    case invalidRequest
    case invalidResponse
    case httpError(statusCode: Int, apiError: APIError?)
    case decodingError
    case offline
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
