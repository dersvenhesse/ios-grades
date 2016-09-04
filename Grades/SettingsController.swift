//
//  SettingsController.swift
//  grades
//
//  Created by Sven Hesse on 23.06.15.
//  Copyright (c) 2015 Sven Hesse. All rights reserved.
//

import Foundation
import UIKit

var username = ""
var password = ""

var school = School()

/*
 * Controller for settings and setup page.
 */
class SettingsController: UITableViewController {
    
    // variables
    
    internal var initialSetup = false
    
    // outlets
    
    @IBOutlet var table: UITableView!
    
    @IBOutlet weak var schoolLabel: UILabel!

    @IBOutlet weak var usernameInput: UITextField!
    @IBOutlet weak var passwordInput: UITextField!

    @IBOutlet weak var detailSwitchCell: UITableViewCell!
    @IBOutlet weak var detailSwitch: UISwitch!

    @IBOutlet weak var simpleAverageSwitch: UISwitch!
    
    // actions
    
    @IBAction func loginClicked(sender: AnyObject) {
        navigationController?.popToRootViewControllerAnimated(true)
    }
    
    @IBAction func usernameChanged(sender: AnyObject) {
        setValues(usernameInput, key: "username", global: &username)
    }
    
    @IBAction func passwordChanged(sender: AnyObject) {
        setValues(passwordInput, key: "password", global: &password)
    }
    
    @IBAction func detailSwitchChanged(sender: AnyObject) {
        RequestManager.sharedInstance.timestamp = nil

        settings[Setting.includeDetails.rawValue] = sender.on
        NSUserDefaults.standardUserDefaults().setObject(settings, forKey: "settings")
    }
    
    @IBAction func simpleAverageSwitchChanged(sender: AnyObject) {
        RequestManager.sharedInstance.timestamp = nil

        settings[Setting.simpleAverageSwitch.rawValue] = sender.on
        NSUserDefaults.standardUserDefaults().setObject(settings, forKey: "settings")
    }
    
    // view functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (initialSetup) {
            username = ""
            password = ""
            
            self.title = "Grades-Setup"
            self.navigationItem.setHidesBackButton(true, animated: false)
            self.navigationItem.leftBarButtonItem = nil
            self.navigationItem.rightBarButtonItem = nil
        }
        
        usernameInput.delegate = self
        passwordInput.delegate = self
        
        let uitgr = UITapGestureRecognizer(target: self, action: #selector(SettingsController.dismissKeyboard))
        uitgr.cancelsTouchesInView = false
        view.addGestureRecognizer(uitgr)
    }
    
    override func viewWillAppear(animated: Bool) {
        table.reloadData()
        
        if (school.name == "") {
            schoolLabel.text = "Bitte wählen"
        }
        else {
            schoolLabel.text = school.name
        }
                
        usernameInput.text = "\(username)"
        passwordInput.text = "\(password)"
        
        detailSwitchCell.hidden = !settings[Setting.showDetailSwitch.rawValue]!
        detailSwitch.on = settings[Setting.includeDetails.rawValue]!
        
        simpleAverageSwitch.on = settings[Setting.simpleAverageSwitch.rawValue]!
        
        if ((table.indexPathForSelectedRow) != nil) {
            table.deselectRowAtIndexPath(table.indexPathForSelectedRow!, animated: false)
        }        
    }
    
    // helper
 
    private func setValues(input: UITextField, key: String, inout global: String) {
        
        // reset grades
        grades = []
        amount = -1
        RequestManager.sharedInstance.timestamp = nil
        
        if (key != "") {
            global = input.text!
            
            if (key == "password") {
                try! keychain.set(global, key: "password")
            }
            else if (key == "username") {
                let defaults = NSUserDefaults.standardUserDefaults()
                defaults.setValue(global, forKey: key)
            }
        }
        else {
            input.text = "\(global)"
        }
    }
}

// MARK - table

extension SettingsController {
    
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String {
        
        var title = ""
        switch(section) {
        case 0:
            title = "Universtität oder Hochschule"
            break
        case 1:
            title = "QIS-Zugangsdaten"
            break
        case 2:
            title = initialSetup ? "" : "Sonstiges"
            break
        default:
            break
        }
        
        return title
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var rows = 0
        switch(section) {
        case 0:
            rows = 1
            break
        case 1:
            rows = 2
            break
        case 2:
            rows = initialSetup ? 0 : settings[Setting.showDetailSwitch.rawValue]! ? 2 : 1
            break
        case 3:
            rows = initialSetup ? 1 : 0
        default:
            break
        }
        
        return rows
    }
}

// MARK - textfield

extension SettingsController: UITextFieldDelegate {
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
