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

    

    @IBOutlet weak var bestGo: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView! {
        didSet{
            mapView.mapType = .standard
            mapView.delegate = self
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

        self.coordinate = CLLocationCoordinate2D(latitude:self.latitude,longitude:self.longitude)
        self.annotation = Point(title: self.pointName,subtitle: self.pointDis,coordinate: self.coordinate!, id: self.id)
        self.getImageURLFromID(id: self.id)

        addPointAnnotation()
    }
    
    //MARK: - MapView and annotation
    private func addPointAnnotation() {
        mapView?.addAnnotation(self.annotation)
        mapView.showAnnotations([self.annotation], animated: true)

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
            drawDirection()
        }
    }
    
    private func drawDirection () {
        let startLocationMapItem = MKMapItem(placemark:MKPlacemark(coordinate: (self.locationManager.location?.coordinate)!, addressDictionary: nil))
        let toLocationMapItem = MKMapItem(placemark: MKPlacemark(coordinate: self.coordinate!, addressDictionary: nil))
        let directionRequest = MKDirectionsRequest()
        directionRequest.transportType = .walking
        directionRequest.source = startLocationMapItem
        directionRequest.destination = toLocationMapItem
        let direction = MKDirections(request: directionRequest)
        direction.calculate { (response, error) -> Void in
            if let error = error {
                print("ERROR:\(error.localizedDescription)")
            } else {
                let route = response!.routes[0] as MKRoute
                self.mapView.add(route.polyline)
            }
        }
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
    
    public func showUser(){
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










