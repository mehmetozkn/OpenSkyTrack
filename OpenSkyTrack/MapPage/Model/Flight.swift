//
//  FlightModel.swift
//  OpenSkyTrack
//
//  Created by Mehmet Özkan on 28.05.2025.
//

import Foundation
import MapKit

struct FlightResponse: Codable {
    let time: Int
    let states: [[Any?]]?

    enum CodingKeys: String, CodingKey {
        case time
        case states
    }

    init(time: Int, states: [[Any?]]?) {
        self.time = time
        self.states = states
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        time = try container.decode(Int.self, forKey: .time)

        if let statesArray = try? container.decode([[AnyCodable]].self, forKey: .states) {
            states = statesArray.map { $0.map { $0.value } }
        } else {
            states = []
        }
    }

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

struct AnyCodable: Codable {
    let value: Any?

    init(_ value: Any?) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = nil
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else {
            self.value = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case nil:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        default:
            try container.encodeNil()
        }
    }
}

struct Flight {
    let id: String
    let callsign: String
    let originCountry: String
    let longitude: Double
    let latitude: Double
    let onGround: Bool
    let velocity: Double
    let trueTrack: Double
    let verticalRate: Double?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(from state: [Any?]) {
        self.id = state[0] as? String ?? ""
        self.callsign = (state[1] as? String)?.trimmingCharacters(in: .whitespaces) ?? ""
        self.originCountry = state[2] as? String ?? ""
        self.longitude = (state[5] as? NSNumber)?.doubleValue ?? 0
        self.latitude = (state[6] as? NSNumber)?.doubleValue ?? 0
        self.onGround = state[8] as? Bool ?? false
        self.velocity = (state[9] as? NSNumber)?.doubleValue ?? 0
        self.trueTrack = (state[10] as? NSNumber)?.doubleValue ?? 0
        self.verticalRate = (state[11] as? NSNumber)?.doubleValue
    }
}

