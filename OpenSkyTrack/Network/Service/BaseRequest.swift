//
//  BaseRequest.swift
//  OpenSkyTrack
//
//  Created by Mehmet Özkan on 30.05.2025.
//

import Foundation

protocol BaseRequest {
    associatedtype Response: Decodable
    associatedtype Body: Encodable

    var baseUrl: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var queryParameters: [String: Any]? { get }
    var body: Body? { get }
    var headers: [String: String]? { get }
}

// MARK: - Default Implementations

extension BaseRequest {
    var baseUrl: String {
        return "https://opensky-network.org/api/"
    }

    var queryParameters: [String: Any]? {
        return nil
    }

    var body: Body? {
        return nil
    }

    var headers: [String: String]? {
        return nil
    }
}

// MARK: - URLRequest Creation

extension BaseRequest {
    var asURLRequest: URLRequest? {
        var urlComponents = URLComponents(string: baseUrl + path)

        if (method == .GET || method == .DELETE), let parameters = queryParameters {
            urlComponents?.queryItems = parameters.map {
                URLQueryItem(name: $0.key, value: "\($0.value)")
            }
        }

        guard let url = urlComponents?.url else { return nil }
        var request = URLRequest(url: url)

        request.httpMethod = method.rawValue

        var defaultHeaders = [
            "Accept": "application/json"
        ]

        if let customHeaders = headers {
            defaultHeaders.merge(customHeaders) { _, new in new }
        }

        defaultHeaders.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        if (method == .POST || method == .PUT), let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
                request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
            } catch {
                return nil
            }
        }

        return request
    }
}

