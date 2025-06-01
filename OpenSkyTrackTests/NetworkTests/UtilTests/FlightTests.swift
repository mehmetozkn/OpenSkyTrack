import XCTest
import MapKit
@testable import OpenSkyTrack

final class FlightTests: XCTestCase {
    // MARK: - Flight Response Tests
    
    func testFlightResponse_Initialization() {
        // Given
        let time = Int(Date().timeIntervalSince1970)
        let states: [[Any?]] = [
            ["abc123", "FL123", "USA", nil, nil, -122.4194, 37.7749, nil, false],
            ["def456", "FL456", "CAN", nil, nil, -79.3832, 43.6532, nil, true]
        ]
        
        // When
        let response = FlightResponse(time: time, states: states)
        
        // Then
        XCTAssertEqual(response.time, time)
        XCTAssertEqual(response.states?.count, 2)
    }
    
    func testFlightResponse_Encoding() throws {
        // Given
        let time = 1622505600
        let states: [[Any?]] = [
            ["abc123", "FL123", "USA", nil, nil, -122.4194, 37.7749, nil, false]
        ]
        let response = FlightResponse(time: time, states: states)
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(response)
        let jsonString = String(data: data, encoding: .utf8)
        
        // Then
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString?.contains("\"time\":1622505600") ?? false)
        XCTAssertTrue(jsonString?.contains("\"states\":[[") ?? false)
    }
    
    func testFlightResponse_Decoding() throws {
        // Given
        let json = """
        {
            "time": 1622505600,
            "states": [
                ["abc123", "FL123", "USA", null, null, -122.4194, 37.7749, null, false]
            ]
        }
        """
        let data = json.data(using: .utf8)!
        
        // When
        let decoder = JSONDecoder()
        let response = try decoder.decode(FlightResponse.self, from: data)
        
        // Then
        XCTAssertEqual(response.time, 1622505600)
        XCTAssertEqual(response.states?.count, 1)
    }
    
    // MARK: - Flight Tests
    
    func testFlight_InitializationWithValidData() {
        // Given
        let state: [Any?] = ["abc123", "FL123", "USA", nil, nil, -122.4194, 37.7749, nil, false]
        
        // When
        let flight = Flight(from: state)
        
        // Then
        XCTAssertEqual(flight.id, "abc123")
        XCTAssertEqual(flight.callsign, "FL123")
        XCTAssertEqual(flight.originCountry, "USA")
        XCTAssertEqual(flight.longitude, -122.4194)
        XCTAssertEqual(flight.latitude, 37.7749)
        XCTAssertFalse(flight.onGround)
    }
    
    func testFlight_InitializationWithInvalidData() {
        // Given
        let state: [Any?] = [nil, nil, nil, nil, nil, nil, nil, nil, nil]
        
        // When
        let flight = Flight(from: state)
        
        // Then
        XCTAssertEqual(flight.id, "")
        XCTAssertEqual(flight.callsign, "")
        XCTAssertEqual(flight.originCountry, "")
        XCTAssertEqual(flight.longitude, 0)
        XCTAssertEqual(flight.latitude, 0)
        XCTAssertFalse(flight.onGround)
    }
    
    func testFlight_InitializationWithPartialData() {
        // Given
        let state: [Any?] = ["abc123", nil, "USA", nil, nil, -122.4194, nil, nil, true]
        
        // When
        let flight = Flight(from: state)
        
        // Then
        XCTAssertEqual(flight.id, "abc123")
        XCTAssertEqual(flight.callsign, "")
        XCTAssertEqual(flight.originCountry, "USA")
        XCTAssertEqual(flight.longitude, -122.4194)
        XCTAssertEqual(flight.latitude, 0)
        XCTAssertTrue(flight.onGround)
    }
    
    func testFlight_CoordinateComputation() {
        // Given
        let state: [Any?] = ["abc123", "FL123", "USA", nil, nil, -122.4194, 37.7749, nil, false]
        
        // When
        let flight = Flight(from: state)
        
        // Then
        XCTAssertEqual(flight.coordinate.latitude, 37.7749)
        XCTAssertEqual(flight.coordinate.longitude, -122.4194)
    }
    
    func testFlight_CallsignTrimming() {
        // Given
        let state: [Any?] = ["abc123", "  FL123  ", "USA", nil, nil, -122.4194, 37.7749, nil, false]
        
        // When
        let flight = Flight(from: state)
        
        // Then
        XCTAssertEqual(flight.callsign, "FL123")
    }
} 