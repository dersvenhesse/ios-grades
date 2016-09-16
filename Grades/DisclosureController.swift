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
        let file = Bundle.main.path(forResource: "disclosure", ofType: "html")
        
        if (file != nil) {
            do {
                html = try String(contentsOfFile: file!, encoding: String.Encoding.utf8)
            }
            catch { }
        }
        
        if (html != "") {
            
            // replace some informations
            html = html.replacingOccurrences(of: "<%contact%>", with: PrivateConfiguration.disclosureContact)
            html = html.replacingOccurrences(of: "<%imprint%>", with: PrivateConfiguration.disclosureImprint)
            html = html.replacingOccurrences(of: "<%author%>", with: PrivateConfiguration.disclosureAuthor)
            
            // show
            webview.loadHTMLString(html, baseURL: nil)
        }
    }
    
}

// MARK - webview

extension DisclosureController: UIWebViewDelegate {
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        switch navigationType {
        case .linkClicked:
            // open links in browser
            UIApplication.shared.openURL(request.url!)
            return false
        default:
            return true
        }
    }
}
