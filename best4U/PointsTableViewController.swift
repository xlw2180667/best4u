//
//  PointsTableViewController.swift
//  best4U
//
//  Created by Xie Liwei on 2016/10/5.
//  Copyright © 2016年 Xie Liwei. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import QuadratTouch

typealias JSONParameters = [String: AnyObject]

class PointsTableViewController: UITableViewController, CLLocationManagerDelegate, SessionAuthorizationDelegate, UISearchBarDelegate, UIAlertViewDelegate {
    
    // MARK: - Models
    var locationManager : CLLocationManager!
    var points : [JSONParameters]!
    var session : Session!
    var task : Task?
    var getPhotoTask : Task?
    var photoOfPoint : UIImage?
    var pointPhotoURL : URL?
    var pointID : String?
    var searchText = ""
    let distanceFormatter = MKDistanceFormatter()

    
    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
        self.session = Session.sharedSession()
        self.locationManager = CLLocationManager()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.delegate = self
        self.locationManager.startUpdatingLocation()
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.goButton.isEnabled = false
        
        self.refreshControl?.attributedTitle = NSAttributedString(string: "Pull Me!")
        self.refreshControl?.addTarget(self, action:#selector(PointsTableViewController.refresh(sender:)),for: UIControlEvents.valueChanged)

    }
    // MARK: - Pull and refresh
    func refresh(sender:AnyObject){
        searchPoints()
        self.refreshControl?.endRefreshing()
    }
    // MARK: - Location and search functions
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .denied || status == .restricted {
            let alert = UIAlertController(title: "No Permission" , message: "Cannot get the location", preferredStyle: .alert)
            let openSettings = UIAlertAction(title: "Open settings", style: .default, handler: {
                (action) -> Void in
                let URL = Foundation.URL(string: UIApplicationOpenSettingsURLString)
                UIApplication.shared.open(URL!)
                self.dismiss(animated: true, completion: nil)
            })
            alert.addAction(openSettings)
            alert.view.tintColor = UIColor.black
            present(alert, animated: true, completion: nil)
        } else {
            self.locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations:[CLLocation]) {
        if self.points == nil {
            searchPoints()
        }
        self.locationManager.stopUpdatingLocation()
    }
    
