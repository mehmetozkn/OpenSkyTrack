import Foundation
import RxSwift
import RxRelay
import MapKit

@testable import OpenSkyTrack

final class MockFlightService: FlightServiceProtocol {
    let flights: BehaviorRelay<[Flight]> = BehaviorRelay(value: [])
    let error: PublishRelay<String> = PublishRelay()
    let isLoading: BehaviorRelay<Bool> = BehaviorRelay(value: false)

    var shouldReturnError = false
    var mockResponse: FlightResponse?
    var isOffline = false

    func fetchFlights(for region: MKCoordinateRegion) {
        isLoading.accept(true)

        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }

            if self.isOffline {
                self.error.accept("Network is offline")
                self.isLoading.accept(false)
                return
            }

            if self.shouldReturnError {
                self.error.accept("Test error")
                self.isLoading.accept(false)
                return
            }

            if let response = self.mockResponse {
                let newFlights = response.states?.compactMap { Flight(from: $0) } ?? []
                self.flights.accept(newFlights)
            } else {
                self.flights.accept([])
            }

            self.isLoading.accept(false)
        }
    }

    func stopUpdates() {
        // Mock implementation - nothing to do
    }
}
