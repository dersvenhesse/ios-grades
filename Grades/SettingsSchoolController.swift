//
//  SettingsSchoolController.swift
//  grades
//
//  Created by Sven Hesse on 26.06.15.
//  Copyright (c) 2015 Sven Hesse. All rights reserved.
//

import Foundation
import UIKit

/*
 * Controller for school selection.
 */
class SettingsSchoolController: UIViewController {
    
    // variables
    
    fileprivate var alphabet = [String]()
    fileprivate var orderedSchools: [[School]] = [[School]]()
    
    // outlets
    
    @IBOutlet weak var table: UITableView!

    // view functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // order schools per first character
        setSchoolsForTable()
        
        self.table.delegate = self
        self.table.dataSource = self
    }
    
    // helper
    
    fileprivate func setSchoolsForTable() {
        var previousOrder: Character = "-"
        
        // create alphabet from schools as sections
        for s in schools {
            if (s.order != previousOrder) {
                orderedSchools.append([s])
                alphabet.append("\(s.order)")
            }
            else {
                orderedSchools[orderedSchools.count-1].append(s)
            }
            previousOrder = s.order
        }
    }
}

// MARK - table

extension SettingsSchoolController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView : UITableView, titleForHeaderInSection section: Int) -> String? {
        return alphabet[section]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return orderedSchools.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orderedSchools[section].count
    }
    
    /*
     func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
     return alphabet
     }
     
     func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
     return index
     }
     */
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let identifier = "schoolCell"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        
        cell.textLabel!.textColor = UIColor.black
        cell.textLabel!.text = "\(orderedSchools[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row].name)"
        
        // show checkmark if school is selected school
        if (orderedSchools[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row].name == school.name) {
            cell.accessoryType = .checkmark
        }
        else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // reset values when changing school
        if (orderedSchools[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row].name != school.name) {
            grades = []
            username = ""
            password = ""
            
            UserDefaults.standard.setValue(username, forKey: "username")
            try! keychain.set(password, key: "password")
        }
        
        school = orderedSchools[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
        UserDefaults.standard.setValue(school.key, forKey: "key")
        
        // reset switch settings as well
        settings[Setting.includeDetails.rawValue] = false
        settings[Setting.showDetailSwitch.rawValue] = false
        UserDefaults.standard.set(settings, forKey: "settings")
        
        UserDefaults.standard.synchronize()
        
        navigationController!.popViewController(animated: true)
    }
}
