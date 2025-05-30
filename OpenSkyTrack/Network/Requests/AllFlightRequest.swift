import Foundation

/// Request to get all flights in a specific region
struct GetAllFlightRequest: BaseRequest {
    typealias Response = FlightResponse
    typealias Body = EmptyBody

    let path: String = "/states/all"
    let method: HTTPMethod = .GET

    private let lamin: Double
    private let lomin: Double
    private let lamax: Double
    private let lomax: Double

    var queryParameters: [String: Any]? {
        return [
            "lamin": lamin,
            "lomin": lomin,
            "lamax": lamax,
            "lomax": lomax
        ]
    }

    init(lamin: Double, lomin: Double, lamax: Double, lomax: Double) {
        self.lamin = lamin
        self.lomin = lomin
        self.lamax = lamax
        self.lomax = lomax
    }
}
