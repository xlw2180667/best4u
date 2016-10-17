//
//  AppDelegate.swift
//  best4U
//
//  Created by Xie Liwei on 2016/10/4.
//  Copyright © 2016年 Xie Liwei. All rights reserved.
//

import UIKit
import QuadratTouch

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        self.window?.tintColor = UIColor.white
        
        let client = Client(clientID: "KPMZM1ABGUNMAEDGNDEPQST0LEBM3B12BX5K4QMHJ5QHVXQY",
                            clientSecret: "TA4ZRPFQXHIOOJ2UAMQNGAAFSTVHYIW5UNAPHYYU0IOSU11P",
                            redirectURL: "best4U://foursquare")
        var configuration = Configuration(client:client)
        configuration.mode = nil
        configuration.shouldControllNetworkActivityIndicator = true
        Session.setupSharedSessionWithConfiguration(configuration)
        return true
    }



}

