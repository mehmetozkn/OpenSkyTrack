import Foundation
import Alamofire

protocol BaseServiceProtocol {
    func send<T: BaseRequest>(
        _ request: T,
        onSuccess: @escaping (T.Response) -> Void,
        onError: @escaping (Error) -> Void
    )
}

class BaseService: BaseServiceProtocol {
    static let shared = BaseService()

    private init() { }

    func send<T: BaseRequest>(
        _ request: T,
        onSuccess: @escaping (T.Response) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        guard let urlRequest = request.asURLRequest else {
            onError(NSError(domain: "RequestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL request"]))
            return
        }

        AF.request(urlRequest)
            .validate(statusCode: 200..<300)
            .responseData { response in
            switch response.result {
            case .success(let data):
                do {
                    let decodedResponse = try JSONDecoder().decode(T.Response.self, from: data)
                    onSuccess(decodedResponse)
                } catch {
                    onError(error)
                }
            case .failure(_):
                let statusCode = response.response?.statusCode ?? -1
                let customError: NSError

                if (400..<500).contains(statusCode) {
                    customError = NSError(domain: "ClientError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Client error occurred with status code: \(statusCode)"])
                } else if (500..<600).contains(statusCode) {
                    customError = NSError(domain: "ServerError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error occurred with status code: \(statusCode)"])
                } else {
                    customError = NSError(domain: "UnknownError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred with status code: \(statusCode)"])
                }
                onError(customError)
            }
        }
    }
}

