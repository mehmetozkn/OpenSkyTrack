import XCTest
import RxSwift
import RxRelay
import MapKit

@testable import OpenSkyTrack

final class FlightViewModelTests: XCTestCase {
    var viewModel: FlightViewModel!
    var mockService: MockBaseService!
    var disposeBag: DisposeBag!

    private let defaultTimeout: TimeInterval = 1.0

    override func setUp() {
        super.setUp()
        mockService = MockBaseService()
        viewModel = FlightViewModel(service: mockService)
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        viewModel = nil
        mockService = nil
        disposeBag = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertTrue(viewModel.flights.value.isEmpty)
        XCTAssertFalse(viewModel.isLoading.value)
        XCTAssertTrue(viewModel.availableCountries.value.isEmpty)
        XCTAssertNil(viewModel.selectedCountry.value)
    }

    func testUpdateFlightsSuccess() {
        let expectation = XCTestExpectation(description: "Flights updated")
        let mockFlights = [
            createMockFlightData(callsign: "TEST1"),
            createMockFlightData(callsign: "TEST2")
        ]

        mockService.shouldReturnError = false
        mockService.mockFlightResponse = OpenSkyTrack.FlightResponse(time: 1622222222, states: mockFlights)

        viewModel.flights
            .skip(1)
            .subscribe(onNext: { flights in
            XCTAssertEqual(flights.count, 2)
            XCTAssertEqual(flights[0].callsign, "TEST1")
            XCTAssertEqual(flights[1].callsign, "TEST2")
            expectation.fulfill()
        })
            .disposed(by: disposeBag)

        viewModel.updateFlights(for: MKCoordinateRegion())
        wait(for: [expectation], timeout: defaultTimeout)
    }

    func testUpdateFlightsFailure() {
        let expectation = XCTestExpectation(description: "Error received")
        mockService.shouldReturnError = true
        mockService.mockFlightResponse = nil

        viewModel.error
            .subscribe(onNext: { error in
            XCTAssertEqual(error, "Mock Error")
            expectation.fulfill()
        })
            .disposed(by: disposeBag)

        viewModel.updateFlights(for: MKCoordinateRegion())
        wait(for: [expectation], timeout: defaultTimeout)
    }

    func testFilterFlightsByCountry() {
        let expectation = XCTestExpectation(description: "Flights filtered by country")
        let mockFlights = [
            OpenSkyTrack.Flight(from: createMockFlightData(callsign: "TEST1", country: "USA")),
            OpenSkyTrack.Flight(from: createMockFlightData(callsign: "TEST2", country: "Turkey"))
        ]

        viewModel.flights.accept(mockFlights)
        viewModel.selectedCountry.accept("USA")

        viewModel.filteredFlights
            .subscribe(onNext: { flights in
            XCTAssertEqual(flights.count, 1)
            XCTAssertEqual(flights[0].callsign, "TEST1")
            expectation.fulfill()
        })
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: defaultTimeout)
    }

    func testFilterGroundedFlights() {
        let expectation = XCTestExpectation(description: "Grounded flights filtered")
        let mockFlights = [
            OpenSkyTrack.Flight(from: createMockFlightData(callsign: "TEST1", onGround: true)),
            OpenSkyTrack.Flight(from: createMockFlightData(callsign: "TEST2", onGround: false))
        ]

        viewModel.flights.accept(mockFlights)

        viewModel.filteredFlights
            .subscribe(onNext: { flights in
            XCTAssertEqual(flights.count, 1)
            XCTAssertEqual(flights[0].callsign, "TEST2")
            expectation.fulfill()
        })
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: defaultTimeout)
    }

    func testUpdateAvailableCountries() {
        let mockFlights = [
            OpenSkyTrack.Flight(from: createMockFlightData(callsign: "TEST1", country: "USA")),
            OpenSkyTrack.Flight(from: createMockFlightData(callsign: "TEST2", country: "Turkey")),
            OpenSkyTrack.Flight(from: createMockFlightData(callsign: "TEST3", country: "USA"))
        ]

        viewModel.updateAvailableCountries(mockFlights)

        let countries = viewModel.availableCountries.value
        XCTAssertEqual(countries.count, 2)
        XCTAssertTrue(countries.contains("USA"))
        XCTAssertTrue(countries.contains("Turkey"))
    }

    // MARK: - Helper Method

    private func createMockFlightData(
        callsign: String,
        country: String = "Test Country",
        onGround: Bool = false
    ) -> [Any?] {
        return [
            "test", // icao24
            callsign,
            country,
            1622222222, // timePosition
            1622222222, // lastContact
            151.2, // longitude
            33.9, // latitude
            10000, // altitude
            onGround
        ]
    }
}

