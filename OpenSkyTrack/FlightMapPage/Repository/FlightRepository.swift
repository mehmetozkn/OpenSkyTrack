import Foundation
import RxSwift
import RxRelay
import MapKit

protocol FlightRepositoryProtocol {
    var flights: BehaviorRelay<[Flight]> { get }
    var error: PublishRelay<String> { get }
    var isLoading: BehaviorRelay<Bool> { get }

    func fetchFlights(for region: MKCoordinateRegion)
    func stopUpdates()
}

final class FlightRepository: FlightRepositoryProtocol {
    let flights: BehaviorRelay<[Flight]> = BehaviorRelay(value: [])
    let error: PublishRelay<String> = PublishRelay()
    let isLoading: BehaviorRelay<Bool> = BehaviorRelay(value: false)

    private let baseService: BaseServiceProtocol
    private let appStorage: AppStorageProtocol
    private let disposeBag = DisposeBag()
    private var timer: Disposable?
    private var lastRegion: MKCoordinateRegion?

    private let cacheExpirationInterval: TimeInterval = 5

    init(baseService: BaseServiceProtocol = BaseService.shared, appStorage: AppStorageProtocol = AppStorage.shared) {
        self.baseService = baseService
        self.appStorage = appStorage
        setupTimer()
    }

    func fetchFlights(for region: MKCoordinateRegion) {
        lastRegion = region
        isLoading.accept(true)

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
                             self.cacheFlights(newFlights)
                             self.isLoading.accept(false)
                         },
                         onError: { [weak self] error in
                             guard let self = self else { return }
                             if case NetworkError.offline = error {
                                 if let cachedFlights = self.getCachedFlights() {
                                     self.flights.accept(cachedFlights)
                                 } else {
                                     self.error.accept(error.localizedDescription)
                                 }
                             } else {
                                 self.error.accept(error.localizedDescription)
                             }
                             self.isLoading.accept(false)
                         })
    }

    func stopUpdates() {
        timer?.dispose()
        timer = nil
    }

    private func setupTimer() {
        timer = Observable<Int>.interval(.seconds(Int(cacheExpirationInterval)), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
            guard let self = self, let region = self.lastRegion else { return }
            self.fetchFlights(for: region)
        })
        timer?.disposed(by: disposeBag)
    }

    private func cacheFlights(_ flights: [Flight]) {
        appStorage.save(flights, key: StorageKeys.cachedFlights)
    }

    private func getCachedFlights() -> [Flight]? {
        return appStorage.get(key: StorageKeys.cachedFlights, as: [Flight].self)
    }
}
