import Foundation

protocol BaseRequest {
    associatedtype Response: Decodable

    var baseUrl: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var param: String? { get }
}

extension BaseRequest {
    var baseUrl: String { return "https://opensky-network.org/api/" }

    var asURLRequest: URLRequest? {
        guard let url = URL(string: baseUrl + path + (param ?? "")) else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        return request
    }
}

enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case DELETE
}
