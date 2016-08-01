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

    // outlets
    
    @IBOutlet var table: UITableView!
    
    @IBOutlet weak var schoolLabel: UILabel!

    @IBOutlet weak var usernameInput: UITextField!
    @IBOutlet weak var passwordInput: UITextField!

    @IBOutlet weak var detailSwitchCell: UITableViewCell!
    @IBOutlet weak var detailSwitch: UISwitch!

    @IBOutlet weak var loginCell: UITableViewCell!
    @IBOutlet weak var loginButton: UIButton!
    
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
        settings[Setting.includeDetails.rawValue]  = sender.on
        NSUserDefaults.standardUserDefaults().setObject(settings, forKey: "settings")
        
        RequestManager.sharedInstance.timestamp = nil
    }
    
    // variables
    
    var initialSetup = false
    
    // view functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (initialSetup) {
            username = ""
            password = ""
            
            loginCell.hidden = false
            detailSwitchCell.hidden = true
            
            self.title = "Grades-Setup"
            self.navigationItem.setHidesBackButton(true, animated: false)
            self.navigationItem.leftBarButtonItem = nil
            self.navigationItem.rightBarButtonItem = nil
        }
        else {
            loginCell.hidden = true
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
        
        if ((table.indexPathForSelectedRow) != nil) {
            table.deselectRowAtIndexPath(table.indexPathForSelectedRow!, animated: false)
        }
    }
    
    // helper
 
    private func setValues(input: UITextField, key: String, inout global: String) {
        
        // reset grades
        grades = []
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
            title = settings[Setting.showDetailSwitch.rawValue]! ? "Weiteres" : ""
            break
        default:
            break
        }
        
        return title
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
