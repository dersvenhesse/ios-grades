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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // status bar
        UIApplication.shared.statusBarStyle = .lightContent
        
        // notifications and background fetch
        let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        UIApplication.shared.registerUserNotificationSettings(settings)
        
        // background refresh
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        return true
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
            
        let rm = RequestManager.sharedInstance
        rm.delegate = nil
        
        // get grades
        if (rm.getRefreshing() == false) {
            rm.fetchGrades() { (error, gradelist, count) in
                
                if (error.type == .none) {
                    grades = gradelist
                    
                    // notify when new entry is found
                    if (amount > 0 && count != 0 && count > amount) {
                        Functions.notification(text: "Neue Eintragung im QIS")
                    }
                    amount = count
                    
                    completionHandler(.newData)
                }
                else {
                    completionHandler(.noData)
                }
            }
        }
        else {
            completionHandler(.noData)
        }

    }

}

