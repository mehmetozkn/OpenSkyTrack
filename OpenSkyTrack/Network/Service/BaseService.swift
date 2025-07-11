//
//  BaseService.swift
//  OpenSkyTrack
//
//  Created by Mehmet Özkan on 31.05.2025.
//

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

    private func generateRequestId() -> String {
        return UUID().uuidString
    }

    func send<T: BaseRequest>(
        _ request: T,
        onSuccess: @escaping (T.Response) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        guard NetworkReachabilityManager()?.isReachable == true else {
            onError(NetworkError.offline)
            return
        }

        guard var urlRequest = request.asURLRequest else {
            onError(NetworkError.invalidRequest)
            return
        }

        let requestId = generateRequestId()
        urlRequest.setValue(requestId, forHTTPHeaderField: "X-Request-ID")

        NetworkLogger.logRequest(urlRequest, requestId: requestId)

        AF.request(urlRequest)
            .validate(statusCode: 200..<300)
            .responseData { response in
                NetworkLogger.logResponse(
                    response: response.response,
                    data: response.data,
                    error: response.error,
                    requestId: requestId
                )

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

                    if let data = response.data {
                        do {
                            let apiError = try JSONDecoder().decode(APIError.self, from: data)
                            onError(NetworkError.httpError(statusCode: statusCode, apiError: apiError))
                            return
                        } catch {
                            print("⚠️ API Error decoding failed: \(error)")
                            if let rawResponse = String(data: data, encoding: .utf8) {
                                print("📄 Raw response: \(rawResponse)")
                            }
                        }
                    }

                    onError(NetworkError.httpError(statusCode: statusCode, apiError: nil))
                }
            }
    }
}

