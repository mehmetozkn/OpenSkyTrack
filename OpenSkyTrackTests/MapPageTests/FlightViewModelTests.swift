import XCTest
import RxSwift
import RxRelay
import MapKit

@testable import OpenSkyTrack

final class FlightViewModelTests: XCTestCase {
    var viewModel: FlightViewModel!
    var mockService: MockFlightService!
    var disposeBag: DisposeBag!

    private let defaultTimeout: TimeInterval = 1.0

    override func setUp() {
        super.setUp()
        mockService = MockFlightService()
        viewModel = FlightViewModel(service: mockService)
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        viewModel = nil
        mockService = nil
        disposeBag = nil
        super.tearDown()
    }

    func testInitialState_ShouldHaveEmpty() {
        XCTAssertTrue(viewModel.flights.value.isEmpty)
        XCTAssertFalse(viewModel.isLoading.value)
        XCTAssertTrue(viewModel.availableCountries.value.isEmpty)
        XCTAssertNil(viewModel.selectedCountry.value)
    }

    // service call successful test
    func testUpdateFlights_WhenServiceSucceeds_ShouldUpdateFlights() {
        let expectation = XCTestExpectation(description: "Flights updated")
        let mockFlights = [
            createMockFlightData(callsign: "TEST1"),
            createMockFlightData(callsign: "TEST2")
        ]

        mockService.shouldReturnError = false
        mockService.mockResponse = FlightResponse(time: 1622222222, states: mockFlights)

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

    // service call failed test
    func testUpdateFlights_WhenServiceFails_ShouldEmitError() {
        let expectation = XCTestExpectation(description: "Error received")
        mockService.shouldReturnError = true
        mockService.mockResponse = nil

        viewModel.error
            .subscribe(onNext: { error in
            XCTAssertEqual(error, "Test error")
            expectation.fulfill()
        })
            .disposed(by: disposeBag)

        viewModel.updateFlights(for: MKCoordinateRegion())
        wait(for: [expectation], timeout: defaultTimeout)
    }

    // filter flights by selected country successful test
    func testFilterFlightsByCountry_WhenCountryMatches_ShouldReturnFilteredFlights() {
        let expectation = XCTestExpectation(description: "Flights filtered by country")
        let mockFlights = [
            Flight(from: createMockFlightData(callsign: "TEST1", country: "USA")),
            Flight(from: createMockFlightData(callsign: "TEST2", country: "Turkey"))
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

    // filter flights by selected country with unmatched country
    func testFilterFlightsByCountry_WhenNoMatch_ShouldReturnEmptyList() {
        let expectation = XCTestExpectation(description: "No flights should match the selected country")
        let mockFlights = [
            Flight(from: createMockFlightData(callsign: "TEST1", country: "Germany")),
            Flight(from: createMockFlightData(callsign: "TEST2", country: "Turkey"))
        ]

        viewModel.flights.accept(mockFlights)
        viewModel.selectedCountry.accept("USA") // USA yok

        viewModel.filteredFlights
            .subscribe(onNext: { flights in
            XCTAssertEqual(flights.count, 0, "Expected no flights to match the selected country")
            expectation.fulfill()
        })
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: defaultTimeout)
    }

    // live flights filter successful test
    func testFilterFlightsByGroundedStatus_ShouldReturnOnlyFlyingFlights() {
        let expectation = XCTestExpectation(description: "Grounded flights filtered")
        let mockFlights = [
            Flight(from: createMockFlightData(callsign: "TEST1", onGround: true)),
            Flight(from: createMockFlightData(callsign: "TEST2", onGround: false))
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

    // successful test of showing each country once in country selection
    func testUpdateAvailableCountries_ShouldReturnUniqueCountries() {
        let mockFlights = [
            Flight(from: createMockFlightData(callsign: "TEST1", country: "USA")),
            Flight(from: createMockFlightData(callsign: "TEST2", country: "Turkey")),
            Flight(from: createMockFlightData(callsign: "TEST3", country: "USA"))
        ]

        viewModel.updateAvailableCountries(mockFlights)

        let countries = viewModel.availableCountries.value
        XCTAssertEqual(countries.count, 2)
        XCTAssertTrue(countries.contains("USA"))
        XCTAssertTrue(countries.contains("Turkey"))
    }
}

extension FlightViewModelTests {
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


