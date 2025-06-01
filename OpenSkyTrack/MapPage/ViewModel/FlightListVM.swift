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

/// ViewModel responsible for managing flight data and user interactions
final class FlightViewModel {
    // MARK: - Public Properties
    
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

    // MARK: - Private Properties
    
    /// Service for making network requests
    private let baseService: BaseServiceProtocol
    
    /// DisposeBag for managing subscriptions
    private let disposeBag = DisposeBag()
    
    /// Timer for automatic data refresh
    private var timer: Disposable?
    
    /// Last viewed map region for comparison
    private var lastRegion: MKCoordinateRegion?

    // MARK: - Computed Properties
    
    /// Observable of filtered flights based on selected country and ground status
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

    // MARK: - Initialization
    
    /// Creates a new FlightViewModel
    /// - Parameter service: Service for making network requests
    init(service: BaseServiceProtocol) {
        self.baseService = service
        setupBindings()
    }

    // MARK: - Private Methods
    
    /// Sets up reactive bindings for the view model
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

    // MARK: - Public Methods
    
    /// Updates flight data for a specific map region
    /// - Parameter region: The map region to fetch flights for
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
            .interval(.seconds(5), scheduler: MainScheduler.instance)
            .startWith(0) // Emit immediately
            .subscribe(onNext: { [weak self] _ in
                guard let self = self, !self.isAlertPresented.value else { return }
                self.fetchFlights(for: region)
            })

        timer?.disposed(by: disposeBag)
    }

    // MARK: - Flight Data Fetching

    /// Fetches flights for the specified map region
    /// - Parameter region: The map region to fetch flights for
    /// This method:
    /// 1. Updates loading state
    /// 2. Creates and sends API request
    /// 3. Processes response and updates UI
    /// 4. Handles any potential errors
    private func fetchFlights(for region: MKCoordinateRegion) {
        // Start loading state
        isLoading.accept(true)

        // Calculate bounding box coordinates for the request
        let request = GetAllFlightRequest(
            lamin: region.center.latitude - region.span.latitudeDelta / 2,
            lomin: region.center.longitude - region.span.longitudeDelta / 2,
            lamax: region.center.latitude + region.span.latitudeDelta / 2,
            lomax: region.center.longitude + region.span.longitudeDelta / 2
        )

        // Send API request and handle response
        baseService.send(request,
                        onSuccess: { [weak self] response in
                            guard let self = self else { return }
                            // Transform response into Flight objects
                            let newFlights = response.states?.compactMap { Flight(from: $0) } ?? []
                            self.flights.accept(newFlights)
                            self.updateAvailableCountries(newFlights)
                            self.isLoading.accept(false)
                        },
                        onError: { [weak self] error in
                            guard let self = self else { return }
                            // Handle error and update UI accordingly
                            self.error.accept(error.localizedDescription)
                            self.isAlertPresented.accept(true)
                            self.isLoading.accept(false)
                        }
        )
    }

    // MARK: - Helper Methods

    /// Creates map annotations from flight data
    /// - Parameter flights: Array of flights to create annotations from
    /// - Returns: Array of map annotations ready to be displayed
    func createAnnotations(from flights: [Flight]) -> [MKPointAnnotation] {
        return flights.map { flight -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.coordinate = flight.coordinate
            annotation.title = flight.callsign
            return annotation
        }
    }

    /// Updates the list of available countries based on flight data
    /// - Parameter flights: The flights to extract countries from
    /// This method:
    /// - Extracts unique country names from flights
    /// - Filters out empty country names
    /// - Sorts countries alphabetically
    /// - Updates the availableCountries relay
    func updateAvailableCountries(_ flights: [Flight]) {
        let countries = Array(Set(flights.map { $0.originCountry }))
            .filter { !$0.isEmpty } // Remove empty country names
            .sorted() // Sort alphabetically
        availableCountries.accept(countries)
    }

    /// Stops automatic updates
    func stopUpdates() {
        timer?.dispose()
        timer = nil
    }

    // MARK: - Deinitialization
    
    deinit {
        stopUpdates()
    }
}

