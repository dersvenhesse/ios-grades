//
//  AppDelegate.swift
//  grades
//
//  Created by Sven Hesse on 23.06.15.
//  Copyright (c) 2015 Sven Hesse. All rights reserved.
//

import Foundation
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        // status bar
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
        
        // notifications and background fetch
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        
        // background refresh
        UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        return true
    }
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
            
        let rm = RequestManager.sharedInstance
        rm.delegate = nil
        
        // get grades
        if (rm.getRefreshing() == false) {
            rm.fetchGrades() { (error, gradelist, count) in
                
                if (error.type == .None) {
                    grades = gradelist
                    
                    // notify when new entry is found
                    if (amount > 0 && count != 0 && count > amount) {
                        Functions.notification("Neue Eintragung im QIS")
                    }
                    amount = count
                    
                    completionHandler(.NewData)
                }
                else {
                    completionHandler(.NoData)
                }
            }
        }
        else {
            completionHandler(.NoData)
        }

    }
    
    func applicationWillResignActive(application: UIApplication) {
        //
    }

    func applicationDidEnterBackground(application: UIApplication) {
        //
    }

    func applicationWillEnterForeground(application: UIApplication) {
        //
    }

    func applicationDidBecomeActive(application: UIApplication) {
        //
    }

    func applicationWillTerminate(application: UIApplication) {
        //
    }


}

