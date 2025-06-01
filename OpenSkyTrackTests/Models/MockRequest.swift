struct MockRequest: BaseRequest {
    typealias Response = MockResponse
    typealias Body = MockBody

    var method: HTTPMethod
    var path: String
    var queryParameters: [String: Any]?
    var body: MockBody?
    var headers: [String: String]?

    init(method: HTTPMethod = .GET,
         path: String = "",
         queryParams: [String: Any]? = nil,
         body: MockBody? = nil,
         headers: [String: String]? = nil) {
        self.method = method
        self.path = path
        self.queryParameters = queryParams
        self.body = body
        self.headers = headers
    }
}

struct MockResponse: Codable {
    let success: Bool
}

struct MockBody: Codable {
    let id: String
    let name: String
}


