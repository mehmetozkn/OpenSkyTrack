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

final class FlightListViewController: UIViewController {
    private let viewModel = FlightViewModel(service: BaseService.shared)
    private let disposeBag = DisposeBag()

    private var countryPickerButton: UIButton!
    private var mapView: MKMapView!
    private var loadingIndicator: UIActivityIndicatorView!
    private var overlayView: UIView!

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
        viewModel.updateFlights(for: initialRegion)
    }

    private func setupUI() {
        mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)

        // Setup Country Picker Button
        countryPickerButton = UIButton(type: .system)
        countryPickerButton.translatesAutoresizingMaskIntoConstraints = false
        countryPickerButton.setTitle("All Countries", for: .normal)
        countryPickerButton.backgroundColor = .systemBackground
        countryPickerButton.layer.cornerRadius = 8
        countryPickerButton.layer.shadowColor = UIColor.black.cgColor
        countryPickerButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        countryPickerButton.layer.shadowRadius = 4
        countryPickerButton.layer.shadowOpacity = 0.2
        countryPickerButton.addTarget(self, action: #selector(showCountryPicker), for: .touchUpInside)
        view.addSubview(countryPickerButton)

        // Setup Loading Indicator ve Overlay
        setupLoadingViews()

        // Setup Constraints
        NSLayoutConstraint.activate([
            countryPickerButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
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
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
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
            self?.updateLoadingState(isLoading)
        })
            .disposed(by: disposeBag)

        // Bind flights
        viewModel.filteredFlights
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] flights in
            self?.updateMapAnnotations(with: flights)
        })
            .disposed(by: disposeBag)

        // Bind error messages
        viewModel.error
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] error in
            self?.showError(error)
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

        let annotations = flights.map { flight -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.coordinate = flight.coordinate
            annotation.title = flight.callsign
            return annotation
        }

        mapView.addAnnotations(annotations)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func showCountryPicker() {
        let alert = UIAlertController(title: "Select Country", message: nil, preferredStyle: .actionSheet)

        // Add "All Countries" option
        alert.addAction(UIAlertAction(title: "All Countries", style: .default) { [weak self] _ in
            self?.viewModel.selectedCountry.accept(nil)
            self?.countryPickerButton.setTitle("All Countries", for: .normal)
        })

        // Add country options
        viewModel.availableCountries.value.forEach { country in
            alert.addAction(UIAlertAction(title: country, style: .default) { [weak self] _ in
                self?.viewModel.selectedCountry.accept(country)
                self?.countryPickerButton.setTitle(country, for: .normal)
            })
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - MKMapViewDelegate

extension FlightListViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { return nil }

        let identifier = "FlightAnnotation"

        let annotationView: MKMarkerAnnotationView

        // Try to dequeue a reusable annotation view
        if let reusableView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
            annotationView = reusableView
            annotationView.annotation = annotation
        } else {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }

        annotationView.glyphImage = UIImage(systemName: "airplane")
        annotationView.markerTintColor = .systemBlue
        annotationView.canShowCallout = true

        return annotationView
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        viewModel.updateFlights(for: mapView.region)
    }
}




