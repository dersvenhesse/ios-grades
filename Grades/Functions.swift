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
        localNotification.fireDate = NSDate(timeIntervalSinceNow: 10)
        
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
    }
    
    /* 
     * Delay a callback.
     */
    static func delay(delay: Double, closure: () -> ()) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), closure)
    }
    
    /* 
     * Match a regex search in a text.
     */
    static func regexSearch(regex: String, text: String) -> [String] {
        
        let regex = try! NSRegularExpression(pattern: regex, options: [])
        
        let string = text as NSString
        let results = regex.matchesInString(text, options: [], range: NSMakeRange(0, string.length))
        
        return results.map {
            string.substringWithRange($0.range)
        }
    }
    
    /* 
     * Strip a html to excerpt its content.
     */
    static func stripHtml(string: String) -> String {
        
        // strip html
        var stripped = string.stringByReplacingOccurrencesOfString("<[^>]+>", withString: "", options: .RegularExpressionSearch, range: nil)
        
        // strip spaces
        stripped = stripped.stringByReplacingOccurrencesOfString("&nbsp;", withString: "")
        
        // strip whitespace
        let components = stripped.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).filter({!$0.characters.isEmpty})
        
        return components.joinWithSeparator(" ")
    }
    
    
    /*
     * Format timestamp to readable (german) format.
     */
    static func formatTimestamp(timestamp: NSDate) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "dd.MM.YY, HH:mm"
        
        return "\(dateFormatter.stringFromDate(timestamp)) Uhr"
    }
}