//
//  FlightListVM.swift
//  OpenSkyTrack
//
//  Created by Mehmet Özkan on 28.05.2025.
//

import Foundation
import MapKit
import RxSwift
import RxRelay

protocol FlightViewModelProtocol {
    var flights: BehaviorRelay<[Flight]> { get }
    var error: PublishRelay<String> { get }
    var isLoading: BehaviorRelay<Bool> { get }
    var availableCountries: BehaviorRelay<[String]> { get }
    var selectedCountry: BehaviorRelay<String?> { get }
    var isAlertPresented: BehaviorRelay<Bool> { get }
    var filteredFlights: Observable<[Flight]> { get }

    func updateFlights(for region: MKCoordinateRegion)
    func createAnnotations(from flights: [Flight]) -> [MKPointAnnotation]
    func stopUpdates()
}

final class FlightViewModel: FlightViewModelProtocol {
    /// Current list of all flights
    let flights: BehaviorRelay<[Flight]> = BehaviorRelay(value: [])

    /// Stream of error messages
    let error: PublishRelay<String> = PublishRelay()

    /// Loading state indicator
    let isLoading: BehaviorRelay<Bool> = BehaviorRelay(value: false)

    /// List of available countries for filtering
    let availableCountries: BehaviorRelay<[String]> = BehaviorRelay(value: [])

    /// Currently selected country for filtering
    let selectedCountry: BehaviorRelay<String?> = BehaviorRelay(value: nil)

    /// Whether an error alert is currently being shown
    let isAlertPresented: BehaviorRelay<Bool> = BehaviorRelay(value: false)

    /// Service for managing flight data
    private let flightService: FlightServiceProtocol

    /// DisposeBag for managing subscriptions
    private let disposeBag = DisposeBag()

    /// Last viewed map region for comparison
    private var lastRegion: MKCoordinateRegion?

    /// Observable of filtered flights based on selected country and ground status
    var filteredFlights: Observable<[Flight]> {
        Observable.combineLatest(flights, selectedCountry) { flights, country in
            var filteredFlights = flights.filter { !$0.onGround }

            if let country = country {
                // Flights only in selected country
                filteredFlights = filteredFlights.filter { $0.originCountry == country }
            }

            return filteredFlights
        }
    }

    init(service: FlightServiceProtocol = FlightService()) {
        self.flightService = service
        setupBindings()
    }

    func updateFlights(for region: MKCoordinateRegion) {
        lastRegion = region
        flightService.fetchFlights(for: region)
    }

    func createAnnotations(from flights: [Flight]) -> [MKPointAnnotation] {
        return flights.map { flight in
            let annotation = MKPointAnnotation()
            annotation.coordinate = flight.coordinate
            annotation.title = flight.callsign
            annotation.subtitle = flight.originCountry
            return annotation
        }
    }

    func stopUpdates() {
        flightService.stopUpdates()
    }

    private func setupBindings() {
        flightService.flights
            .bind(to: flights)
            .disposed(by: disposeBag)

        flightService.error
            .bind(to: error)
            .disposed(by: disposeBag)

        flightService.isLoading
            .bind(to: isLoading)
            .disposed(by: disposeBag)

        // Update available countries when flights change
        flights
            .map { flights in
            Array(Set(flights.map { $0.originCountry })).sorted()
        }
            .bind(to: availableCountries)
            .disposed(by: disposeBag)

        selectedCountry
            .skip(1) // Skip the initial value to avoid sending a request
        .subscribe(onNext: { [weak self] _ in
            guard let self = self,
                let region = self.lastRegion else { return }
            self.updateFlights(for: region)
        })
            .disposed(by: disposeBag)
    }
}

