//
//  Functions.swift
//  grades
//
//  Created by Sven Hesse on 19.01.16.
//  Copyright © 2016 Sven Hesse. All rights reserved.
//

import Foundation
import UIKit

struct Functions {
    
    /*
     * Show local notification.
     */
    static func notification(text: String) {
        let localNotification: UILocalNotification = UILocalNotification()
        
        localNotification.alertAction = nil
        localNotification.alertBody = text
        localNotification.fireDate = Date(timeIntervalSinceNow: 10)
        
        UIApplication.shared.scheduleLocalNotification(localNotification)
    }
    
    /* 
     * Delay a callback.
     */
    static func delay(delay: Double, closure: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
    
    /* 
     * Match a regex search in a text.
     */
    static func regexSearch(regex: String, text: String) -> [String] {
        
        let regex = try! NSRegularExpression(pattern: regex, options: [])
        
        let string = text as NSString
        let results = regex.matches(in: text, options: [], range: NSMakeRange(0, string.length))
        
        return results.map {
            string.substring(with: $0.range)
        }
    }
    
    /* 
     * Strip a html to excerpt its content.
     */
    static func stripHtml(string: String) -> String {
        
        // strip html
        var stripped = string.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
        
        // strip spaces
        stripped = stripped.replacingOccurrences(of: "&nbsp;", with: "")
        
        // strip whitespace
        let components = stripped.components(separatedBy: CharacterSet.whitespacesAndNewlines).filter({!$0.characters.isEmpty})
        
        return components.joined(separator: " ")
    }
    
    
    /*
     * Format timestamp to readable (german) format.
     */
    static func formatTimestamp(timestamp: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.YY, HH:mm"
        
        return "\(dateFormatter.string(from: timestamp)) Uhr"
    }
}
