import XCTest
@testable import OpenSkyTrack

final class AnyCodableTests: XCTestCase {
    // MARK: - Encoding Tests
    
    func testEncoding_NilValue() throws {
        // Given
        let codable = AnyCodable(nil)
        
        // When
        let data = try JSONEncoder().encode(codable)
        let jsonString = String(data: data, encoding: .utf8)
        
        // Then
        XCTAssertEqual(jsonString, "null")
    }
    
    func testEncoding_BoolValue() throws {
        // Given
        let codable = AnyCodable(true)
        
        // When
        let data = try JSONEncoder().encode(codable)
        let jsonString = String(data: data, encoding: .utf8)
        
        // Then
        XCTAssertEqual(jsonString, "true")
    }
    
    func testEncoding_IntValue() throws {
        // Given
        let codable = AnyCodable(42)
        
        // When
        let data = try JSONEncoder().encode(codable)
        let jsonString = String(data: data, encoding: .utf8)
        
        // Then
        XCTAssertEqual(jsonString, "42")
    }
    
    func testEncoding_DoubleValue() throws {
        // Given
        let codable = AnyCodable(3.14)
        
        // When
        let data = try JSONEncoder().encode(codable)
        let jsonString = String(data: data, encoding: .utf8)
        
        // Then
        XCTAssertEqual(jsonString, "3.14")
    }
    
    func testEncoding_StringValue() throws {
        // Given
        let codable = AnyCodable("test")
        
        // When
        let data = try JSONEncoder().encode(codable)
        let jsonString = String(data: data, encoding: .utf8)
        
        // Then
        XCTAssertEqual(jsonString, "\"test\"")
    }
    
    func testEncoding_UnsupportedValue() throws {
        // Given
        let codable = AnyCodable(["key": "value"]) // Dictionary is not supported
        
        // When
        let data = try JSONEncoder().encode(codable)
        let jsonString = String(data: data, encoding: .utf8)
        
        // Then
        XCTAssertEqual(jsonString, "null")
    }
    
    // MARK: - Decoding Tests
    
    func testDecoding_NilValue() throws {
        // Given
        let json = "null"
        let data = json.data(using: .utf8)!
        
        // When
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        
        // Then
        XCTAssertNil(decoded.value)
    }
    
    func testDecoding_BoolValue() throws {
        // Given
        let json = "true"
        let data = json.data(using: .utf8)!
        
        // When
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        
        // Then
        XCTAssertEqual(decoded.value as? Bool, true)
    }
    
    func testDecoding_IntValue() throws {
        // Given
        let json = "42"
        let data = json.data(using: .utf8)!
        
        // When
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        
        // Then
        XCTAssertEqual(decoded.value as? Int, 42)
    }
    
    func testDecoding_DoubleValue() throws {
        // Given
        let json = "3.14"
        let data = json.data(using: .utf8)!
        
        // When
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        
        // Then
        XCTAssertEqual(decoded.value as? Double, 3.14)
    }
    
    func testDecoding_StringValue() throws {
        // Given
        let json = "\"test\""
        let data = json.data(using: .utf8)!
        
        // When
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        
        // Then
        XCTAssertEqual(decoded.value as? String, "test")
    }
} 