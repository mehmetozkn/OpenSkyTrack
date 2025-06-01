import XCTest
@testable import OpenSkyTrack

final class NetworkLayerTests: XCTestCase {
    // MARK: - Properties
    var mockService: MockBaseService!
    var mockRequest: MockRequest!

    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
        mockService = MockBaseService()
        mockRequest = MockRequest()
    }

    override func tearDown() {
        mockRequest = nil
        mockService = nil
        super.tearDown()
    }

    // MARK: - Request Creation Tests

    func testURLRequestCreation_WithGETMethod() {
        // Given
        let request = MockRequest(method: .GET, path: "test", queryParams: ["key": "value"])

        // When
        let urlRequest = request.asURLRequest

        // Then
        XCTAssertNotNil(urlRequest)
        XCTAssertEqual(urlRequest?.httpMethod, "GET")
        XCTAssertEqual(urlRequest?.url?.absoluteString, "https://opensky-network.org/api/test?key=value")
        XCTAssertNil(urlRequest?.httpBody)
        XCTAssertEqual(urlRequest?.value(forHTTPHeaderField: "Accept"), "application/json")
    }

    func testURLRequestCreation_WithPOSTMethod() {
        // Given
        let body = MockBody(id: "123", name: "test")
        let request = MockRequest(method: .POST, path: "test", body: body)

        // When
        let urlRequest = request.asURLRequest

        // Then
        XCTAssertNotNil(urlRequest)
        XCTAssertEqual(urlRequest?.httpMethod, "POST")
        XCTAssertEqual(urlRequest?.url?.absoluteString, "https://opensky-network.org/api/test")
        XCTAssertNotNil(urlRequest?.httpBody)
        XCTAssertEqual(urlRequest?.value(forHTTPHeaderField: "Content-Type"), "application/json; charset=UTF-8")
    }

    func testURLRequestCreation_WithCustomHeaders() {
        // Given
        let customHeaders = ["Custom-Header": "Value"]
        let request = MockRequest(method: .GET, path: "test", headers: customHeaders)

        // When
        let urlRequest = request.asURLRequest

        // Then
        XCTAssertNotNil(urlRequest)
        XCTAssertEqual(urlRequest?.value(forHTTPHeaderField: "Custom-Header"), "Value")
    }

    // MARK: - Network Service Tests

    func testNetworkService_OfflineError() {
        // Given
        let request = MockRequest(method: .GET, path: "test")
        let expectation = XCTestExpectation(description: "Should receive offline error")

        // Simulate offline state using mock service
        mockService.isOffline = true
        mockService.shouldReturnError = false // Make sure we're not triggering other errors
        mockService.mockResponse = nil // Make sure we're not accidentally returning a success

        // When
        mockService.send(request, onSuccess: { _ in
            XCTFail("Should not succeed when offline")
            expectation.fulfill()
        }, onError: { error in
            // Then
            if case OpenSkyTrack.NetworkError.offline = error {
                expectation.fulfill()
            } else {
                XCTFail("Expected offline error, got \(error)")
            }
        })

        wait(for: [expectation], timeout: 1.0)
    }

    func testNetworkService_HTTPError() {
        // Given
        let request = MockRequest(method: .GET, path: "test")
        let expectation = XCTestExpectation(description: "Should receive HTTP error")

        // Simulate error state
        mockService.shouldReturnError = true
        mockService.isOffline = false

        // When
        mockService.send(request, onSuccess: { _ in
            XCTFail("Should not succeed when error is expected")
            expectation.fulfill()
        }, onError: { error in
            // Then
            if case OpenSkyTrack.NetworkError.httpError(let statusCode, _) = error {
                XCTAssertEqual(statusCode, 404)
                expectation.fulfill()
            } else {
                XCTFail("Expected HTTP error, got \(error)")
            }
        })

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Logger Tests

    func testNetworkLogger_ResponseLogging() {
        // Given
        let url = URL(string: "https://test.com")!
        let statusCode = 200
        let headers = ["Content-Type": "application/json"]
        let responseData = """
        {
            "success": true,
            "message": "Test response"
        }
        """.data(using: .utf8)!

        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: headers
        )

        // When & Then - This mainly tests that logging doesn't crash
        NetworkLogger.logResponse(
            response: response,
            data: responseData,
            error: nil,
            requestId: "test-request-id"
        )
    }

    func testNetworkLogger_ResponseLogging_WithError() {
        // Given
        let url = URL(string: "https://test.com")!
        let statusCode = 404
        let headers = ["Content-Type": "application/json"]
        let responseData = """
        {
            "success": false,
            "error": "Not found"
        }
        """.data(using: .utf8)!
        let error = NetworkError.httpError(
            statusCode: statusCode,
            apiError: APIError(code: "404", message: "Resource not found", details: nil)
        )

        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: headers
        )

        // When & Then - This mainly tests that logging doesn't crash
        NetworkLogger.logResponse(
            response: response,
            data: responseData,
            error: error,
            requestId: "test-request-id"
        )
    }

    func testNetworkLogger_RequestLogging() {
        // Given
        var request = URLRequest(url: URL(string: "https://test.com/api/endpoint")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = """
        {
            "key": "value",
            "test": true
        }
        """.data(using: .utf8)

        // When & Then - This mainly tests that logging doesn't crash
        NetworkLogger.logRequest(request, requestId: "test-request-id")
    }

    // MARK: - Error Handling Tests

    func testNetworkError_LocalizedDescription() {
        // Test various error cases
        XCTAssertEqual(NetworkError.invalidRequest.errorDescription, "Invalid request")
        XCTAssertEqual(NetworkError.offline.errorDescription, "No internet connection available")

        // Test HTTP errors
        let clientError = NetworkError.httpError(statusCode: 404, apiError: nil)
        XCTAssertEqual(clientError.errorDescription, "An unexpected error occurred")

        // Test with API Error
        let apiError = APIError(code: "404", message: "Error message returned from the service", details: nil)
        let errorWithAPI = NetworkError.httpError(statusCode: 404, apiError: apiError)
        XCTAssertEqual(errorWithAPI.errorDescription, "Error message returned from the service")
    }

    func testAPIError_Decoding() {
        // Given
        let jsonData = """
        {
            "code": "400",
            "message": "Bad Request",
            "details": {
                "field": "Invalid value"
            }
        }
        """.data(using: .utf8)!

        // When
        let error = try? JSONDecoder().decode(APIError.self, from: jsonData)

        // Then
        XCTAssertNotNil(error)
        XCTAssertEqual(error?.code, "400")
        XCTAssertEqual(error?.message, "Bad Request")
        XCTAssertEqual(error?.details?["field"], "Invalid value")
    }
}

