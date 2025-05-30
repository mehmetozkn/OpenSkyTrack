//
//  NetworkErrorEnum.swift
//  OpenSkyTrack
//
//  Created by Mehmet Özkan on 30.05.2025.
//

import Foundation

// Network error types
enum NetworkError: LocalizedError {
    case invalidRequest
    case invalidResponse
    case serverError(Int)
    case clientError(Int)
    case decodingError
    case unknown(Int?)

    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "Invalid request"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server error occurred with status code: \(code)"
        case .clientError(let code):
            return "Client error occurred with status code: \(code)"
        case .decodingError:
            return "Failed to decode response"
        case .unknown(let code):
            return "Unknown error occurred\(code.map { " with status code: \($0)" } ?? "")"
        }
    }
}
