//
//  FlightModel.swift
//  OpenSkyTrack
//
//  Created by Mehmet Özkan on 28.05.2025.
//

import Foundation
import MapKit

/// Represents the response from the OpenSky Network API containing flight state vectors
struct FlightResponse: Codable {
    /// Unix timestamp (seconds) of the last data update
    let time: Int
    
    /// Array of flight state vectors
    /// Each vector is an array of optional values representing various flight attributes
    let states: [[Any?]]?

    enum CodingKeys: String, CodingKey {
        case time
        case states
    }

    /// Creates a new flight response with the specified time and states
    /// - Parameters:
    ///   - time: Unix timestamp of the data
    ///   - states: Array of flight state vectors
    init(time: Int, states: [[Any?]]?) {
        self.time = time
        self.states = states
    }

    /// Decodes a FlightResponse from JSON data
    /// - Parameter decoder: The decoder to read from
    /// - Throws: DecodingError if the data cannot be decoded
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        time = try container.decode(Int.self, forKey: .time)

        if let statesArray = try? container.decode([[AnyCodable]].self, forKey: .states) {
            states = statesArray.map { $0.map { $0.value } }
        } else {
            states = []
        }
    }

    /// Encodes the FlightResponse to JSON data
    /// - Parameter encoder: The encoder to write to
    /// - Throws: EncodingError if the data cannot be encoded
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(time, forKey: .time)

        if let states = states {
            let encodableStates = states.map { row in
                row.map { AnyCodable($0) }
            }
            try container.encode(encodableStates, forKey: .states)
        }
    }
}

/// Represents a single flight with its current state information
struct Flight {
    /// ICAO24 unique identifier for the aircraft
    let id: String
    
    /// Flight callsign (airline code + flight number)
    let callsign: String
    
    /// Country of origin for the flight
    let originCountry: String
    
    /// Current longitude of the aircraft
    let longitude: Double
    
    /// Current latitude of the aircraft
    let latitude: Double
    
    /// Whether the aircraft is on the ground
    let onGround: Bool

    /// The aircraft's current location as a coordinate
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Creates a new Flight from a state vector array
    /// - Parameter state: Array containing flight state information
    /// Index meanings:
    /// - 0: ICAO24 (id)
    /// - 1: Callsign
    /// - 2: Origin Country
    /// - 5: Longitude
    /// - 6: Latitude
    /// - 8: On Ground
    init(from state: [Any?]) {
        self.id = state[0] as? String ?? ""
        self.callsign = (state[1] as? String)?.trimmingCharacters(in: .whitespaces) ?? ""
        self.originCountry = state[2] as? String ?? ""
        self.longitude = (state[5] as? NSNumber)?.doubleValue ?? 0
        self.latitude = (state[6] as? NSNumber)?.doubleValue ?? 0
        self.onGround = state[8] as? Bool ?? false
    }
}

