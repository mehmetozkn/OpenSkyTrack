import Foundation

final class MockBaseService: BaseServiceProtocol {
    var shouldReturnError = false
    var mockResponse: Any?
    var isOffline = false

    func send<T>(_ request: T, onSuccess: @escaping (T.Response) -> Void, onError: @escaping (Error) -> Void) where T: BaseRequest {
        // Check offline state first
        if isOffline {
            onError(NetworkError.offline)
            return
        }

        // Check for error state
        if shouldReturnError {
            let error = NetworkError.httpError(
                statusCode: 404,
                apiError: APIError(code: nil, message: "Test error", details: nil)
            )
            onError(error)
            return
        }

        // Check for success response
        if let response = mockResponse as? T.Response {
            onSuccess(response)
        } else {
            onError(NetworkError.invalidResponse)
        }
    }
}
