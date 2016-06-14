//
//  Configuration.swift
//  grades
//
//  Created by Sven Hesse on 10.04.16.
//  Copyright © 2016 Sven Hesse. All rights reserved.
//

import KeychainAccess

// holds current app version
let version = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as! String

// holds access to keychain to save the password
let keychain = Keychain(service: PrivateConfiguration.keychainService)

// if set, allows testing with local html files
let testing = false

// enum to match raw values to strings
enum Setting: String {
    case includeDetails = "includeDetails"
    case showDetailSwitch = "showDetailSwitch"
}

// settings array using raw values
var settings: [String: Bool] = [
    
    // if set, details will be loaded as well
    Setting.includeDetails.rawValue: false,
    
    // if set, a switch will be shown on the settings page
    Setting.showDetailSwitch.rawValue: false,
]