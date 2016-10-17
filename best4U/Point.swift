//
//  Point.swift
//  best4U
//
//  Created by Xie Liwei on 2016/10/8.
//  Copyright © 2016年 Xie Liwei. All rights reserved.
//

import UIKit
import MapKit
class Point: NSObject , MKAnnotation{
    var title: String?
    var subtitle: String?
    var coordinate: CLLocationCoordinate2D
    var id: String?
    
    init(title:String, subtitle:String, coordinate: CLLocationCoordinate2D,id:String) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.id = id
    }
}
