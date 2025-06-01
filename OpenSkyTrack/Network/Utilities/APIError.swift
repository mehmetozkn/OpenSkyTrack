//
//  APIError.swift
//  OpenSkyTrack
//
//  Created by Mehmet Özkan on 31.05.2025.
//

/// Represents a structured error response from the API
/// This structure matches the error format returned by the backend
struct APIError: Codable {
    /// Optional error code that identifies the type of error
    let code: String?
    
    /// A human-readable error message describing what went wrong
    let message: String
    
    /// Optional dictionary containing additional error details
    /// The keys represent field names and values contain specific error messages
    let details: [String: String]?

    enum CodingKeys: String, CodingKey {
        case code
        case message
        case details
    }
}
