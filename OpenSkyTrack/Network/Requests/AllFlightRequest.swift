//
//  GetAllFlightRequest.swift
//  OpenSkyTrack
//
//  Created by Mehmet Özkan on 30.05.2025.
//

import Foundation

/// Request to get all flights in a specific geographical region
/// This request fetches flight data from the OpenSky Network API within the specified bounding box
struct GetAllFlightRequest: BaseRequest {
    /// The response type for this request, containing flight state vectors
    typealias Response = FlightResponse
    
    /// No body is needed for this GET request
    typealias Body = Never

    /// The API endpoint path for getting flight states
    let path: String = "/states/all"
    
    /// This is a GET request
    let method: HTTPMethod = .GET

    /// Minimum latitude of the bounding box
    private let lamin: Double
    
    /// Minimum longitude of the bounding box
    private let lomin: Double
    
    /// Maximum latitude of the bounding box
    private let lamax: Double
    
    /// Maximum longitude of the bounding box
    private let lomax: Double

    /// Query parameters defining the bounding box for the flight search
    var queryParameters: [String: Any]? {
        return [
            "lamin": lamin,
            "lomin": lomin,
            "lamax": lamax,
            "lomax": lomax
        ]
    }

    /// Initializes a new request to get flights within a specific bounding box
    /// - Parameters:
    ///   - lamin: Minimum latitude of the bounding box
    ///   - lomin: Minimum longitude of the bounding box
    ///   - lamax: Maximum latitude of the bounding box
    ///   - lomax: Maximum longitude of the bounding box
    init(lamin: Double, lomin: Double, lamax: Double, lomax: Double) {
        self.lamin = lamin
        self.lomin = lomin
        self.lamax = lamax
        self.lomax = lomax
    }
}