    @IBOutlet weak var searchField: UISearchBar! {
        didSet {
            searchField.delegate = self
            searchField.text = ""
        }
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchField.endEditing(true)
        self.searchField.showsCancelButton = false
    }
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.searchField.showsCancelButton = false
    }
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchField.showsCancelButton = true
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchField.resignFirstResponder()
        searchText = searchField.text!
        searchPoints()
    }

    private func searchPoints() {
        let location = self.locationManager.location
        
        if location == nil {
            return
        }
        self.task?.cancel()
        var parameters = [Parameter.query:searchText]
        parameters += location?.parameters()
        self.task = self.session.venues.search(parameters) {
            (result) -> Void in
            if let response = result.response {
                self.points = response["venues"] as? [JSONParameters]
                self.tableView.reloadData()
            }
        }
        self.task?.start()
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let points = self.points {
            return points.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "points", for: indexPath) as! PointsTableViewCell
        let point = points[(indexPath as NSIndexPath).row]
        if let location = point["location"] as? JSONParameters {
            if let distance = location["distance"] as? CLLocationDistance {
                cell.distanceAndAddressLabel?.text = distanceFormatter.string(fromDistance: distance)
            }
                cell.nameLabel?.text = (point["name"] as? String)!
        }
        return cell
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showMeOnTheMap" {
            if let destination = segue.destination as? PointMapViewController {
                let path = tableView.indexPathForSelectedRow
                let row = path?.row
                let point = points[row!]
                destination.session = self.session
                destination.id = point["id"] as? String
                destination.pointName = point["name"] as? String
                if let location = point["location"] as? JSONParameters {
                    if let distance = location["distance"] as? CLLocationDistance {
                        destination.pointDis = distanceFormatter.string(fromDistance: distance)
                        destination.latitude = location["lat"] as! Double
                        destination.longitude = location["lng"] as! Double
                    }
                }

            }
        }
        if segue.identifier == "bestforyou" {
            if tableView.indexPathsForSelectedRows?.count == 3 {
                if let destination = segue.destination as? PointMapViewController {
                    if let selectedRows = tableView.indexPathsForSelectedRows {
                        let firstPointIndexPath = selectedRows[0][1]
                        let secondPointIndexPath = selectedRows[1][1]
                        let thirdPointIndexPath = selectedRows[2][1]
                        let firstPoint = points[firstPointIndexPath]
                        let secondPoint = points[secondPointIndexPath]
                        let thirdPoint = points[thirdPointIndexPath]
                        
                        
                        destination.session = self.session
                        // First point
                        destination.firstPointId = firstPoint["id"] as? String
                        destination.firstPointName = firstPoint["name"] as? String
                        if let firstPointLocation = firstPoint["location"] as? JSONParameters {
                            if let distance = firstPointLocation["distance"] as? CLLocationDistance {
                                destination.firstPointDis = distanceFormatter.string(fromDistance: distance)
                                destination.firstPointlatitude = firstPointLocation["lat"] as! Double
                                destination.firstPointlongitude = firstPointLocation["lng"] as! Double
                            }
                        }
                        // Second point
                        destination.secondPointId = secondPoint["id"] as? String
                        destination.secondPointName = secondPoint["name"] as? String
                        if let secondPointLocation = secondPoint["location"] as? JSONParameters {
                            if let distance = secondPointLocation["distance"] as? CLLocationDistance {
                                destination.secondPointDis = distanceFormatter.string(fromDistance: distance)
                                destination.secondPointlatitude = secondPointLocation["lat"] as! Double
                                destination.secondPointlongitude = secondPointLocation["lng"] as! Double
                            }
                        }
                        // Third point
                        destination.thirdPointId = thirdPoint["id"] as? String
                        destination.thirdPointName = thirdPoint["name"] as? String
                        if let thirdPointLocation = thirdPoint["location"] as? JSONParameters {
                            if let distance = thirdPointLocation["distance"] as? CLLocationDistance {
                                destination.thirdPointDis = distanceFormatter.string(fromDistance: distance)
                                destination.thirdPointlatitude = thirdPointLocation["lat"] as! Double
                                destination.thirdPointlongitude = thirdPointLocation["lng"] as! Double
                            }
                        }
                    }
                    self.isEditing = !self.isEditing
                    self.goButton.isEnabled = false

                }
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "showMeOnTheMap" {
            if tableView.isEditing {
                return false
            }
        } else if identifier == "bestforyou" {
            if tableView.indexPathsForSelectedRows?.count != 3 {
                let alert = UIAlertController(title: "Oooops", message: "Select 3 points then we can go!", preferredStyle: .alert)
                alert.view.tintColor = UIColor.black
                let OK = UIAlertAction(title:"OK", style: .cancel)
                alert.addAction(OK)
                self.present(alert, animated: true, completion: nil)
                return false
            }
        }
        return true
    }
    
    // MARK: - Sort functions
    @IBAction func showSortActionSheet(_ sender: AnyObject) {

        let sortActionSheet = UIAlertController(title: "Sort The Result", message: nil, preferredStyle: .actionSheet)
        let cancle = UIAlertAction(title: "Cancle", style: .cancel)
        
        let sortByAToZ = UIAlertAction(title: "Sort by name: a-z", style: .default) { (UIAlertAction) -> Void in
                self.points = self.points.sorted { (point1, point2) -> Bool in
                    if let name1 = point1["name"] as? String, let name2 = point2["name"] as? String {
                        if name2.lowercased() > name1.lowercased() {
                            return true
                        }
                    }
                    return false
                }
                self.tableView.reloadData()
        }

        let sortByZToA = UIAlertAction(title: "Sort by name: z-a", style: .default) { (UIAlertAction) -> Void in
            self.points = self.points.sorted { (point1, point2) -> Bool in
                if let name1 = point1["name"] as? String, let name2 = point2["name"] as? String {
                    if name1.lowercased() > name2.lowercased() {
                        return true
                    }
                }
                return false
            }
            self.tableView.reloadData()
        }
        
        let sortByDistancePlus = UIAlertAction(title: "Sort by distance: plus", style: .default) { (UIAlertAction) -> Void in
            self.points = self.points.sorted { (point1, point2) -> Bool in
                if let location1 = point1["location"] as? JSONParameters, let location2 = point2["location"] as? JSONParameters {
                    if let distance1 = location1["distance"] as? CLLocationDistance, let distance2 = location2["distance"] as? CLLocationDistance {
                            if distance1 < distance2 {
                                return true
                            }
                        }
                    }
                return false
                }

            self.tableView.reloadData()
        }
        let sortByDistanceMinus = UIAlertAction(title: "Sort by distance: minus", style: .default) { (UIAlertAction) -> Void in
            self.points = self.points.sorted { (point1, point2) -> Bool in
                if let location1 = point1["location"] as? JSONParameters, let location2 = point2["location"] as? JSONParameters {
                    if let distance1 = location1["distance"] as? CLLocationDistance, let distance2 = location2["distance"] as? CLLocationDistance {
                        if distance1 > distance2 {
                            return true
                        }
                    }
                }
                return false
            }
            
            self.tableView.reloadData()
        }
        
        sortActionSheet.addAction(cancle)
        sortActionSheet.addAction(sortByAToZ)
        sortActionSheet.addAction(sortByZToA)
        sortActionSheet.addAction(sortByDistancePlus)
        sortActionSheet.addAction(sortByDistanceMinus)
        sortActionSheet.view.tintColor = UIColor.black
        self.present(sortActionSheet, animated: true, completion: nil)
    }

    // MARK: - Best plan function
    @IBOutlet weak var goButton: UIBarButtonItem!
    
    @IBAction func bestPlan(_ sender: UIBarButtonItem) {
        self.isEditing = !self.isEditing
        if self.isEditing {
            self.goButton.isEnabled = true
        } else {
            self.goButton.isEnabled = false
        }
    }

    

}

extension CLLocation {
    func parameters() -> Parameters {
        let ll      = "\(self.coordinate.latitude),\(self.coordinate.longitude)"
        let llAcc   = "\(self.horizontalAccuracy)"
        let alt     = "\(self.altitude)"
        let altAcc  = "\(self.verticalAccuracy)"
        let parameters = [
            Parameter.ll:ll,
            Parameter.llAcc:llAcc,
            Parameter.alt:alt,
            Parameter.altAcc:altAcc
        ]
        return parameters
    }
}
