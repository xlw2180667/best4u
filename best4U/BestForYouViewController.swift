//
//  BestForYouViewController.swift
//  best4U
//
//  Created by Xie Liwei on 2016/10/26.
//  Copyright © 2016年 Xie Liwei. All rights reserved.
//

import UIKit
import MapKit

class BestForYouViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    var points : [JSONParameters]!
    var pointsMKAnnotation : [MKAnnotation]?
    let locationManager = CLLocationManager()
    
    var annotation : MKAnnotation!
    var latitude : Double!
    var longitude : Double!
    var pointName : String!
    var pointDis : String!
    var id : String!
    var coordinate : CLLocationCoordinate2D?
    var locations : [CLLocation]?
    let distanceFormatter = MKDistanceFormatter()
    
    @IBOutlet weak var mapView: MKMapView!{
        didSet{
            mapView.mapType = .standard
            mapView.delegate = self
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isToolbarHidden = false
        mapView.showsUserLocation = true
        
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }

        getPositionsFromPoints()
        addPointAnnotation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.navigationController?.isToolbarHidden = true
    }
    
    private func getPositionsFromPoints() {
        let countPoints = points.count
        for i in 0...(countPoints-1) {
            if pointsMKAnnotation == nil {
                self.id = points[i]["id"] as! String
                self.pointName = points[i]["name"] as! String
                let distance = points[i]["location"]?["distance"] as? CLLocationDistance
                self.pointDis = distanceFormatter.string(fromDistance: distance!)
                self.latitude = points[i]["location"]?["lat"] as! Double
                self.longitude = points[i]["location"]?["lng"] as! Double
                self.coordinate = CLLocationCoordinate2D(latitude:self.latitude,longitude:self.longitude)
                let location = CLLocation(latitude:self.latitude, longitude:self.longitude)
                self.locations = [location]
                self.annotation = Point(title: self.pointName,subtitle: self.pointDis,coordinate: self.coordinate!, id: self.id)
                pointsMKAnnotation = [self.annotation]
            } else {
                self.id = points[i]["id"] as! String
                self.pointName = points[i]["name"] as! String
                let distance = points[i]["location"]?["distance"] as? CLLocationDistance
                self.pointDis = distanceFormatter.string(fromDistance: distance!)
                self.latitude = points[i]["location"]?["lat"] as! Double
                self.longitude = points[i]["location"]?["lng"] as! Double
                self.coordinate = CLLocationCoordinate2D(latitude:self.latitude,longitude:self.longitude)
                let location = CLLocation(latitude:self.latitude, longitude:self.longitude)
                self.annotation = Point(title: self.pointName,subtitle: self.pointDis,coordinate: self.coordinate!, id: self.id)
                pointsMKAnnotation?.append(self.annotation)
                self.locations?.append(location)
            }
        }
    }

    //MARK: - MapView and annotations

    private func addPointAnnotation() {
            mapView?.addAnnotations(pointsMKAnnotation!)
            mapView.showAnnotations(pointsMKAnnotation!, animated: true)

    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "points"
        if annotation .isEqual(mapView.userLocation) {
            return nil
        }
        var view : MKAnnotationView! = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
        } else {
            view.annotation = annotation
        }
        return view
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let directionLine = MKPolylineRenderer(overlay: overlay)
        directionLine.strokeColor = UIColor.blue
        directionLine.lineWidth = 5
        return directionLine
    }

    
    private func bestDirectionCalculation (location:CLLocation, locations: [CLLocation]) -> CLLocation? {
        var bestDirection : (distance: CLLocationDistance, coordinates:CLLocation)?
        for pointLocation in locations {
            let distance = round(location.distance(from: pointLocation))
            if bestDirection == nil {
                bestDirection = (distance, pointLocation)
            } else {
                if distance < bestDirection!.distance {
                    bestDirection = (distance, pointLocation)
                }
            }
        }
        return bestDirection?.coordinates
    }
    
    private func directionsDraw (startLocation: CLLocation,toLocation:CLLocation) {
        
        let startLocationMapItem = MKMapItem(placemark:MKPlacemark(coordinate: startLocation.coordinate, addressDictionary: nil))
        let toLocationMapItem = MKMapItem(placemark: MKPlacemark(coordinate: toLocation.coordinate, addressDictionary: nil))
        let directionRequest = MKDirectionsRequest()
        directionRequest.transportType = .walking
        directionRequest.source = startLocationMapItem
        directionRequest.destination = toLocationMapItem
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (response, error) -> Void in
            if let error = error {
                print("ERROR:\(error.localizedDescription)")
            } else {
                let route = response!.routes[0] as MKRoute
                self.mapView.add(route.polyline)
                if self.locations != nil {
                    let nextLocation = self.bestDirectionCalculation(location: toLocation, locations: self.locations!)
                    if let next = nextLocation {
                        self.directionsDraw(startLocation: toLocation, toLocation: next)
                    }
                    self.locations = self.locations?.filter({ $0 != toLocation})
                }
            }
        }
        
    }

    @IBOutlet weak var bestGo: UIBarButtonItem!
    @IBAction func bestForYou(_ sender: AnyObject) {
        let nextLocatin = bestDirectionCalculation(location: self.locationManager.location!, locations: self.locations!)
        if let next = nextLocatin {
            self.directionsDraw(startLocation: self.locationManager.location!, toLocation: next)
        }
    }
    
    private func showUser(){
        let location = locationManager.location
        let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView!.setRegion(region, animated: true)
        mapView!.setCenter(mapView.userLocation.coordinate, animated: true)
    }
    @IBAction func showUserPosition(_ sender: AnyObject) {
        showUser()
    }
}
