//
//  PointMapViewController.swift
//  Best4U
//
//  Created by Xie Liwei on 2016/10/04.
//  Copyright © 2016年 Xie Liwei. All rights reserved.
//

import UIKit
import MapKit
import QuadratTouch

class PointMapViewController: UIViewController,MKMapViewDelegate, CLLocationManagerDelegate {

    var task : Task!
    var session : Session!
    let locationManager = CLLocationManager()
    var route : MKRoute!
    
    // MARK: - One point display model
    var annotation : MKAnnotation!
    var latitude : Double!
    var longitude : Double!
    var id : String!
    var pointName : String!
    var pointDis : String!
    var pointImage : UIImage?
    var coordinate : CLLocationCoordinate2D?

    // MARK: - Best plan model
    var firstPointAnnotation : MKAnnotation!
    var secondPointAnnotation : MKAnnotation!
    var thirdPointAnnotation : MKAnnotation!
    var firstPointlatitude : Double!
    var secondPointlatitude : Double!
    var thirdPointlatitude : Double!
    var firstPointlongitude : Double!
    var secondPointlongitude : Double!
    var thirdPointlongitude : Double!
    var firstPointId : String!
    var secondPointId : String!
    var thirdPointId : String!
    var firstPointName : String!
    var secondPointName : String!
    var thirdPointName : String!
    var firstPointDis : String!
    var secondPointDis : String!
    var thirdPointDis : String!
    var firstCoordinate : CLLocationCoordinate2D?
    var secondCoordinate : CLLocationCoordinate2D?
    var thirdCoordinate : CLLocationCoordinate2D?
    var threePoints : [MKAnnotation]?
    

    @IBOutlet weak var bestGo: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView! {
        didSet{
            mapView.mapType = .standard
            mapView.delegate = self
            if self.coordinate != nil {
            mapView.centerCoordinate = self.coordinate!
            } else {
                mapView.centerCoordinate = (locationManager.location?.coordinate)!

            }
        }
    }

    
    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.showsUserLocation = true
        
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        if self.latitude != nil {

            self.coordinate = CLLocationCoordinate2D(latitude:self.latitude,longitude:self.longitude)
            self.annotation = Point(title: self.pointName,subtitle: self.pointDis,coordinate: self.coordinate!, id: self.id)
            self.bestGo.isEnabled = false
            self.getImageURLFromID(id: self.id)

        } else {
            self.firstCoordinate = CLLocationCoordinate2D(latitude: firstPointlatitude, longitude: firstPointlongitude)
            self.firstPointAnnotation = Point(title: self.firstPointName, subtitle: "", coordinate: self.firstCoordinate!, id: self.firstPointId!)
            self.secondCoordinate = CLLocationCoordinate2D(latitude: secondPointlatitude, longitude: secondPointlongitude)
            self.secondPointAnnotation = Point(title: self.secondPointName, subtitle: "", coordinate: self.secondCoordinate!, id: self.secondPointId!)
            self.thirdCoordinate = CLLocationCoordinate2D(latitude: thirdPointlatitude, longitude: thirdPointlongitude)
            self.thirdPointAnnotation = Point(title: self.secondPointName, subtitle: "", coordinate: self.thirdCoordinate!, id: self.thirdPointId)
            self.threePoints = [self.firstPointAnnotation, self.secondPointAnnotation, self.thirdPointAnnotation]
            
        }
        addPointAnnotation()
    }
    
    //MARK: - MapView and annotations
    private func addPointAnnotation() {
        if self.latitude != nil {
            mapView?.addAnnotation(self.annotation)
            mapView.showAnnotations([self.annotation], animated: true)
        } else {
            mapView.addAnnotations(self.threePoints!)
            mapView.showAnnotations(self.threePoints!, animated: true)
        }
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
        if self.latitude != nil {
            view.leftCalloutAccessoryView = UIButton(frame: CGRect(x: 0, y: 0, width: 59, height: 59))
        }


        return view
        }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {

        if let leftImageButton = view.leftCalloutAccessoryView as? UIButton {
            leftImageButton.setImage(self.pointImage, for: .normal)
        }

    }
 
    //MARK: - Draw directions
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let directionLine = MKPolylineRenderer(overlay: overlay)
        directionLine.strokeColor = UIColor.blue
        directionLine.lineWidth = 5
        return directionLine
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.leftCalloutAccessoryView {
            if self.latitude != nil {
                directionsDraw(startLocation: self.locationManager.location!, toLocation: CLLocation(latitude: self.latitude, longitude: self.longitude))
            }
        }
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
    var locations : [CLLocation]?
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
    
    @IBAction func bestPathForYou(_ sender: AnyObject) {
        let firstPoint : CLLocation = CLLocation(latitude: firstPointlatitude, longitude: firstPointlongitude)
        let secondPoint : CLLocation = CLLocation(latitude: secondPointlatitude, longitude: secondPointlongitude)
        let thirdPoint : CLLocation = CLLocation(latitude: thirdPointlatitude, longitude: thirdPointlongitude)
        self.locations = [firstPoint,secondPoint,thirdPoint]
        let nextLocatin = bestDirectionCalculation(location: self.locationManager.location!, locations: self.locations!)
        if let next = nextLocatin {
            self.directionsDraw(startLocation: self.locationManager.location!, toLocation: next)
        }
        self.bestGo.isEnabled = false
    }
    //MARK: - Fetch image data
    private func getImageURLFromID (id:String){
        self.task = self.session.venues.photos(id, parameters: nil) {
            (result) -> Void in
            if let response = result.response {
                if let photos = response["photos"]?["items"] as! NSArray? {
                    if let photo = photos.firstObject as? NSDictionary {
                        let prefix = photo.object(forKey: "prefix") as! String
                        let suffix = photo.object(forKey: "suffix") as! String
                        let photoURLString = prefix + "100x100" + suffix
                        let url = Foundation.URL(string: photoURLString)!
                        if let imageData = self.session.cachedImageDataForURL(url) {
                            self.pointImage = UIImage(data:imageData)
                        } else {
                            self.session.downloadImageAtURL(url){
                                (imageData, error) -> Void in
                                if imageData != nil {
                                    self.pointImage = UIImage(data:imageData!)
                                }
                            }
                        }
                    } else {
                        self.pointImage = UIImage(named: "1.jpg")
                    }
                }
            }
        }
        self.task?.start()
    }
    
    private func showUser(){
        let location = locationManager.location
        let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView!.setRegion(region, animated: true)
        mapView!.setCenter(mapView.userLocation.coordinate, animated: true)
    }
    
    @IBAction func showUserPosition(_ sender: AnyObject) {
        self.showUser()
    }
}










