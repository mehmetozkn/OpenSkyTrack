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
    func updateAvailableCountries(_ flights: [Flight])
    func createAnnotations(from flights: [Flight]) -> [MKPointAnnotation]
    func stopUpdates()
}

final class FlightViewModel: FlightViewModelProtocol {
    let flights: BehaviorRelay<[Flight]> = BehaviorRelay(value: [])
    let error: PublishRelay<String> = PublishRelay()
    let isLoading: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    let availableCountries: BehaviorRelay<[String]> = BehaviorRelay(value: [])
    let selectedCountry: BehaviorRelay<String?> = BehaviorRelay(value: nil)
    let isAlertPresented: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    
    private let flightRepository: FlightRepositoryProtocol
    private let disposeBag = DisposeBag()
    private var lastRegion: MKCoordinateRegion?
    
    var filteredFlights: Observable<[Flight]> {
        Observable.combineLatest(flights, selectedCountry) { flights, country in
            var filteredFlights = flights.filter { !$0.onGround }

            if let country = country {
                filteredFlights = filteredFlights.filter { $0.originCountry == country }
            }

            return filteredFlights
        }
    }

    init(service: FlightRepositoryProtocol = FlightRepository()) {
        self.flightRepository = service
        setupBindings()
    }

    func updateFlights(for region: MKCoordinateRegion) {
        lastRegion = region
        flightRepository.fetchFlights(for: region)
    }

    func updateAvailableCountries(_ flights: [Flight]) {
        let countries = Array(Set(flights.map { $0.originCountry })).sorted()
        availableCountries.accept(countries)
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
        flightRepository.stopUpdates()
    }

    private func setupBindings() {
        flightRepository.flights
            .bind(to: flights)
            .disposed(by: disposeBag)

        flightRepository.error
            .bind(to: error)
            .disposed(by: disposeBag)

        flightRepository.isLoading
            .bind(to: isLoading)
            .disposed(by: disposeBag)

        flights
            .map { flights in
            Array(Set(flights.map { $0.originCountry })).sorted()
        }
            .bind(to: availableCountries)
            .disposed(by: disposeBag)

        selectedCountry
            .skip(1)
            .subscribe(onNext: { [weak self] _ in
            guard let self = self,
                let region = self.lastRegion else { return }
            self.updateFlights(for: region)
        })
            .disposed(by: disposeBag)
    }
}

