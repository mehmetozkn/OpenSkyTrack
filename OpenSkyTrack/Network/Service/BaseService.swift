import Foundation
import Alamofire

protocol BaseServiceProtocol {
    func send<T: BaseRequest>(
        _ request: T,
        onSuccess: @escaping (T.Response) -> Void,
        onError: @escaping (Error) -> Void
    )
}

final class BaseService: BaseServiceProtocol {
    static let shared = BaseService()

    private init() { }

    func send<T: BaseRequest>(
        _ request: T,
        onSuccess: @escaping (T.Response) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        guard let urlRequest = request.asURLRequest else {
            onError(NetworkError.invalidRequest)
            return
        }

        AF.request(urlRequest)
            .validate(statusCode: 200..<300)
            .responseData { response in
            // Log the response
            NetworkLogger.logResponse(response)

            switch response.result {
            case .success(let data):
                do {
                    let decodedResponse = try JSONDecoder().decode(T.Response.self, from: data)
                    onSuccess(decodedResponse)
                } catch {
                    onError(NetworkError.decodingError)
                }
            case .failure:
                let statusCode = response.response?.statusCode ?? -1
                let error: NetworkError

                switch statusCode {
                case 400...499:
                    error = .clientError(statusCode)
                case 500...599:
                    error = .serverError(statusCode)
                default:
                    error = .unknown(statusCode)
                }

                onError(error)
            }
        }
    }
}

