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

final class FlightViewModel {
    let flights: BehaviorRelay<[Flight]> = BehaviorRelay(value: [])
    let error: PublishRelay<String> = PublishRelay()
    let isLoading: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    let availableCountries: BehaviorRelay<[String]> = BehaviorRelay(value: [])
    let selectedCountry: BehaviorRelay<String?> = BehaviorRelay(value: nil)
    let isAlertPresented: BehaviorRelay<Bool> = BehaviorRelay(value: false)

    private let baseService: BaseServiceProtocol
    private let disposeBag = DisposeBag()
    private var timer: Disposable?
    private var lastRegion: MKCoordinateRegion?

    var filteredFlights: Observable<[Flight]> {
        Observable.combineLatest(flights, selectedCountry) { flights, country in
            var filteredFlights = flights.filter { !$0.onGround } // Take the planes in the air

            if let country = country {
                // Flights only in selected country
                filteredFlights = filteredFlights.filter { $0.originCountry == country }
            }

            return filteredFlights
        }
    }

    init(service: BaseServiceProtocol) {
        self.baseService = service
        setupBindings()
    }

    private func setupBindings() {
        selectedCountry
            .skip(1) // Skip the initial value to avoid sending a request
        .subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            if let region = self.lastRegion {
                self.fetchFlights(for: region)
            }
        }).disposed(by: disposeBag)
    }

    func updateFlights(for region: MKCoordinateRegion) {
        // if the alert is presented, do not update flights
        guard !isAlertPresented.value else { return }

        // Store the region for comparison
        lastRegion = region

        // Cancel existing timer
        timer?.dispose()

        // Create new timer for auto-refresh
        // Update flights if the area shown on the map does not change for 5 seconds
        timer = Observable<Int>
            .interval(.seconds(1), scheduler: MainScheduler.instance)
            .startWith(0) // Emit immediately
        .subscribe(onNext: { [weak self] _ in
            guard let self = self, !self.isAlertPresented.value else { return }
            self.fetchFlights(for: region)
        })

        timer?.disposed(by: disposeBag)
    }

    private func fetchFlights(for region: MKCoordinateRegion) {
        isLoading.accept(true)

        // Create request with the current region's coordinates
        let request = GetAllFlightRequest(
            lamin: region.center.latitude - region.span.latitudeDelta / 2,
            lomin: region.center.longitude - region.span.longitudeDelta / 2,
            lamax: region.center.latitude + region.span.latitudeDelta / 2,
            lomax: region.center.longitude + region.span.longitudeDelta / 2
        )

        baseService.send(request,
                         onSuccess: { [weak self] response in
                             guard let self = self else { return }
                             let newFlights = response.states?.compactMap { Flight(from: $0) } ?? []
                             self.flights.accept(newFlights)
                             self.updateAvailableCountries(newFlights)
                             self.isLoading.accept(false)
                         },
                         onError: { [weak self] error in
                             guard let self = self else { return }
                             self.error.accept(error.localizedDescription)
                             self.isAlertPresented.accept(true)
                             self.isLoading.accept(false)
                         }
        )
    }

    // Updates the list of available countries based on flight data, with countries appearing 1 time
    func updateAvailableCountries(_ flights: [Flight]) {
        let countries = Array(Set(flights.map { $0.originCountry }))
            .filter { !$0.isEmpty } // Filter out empty country names
        .sorted()
        availableCountries.accept(countries)
    }

    // Stops the timer to prevent further updates
    func stopUpdates() {
        timer?.dispose()
        timer = nil
    }

    // Deinit to stop updates when the view model is no longer needed
    deinit {
        stopUpdates()
    }
}

