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

/// FlightListViewController displays a map with real-time flight tracking
/// This view controller is responsible for:
/// - Displaying flights on a map
/// - Filtering flights by country
/// - Handling loading states and errors
/// - Updating flight positions in real-time
final class FlightListViewController: UIViewController {
    private let viewModel = FlightViewModel(service: BaseService.shared)
    private let disposeBag = DisposeBag()

    // MARK: - UI Components
    
    /// Button for selecting country filters
    private var countryPickerButton: UIButton!
    
    /// MapView displaying flight locations
    private var mapView: MKMapView!
    
    /// Activity indicator for loading states
    private var loadingIndicator: UIActivityIndicatorView!
    
    /// Semi-transparent view for loading overlay
    private var overlayView: UIView!

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()

        // Set initial region
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

        // Setup Country Picker Button
        countryPickerButton = UIButton(type: .system)
        countryPickerButton.translatesAutoresizingMaskIntoConstraints = false
        countryPickerButton.setTitle(StringConstants.allCountries, for: .normal)
        countryPickerButton.backgroundColor = .systemBackground
        countryPickerButton.layer.cornerRadius = 8
        countryPickerButton.layer.shadowColor = UIColor.black.cgColor
        countryPickerButton.addTarget(self, action: #selector(showCountryPicker), for: .touchUpInside)
        view.addSubview(countryPickerButton)

        // Setup Loading Indicator ve Overlay
        setupLoadingViews()

        // Setup Constraints
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

    private func setupLoadingViews() {
        // Setup overlay view
        overlayView = UIView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayView.isHidden = true
        view.addSubview(overlayView)

        // Setup loading indicator
        loadingIndicator = UIActivityIndicatorView(style: .large)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = .white
        overlayView.addSubview(loadingIndicator)

        // Setup constraints for overlay and indicator
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor)
        ])
    }

    private func setupBindings() {
        // Bind loading state
        viewModel.isLoading
            .subscribe(onNext: { [weak self] isLoading in
            guard let self = self else { return }
            self.updateLoadingState(isLoading)
        })
            .disposed(by: disposeBag)

        // Bind flights
        viewModel.filteredFlights
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] flights in
            guard let self = self else { return }
            self.updateMapAnnotations(with: flights)
        })
            .disposed(by: disposeBag)

        // Bind error messages
        viewModel.error
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] error in
            guard let self = self else { return }
            self.showError(error)
        })
            .disposed(by: disposeBag)

        // Bind alert state
        viewModel.isAlertPresented
            .skip(1) // skip initial value to avoid unnecessary processing
        .subscribe(onNext: { [weak self] isPresented in
            guard let self = self else { return }
            if !isPresented {
                // Alert dismissed, update the map if needed
                let region = self.mapView.region
                self.viewModel.updateFlights(for: region)
            }
        })
            .disposed(by: disposeBag)
    }

    private func updateLoadingState(_ isLoading: Bool) {
        overlayView.isHidden = !isLoading
        if isLoading {
            loadingIndicator.startAnimating()
            view.isUserInteractionEnabled = false
            mapView.isZoomEnabled = false
            mapView.isScrollEnabled = false
            countryPickerButton.isEnabled = false
        } else {
            loadingIndicator.stopAnimating()
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
        // Set alert state to true to prevent API calls
        viewModel.isAlertPresented.accept(true)

        let alert = UIAlertController(title: StringConstants.selectCountry, message: nil, preferredStyle: .actionSheet)

        // Add "All Countries" option
        alert.addAction(UIAlertAction(title: StringConstants.allCountries, style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.viewModel.selectedCountry.accept(nil)
            self.countryPickerButton.setTitle(StringConstants.allCountries, for: .normal)
            self.viewModel.isAlertPresented.accept(false)
        })

        // Add country options
        viewModel.availableCountries.value.forEach { country in
            alert.addAction(UIAlertAction(title: country, style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.selectedCountry.accept(country)
                self.countryPickerButton.setTitle(country, for: .normal)
                self.viewModel.isAlertPresented.accept(false)
            })
        }

        // Add cancel action
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

        // Try to dequeue a reusable annotation view
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
