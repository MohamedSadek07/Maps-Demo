//
//  ViewController.swift
//  Maps Demo
//
//  Created by Mohamed Ahmed Sadek on 3/31/19.
//  Copyright © 2019 ItShare. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var dismissButton: UIButton!
    
    let locationManager = CLLocationManager()
    var previousLocation : CLLocation?
    var directionsArray : [MKDirections] = []
    let annotation = MKPointAnnotation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
       
        goButton.layer.cornerRadius =  30
        goButton.layer.borderColor = UIColor.white.cgColor
        dismissButton.layer.cornerRadius = 30
        
        mapView.delegate = self
        checkLocationAuthorization()
    }

    
    func checkLocationAuthorization(){
        switch CLLocationManager.authorizationStatus() {
          case .authorizedWhenInUse , .authorizedAlways :
              trackUserLocation()
              break
          case .notDetermined:
              locationManager.requestWhenInUseAuthorization()
              break
          case .restricted:
              // alert guiding them what to do
              break
          case .denied:
              whenAuthorizationdenied()
              break
        }
    }

    
    func trackUserLocation(){
        mapView.showsUserLocation = true
        locationManager.startUpdatingLocation()
        previousLocation = getCenterLocation(mapView: mapView)
    }
    
    func whenAuthorizationdenied() {
        let alert = UIAlertController(title: "Location is dendied", message: "You have denied location access before, would you like to change it in settings?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .default))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (_) in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {return}
            if UIApplication.shared.canOpenURL(settingsUrl){
                UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
            }
        }))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    func resetMapView (directions : MKDirections){
        mapView.removeOverlays(mapView.overlays)
         directionsArray.append(directions)
        let _ = directionsArray.map { $0.cancel()}
    }
    
    func createDirectionRequest(coordinate : CLLocationCoordinate2D) -> MKDirections.Request{
        let destinationCoordinate = getCenterLocation(mapView: mapView).coordinate
        let startingPoint = MKPlacemark(coordinate: coordinate)
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingPoint)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        
        return request
    }
    
      // It will be called when the go button is clicked , firstly it grts the current coordinates then call createDirectionRequest passing currnt coordinates to it ,then we reset the map from pending routes ,finally we make direction variable given request made brfore to calculate the distance and itertate on the stated routes making them visible and enlarge the view as the route estimated.
    func getDirections(){
        guard let location = locationManager.location?.coordinate else {return}
        
        let request = createDirectionRequest(coordinate: location)
        let direction = MKDirections(request: request)
         resetMapView(directions: direction)
        
        direction.calculate { [unowned self] (response, error) in
            if let _ = error {
                print("Error occured while specifing routes")
            }
            
            guard let response = response else {return}
              for route in response.routes {
                DispatchQueue.main.async {
                    self.mapView.addOverlay(route.polyline)
                    self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                }
            }
        }
    }
    
    
   
    
    //MARK:Buttons
    @IBAction func goButtonAction(_ sender: UIButton) {
        goButton.isEnabled = false
        getDirections()
    }

    
    @IBAction func dismissButtonAction(_ sender: UIButton) {
        mapView.removeOverlays(mapView.overlays)
        goButton.isEnabled = true
    }
    
    
    func getCenterLocation(mapView : MKMapView) -> CLLocation{
        let longitude = mapView.centerCoordinate.longitude
        let latitude = mapView.centerCoordinate.latitude
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
}


 // CLLocation Delegate
extension ViewController : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus){
        if status == .authorizedWhenInUse || status == .authorizedAlways {
             manager.startUpdatingLocation()
        }
       
    }
    
     func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        guard let location = locations.first else {return}
        
        let region = MKCoordinateRegion.init(center: location.coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        mapView.setRegion(region, animated: true)
        print("Longtuide \(location.coordinate.longitude)")
        print("latitude \(location.coordinate.latitude)")

        //        mapView.centerCoordinate = location.coordinate
        //        let annotation = MKPointAnnotation()
        //        annotation.coordinate = location.coordinate
        //        mapView.addAnnotation(annotation)
    }
}

// MapView Delegate
extension ViewController : MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("Region is Changed")
    
        if goButton.isEnabled {
          mapView.removeAnnotations(mapView.annotations)
            annotation.coordinate = mapView.centerCoordinate
              mapView.addAnnotation(annotation)
        } else{
            annotation.coordinate = (previousLocation?.coordinate)!
        }
        
        let center = getCenterLocation(mapView: mapView)
        let geoCoder = CLGeocoder()
    
        guard self.previousLocation != nil else {return}
         guard center.distance(from: previousLocation!) > 50 else {return}
          self.previousLocation = center
        
        geoCoder.reverseGeocodeLocation(center) { [weak self](placemarks, error) in
            guard let self = self  else {return}
            if let _ = error {
                print("Error found")
                 return
            }
            guard let placemark = placemarks?.first else {
                // alert
                 return
            }
              let streetNumber = placemark.subThoroughfare ?? ""
                let streetName = placemark.thoroughfare ?? ""
                 DispatchQueue.main.async {
                   self.addressLabel.text = "\(streetNumber)\(streetName)"
            }
        }
    }
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let render = MKPolylineRenderer(overlay: overlay)
          render.strokeColor = .blue
            return render
    }
}
