//
//  APIError.swift
//  OpenSkyTrack
//
//  Created by Mehmet Özkan on 31.05.2025.
//

struct APIError: Codable {
    let code: String?
    let message: String
    let details: [String: String]?

    enum CodingKeys: String, CodingKey {
        case code
        case message
        case details
    }
}
