//
//  DisclosureController.swift
//  grades
//
//  Created by Sven Hesse on 25.02.16.
//  Copyright © 2016 Sven Hesse. All rights reserved.
//

import UIKit

/*
 * Controller for disclore view (faq, imprint,...).
 */
class DisclosureController: UIViewController {
    
    // outlets
    
    @IBOutlet var webview: UIWebView!
    
    // view functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webview.delegate = self
        
        var html = ""
        
        // load from local file
        let file = NSBundle.mainBundle().pathForResource("disclosure", ofType: "html")
        
        if (file != nil) {
            do {
                html = try String(contentsOfFile: file!, encoding: NSUTF8StringEncoding)
            }
            catch { }
        }
        
        if (html != "") {
            
            // replace some informations
            html = html.stringByReplacingOccurrencesOfString("<%contact%>", withString: PrivateConfiguration.disclosureContact)
            html = html.stringByReplacingOccurrencesOfString("<%imprint%>", withString: PrivateConfiguration.disclosureImprint)
            html = html.stringByReplacingOccurrencesOfString("<%author%>", withString: PrivateConfiguration.disclosureAuthor)
            
            // show
            webview.loadHTMLString(html, baseURL: nil)
        }
    }
    
}

// MARK - webview

extension DisclosureController: UIWebViewDelegate {
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        switch navigationType {
        case .LinkClicked:
            // open links in browser
            UIApplication.sharedApplication().openURL(request.URL!)
            return false
        default:
            return true
        }
    }
}
