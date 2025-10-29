//
//  FlightListVC.swift
//  OpenSkyTrack
//
//  Created by Mehmet Özkan on 28.05.2025.
//

import UIKit
import MapKit
import RxSwift
import RxRelay

final class FlightListViewController: UIViewController, LoadingShowable {
    private let viewModel: FlightViewModelProtocol
    private let disposeBag = DisposeBag()

    init() {
        self.viewModel = FlightViewModel()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var countryPickerButton: UIButton!
    private var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()

        let initialRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 47.0, longitude: 8.0),
            span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 4.0)
        )
        mapView.setRegion(initialRegion, animated: false)
    }

    private func setupUI() {
        mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)

        countryPickerButton = UIButton(type: .system)
        countryPickerButton.translatesAutoresizingMaskIntoConstraints = false
        countryPickerButton.setTitle(StringConstants.allCountries, for: .normal)
        countryPickerButton.backgroundColor = .systemBackground
        countryPickerButton.layer.cornerRadius = 8
        countryPickerButton.layer.shadowColor = UIColor.black.cgColor
        countryPickerButton.addTarget(self, action: #selector(showCountryPicker), for: .touchUpInside)
        view.addSubview(countryPickerButton)

        NSLayoutConstraint.activate([
            countryPickerButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            countryPickerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            countryPickerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            countryPickerButton.heightAnchor.constraint(equalToConstant: 44),

            mapView.topAnchor.constraint(equalTo: countryPickerButton.bottomAnchor, constant: 16),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        mapView.delegate = self
    }

    private func setupBindings() {
        viewModel.isLoading
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
            guard let self = self else { return }
            self.updateLoadingState(isLoading)
        })
            .disposed(by: disposeBag)

        viewModel.filteredFlights
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] flights in
            guard let self = self else { return }
            self.updateMapAnnotations(with: flights)
        })
            .disposed(by: disposeBag)

        viewModel.error
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] error in
            guard let self = self else { return }
            self.showError(error)
        })
            .disposed(by: disposeBag)

        viewModel.isAlertPresented
            .skip(1)
            .subscribe(onNext: { [weak self] isPresented in
            guard let self = self else { return }
            if !isPresented {
                let region = self.mapView.region
                self.viewModel.updateFlights(for: region)
            }
        })
            .disposed(by: disposeBag)
    }

    private func updateLoadingState(_ isLoading: Bool) {
        if isLoading {
            showLoading()
            view.isUserInteractionEnabled = false
            mapView.isZoomEnabled = false
            mapView.isScrollEnabled = false
            countryPickerButton.isEnabled = false
        } else {
            hideLoading()
            view.isUserInteractionEnabled = true
            mapView.isZoomEnabled = true
            mapView.isScrollEnabled = true
            countryPickerButton.isEnabled = true
        }
    }

    private func updateMapAnnotations(with flights: [Flight]) {
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotations(viewModel.createAnnotations(from: flights))
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: StringConstants.error, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: StringConstants.tryAgain, style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.viewModel.isAlertPresented.accept(false)
        })
        present(alert, animated: true)
    }

    @objc private func showCountryPicker() {
        viewModel.isAlertPresented.accept(true)

        let alert = UIAlertController(title: StringConstants.selectCountry, message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: StringConstants.allCountries, style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.viewModel.selectedCountry.accept(nil)
            self.countryPickerButton.setTitle(StringConstants.allCountries, for: .normal)
            self.viewModel.isAlertPresented.accept(false)
        })

        viewModel.availableCountries.value.forEach { country in
            alert.addAction(UIAlertAction(title: country, style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.selectedCountry.accept(country)
                self.countryPickerButton.setTitle(country, for: .normal)
                self.viewModel.isAlertPresented.accept(false)
            })
        }

        alert.addAction(UIAlertAction(title: StringConstants.cancel, style: .cancel) { [weak self] _ in
            self?.viewModel.isAlertPresented.accept(false)
        })

        present(alert, animated: true)
    }
}

// MARK: - MKMapViewDelegate

extension FlightListViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { return nil }

        let identifier = StringConstants.flighAnnotationIdentifier
        let annotationView: MKMarkerAnnotationView

        if let reusableView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
            annotationView = reusableView
            annotationView.annotation = annotation
        } else {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }

        annotationView.glyphImage = UIImage(systemName: StringConstants.annotationImage)
        annotationView.markerTintColor = .systemBlue
        annotationView.canShowCallout = true

        return annotationView
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        viewModel.updateFlights(for: mapView.region)
    }
}
