//
//  ViewController.swift
//  grades
//
//  Created by Sven Hesse on 23.06.15.
//  Copyright (c) 2015 Sven Hesse. All rights reserved.
//

import Foundation
import UIKit
import KeychainAccess

var grades = [(String, [Grade])]()
var amount = -1

var lastErrorType = RequestErrorType.none

/*
 * Controller for grade list.
 */
class GradesController: UIViewController {
    
    // variables
    
    fileprivate var alertController: UIAlertController?
    fileprivate let refreshControl = UIRefreshControl()
    
    fileprivate var statusLabelAnimated: Bool = false
    
    // outlets
    
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    // view functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserDefaults.standard.setValue(version, forKey: "version")

        settingsButton.title = "⚙\u{0000FE0E}"

        self.table.delegate = self
        self.table.dataSource = self
        
        refreshControl.addTarget(self, action: #selector(GradesController.refresh(_:)), for: .valueChanged)
        table.addSubview(refreshControl)
        
        NotificationCenter.default.addObserver(self, selector: #selector(GradesController.applicationWillEnterForeground), name:
            NSNotification.Name.UIApplicationWillEnterForeground, object: nil)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if ((table.indexPathForSelectedRow) != nil) {
            table.deselectRow(at: table.indexPathForSelectedRow!, animated: false)
        }
    }
    
    func applicationWillEnterForeground() {
        updateView()
    }
    
    // helper
    
    fileprivate func updateView() {
        
        // dismiss old alerts
        if (alertController != nil) {
            alertController!.dismiss(animated: false, completion: nil)
        }
        
        if (grades.count == 0) {
            table.reloadData()
        }
        
        // get settings
        readSettings()
        
        if (username == "" && (school.name == "" || school.url == "")) {
            self.table.reloadData()
            performSegue(withIdentifier: "showSetup", sender: nil)
        }
        else {
            
            // get gradelist an show them or error popup
            let rm = RequestManager.sharedInstance
            rm.delegate = self
            
            if (rm.getRefreshing() == false && ((rm.timestamp == nil || Date().timeIntervalSince(rm.timestamp! as Date) > 60) || lastErrorType != .none)) {
                
                beginRefresh()
                
                rm.fetchGrades() { (error, gradelist, count) in
                    
                    self.refreshControl.attributedTitle = NSAttributedString(string: "Zuletzt aktualisiert am \(Functions.formatTimestamp(timestamp: rm.timestamp!))")
                    
                    lastErrorType = error.type
                    
                    if (error.type == .none) {
                        grades = gradelist
                        amount = count
                        
                        self.table.reloadData()
                        self.updateStatusLabel()
                    }
                    else {
                        
                        // alert only when view is visible
                        if (self.isViewLoaded && self.view.window != nil) {
                            
                            var title = ""
                            var message = ""
                            
                            switch error.type {
                            case .settingsError:
                                title = "Fehlende Angaben"
                                message = "Bitte Einstellungen prüfen."
                            case .qisError:
                                title = "QIS nicht erreichbar"
                                message = "Bitte Internetverbindung und/oder QIS prüfen."
                            case .loginError:
                                title = "Login nicht möglich"
                                message = "Bitte Zugangsdaten prüfen."
                            case .asiError:
                                title = "Prüfungsverwaltung nicht aufrufbar"
                                message = "Bitte nochmals aktualisieren."
                            case .degreeError:
                                title = "Abschluss nicht gefunden"
                                message = "Bitte das Vorhandensein einer Abschluss-Auswahl prüfen."
                            case .listError:
                                title = "Leere Notenliste"
                                message = "Bitte das Vorhandensein von Noten prüfen."
                            default:
                                title = "Zeitüberschreitung"
                                message = "Bitte nochmals aktualisieren."
                            }
                            
                            if (error.code != 0) {
                                message = "\(message)\n\nFehlercode: \(error.code)"
                            }
                            
                            // update table
                            self.table.reloadData()
                            if (rm.timestamp != nil) {
                                self.updateStatusLabel(text: "\(title) am \(Functions.formatTimestamp(timestamp: rm.timestamp!))")
                            }
                            
                            // prepare and show alert
                            self.alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                            
                            self.alertController!.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                            
                            if (self.presentedViewController == nil) {
                                self.present(self.alertController!, animated: true, completion: nil)
                            }
                        }
                        
                    }
                    self.endRefresh()
                }
            }
            else {
                self.endRefresh()
            }
        }
    }
    
    fileprivate func readSettings() {
        
        let defaults = UserDefaults.standard
        
        // school-key
        if (defaults.value(forKey: "key") != nil) {
            for s in schools {
                if s.key == defaults.string(forKey: "key")! {
                    school = s
                }
            }
        }
        
        // username
        if (defaults.value(forKey: "username") != nil) {
            username = defaults.string(forKey: "username")!
        }
        
        // password
        if (keychain["password"] != nil) {
            try! password = keychain.getString("password")!
        }
        
        // settings
        if (defaults.value(forKey: "settings") != nil) {
            settings.merge(dict: defaults.object(forKey: "settings")! as! [String: Bool])
        }
        
        // grades amount
        if (defaults.value(forKey: "amount") != nil) {
            amount = defaults.integer(forKey: "amount")
        }
    }
}

// MARK - detail

extension GradesController: GradeDetailDelegate {
    func attachDetail(error: DetailRequestError, grade: Grade, detail: GradeDetail?) {
        if (error.type == .none && detail != nil) {
            outer: for (termIndex, _) in grades.enumerated() {
                for entry in grades[termIndex].1 {
                    if (entry.equals(grade)) {
                        entry.details = detail!
                        break outer
                    }
                }
            }
            table.reloadData()
        }
        else {
            self.updateStatusLabel(text: "Fehlercode: \(error.code)", animated: true)
        }
    }
}

// MARK - table

extension GradesController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return grades.count
    }
    
    func tableView(_ tableView : UITableView, titleForHeaderInSection section: Int) -> String? {
        
        var key = grades[section].0
        
        // update strings for view
        key = key.replacingOccurrences(of: "SoSe", with: "Sommersemester")
        key = key.replacingOccurrences(of: "WiSe", with: "Wintersemester")
        
        if (key == "") {
            key = "Verschiedene Semester"
        }
        
        let cps = calculateCreditpoints(for: section)
        if (cps > 0) {
            key += " – \(format(cps: cps)) CP"
        }
        
        let averageGrade = calculateAverageGrade(for: section)
        if (!averageGrade.isNaN && !averageGrade.isInfinite && averageGrade != 0) {
            key += " – ⌀ \(self.format(grade: averageGrade, to: 2))"
        }
        
        return key
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return grades[section].1.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let entry = grades[(indexPath as NSIndexPath).section].1[(indexPath as NSIndexPath).row]
        
        // update strings for view
        let lecture = entry.lecture
        let cp = entry.cp
        let state = entry.state
        let grade = entry.grade
        
        var gradeString = (grade == 0 || grade == 5) ? state : format(grade: grade)
        if (gradeString == "bestanden" || gradeString == "BE") {
            gradeString = "✓"
        }
        else if (gradeString == "nicht bestanden" || gradeString == "NB") {
            gradeString = "✗"
        }
        
        // create cell
        let identifier = "gradeCell"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! GradeTableViewCell
        
        if (settings[Setting.includeDetails.rawValue]!) {
            if (entry.details != nil) {
                cell.accessoryView = nil
                cell.accessoryType = .disclosureIndicator
            }
            else {
                cell.accessoryView = UIView()
                cell.accessoryView!.frame = CGRect(x: 0.0, y: 0.0, width: 18.0, height: 0.0)
            }
        }
        else {
            cell.accessoryView = UIView()
            cell.accessoryView!.frame = CGRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0)
        }
        
        cell.lectureLabel.text = "\(lecture)"
        cell.cpLabel.text = cp > 0 ? "\(format(cps: cp)) CP" : "\(state)"
        cell.gradeLabel.text = "\(gradeString)"
        
        return cell
    }
}

// MARK - refresh control

extension GradesController {
    
    func refresh(_ refreshControl: UIRefreshControl) {
        updateView()
    }
    
    fileprivate func beginRefresh() {
        
        let rm = RequestManager.sharedInstance
        if (rm.timestamp != nil) {
            refreshControl.attributedTitle = NSAttributedString(string: "Zuletzt aktualisiert am \(Functions.formatTimestamp(timestamp: rm.timestamp!))")
        }
        
        refreshControl.beginRefreshing()
        refreshControl.isEnabled = false
        
        table.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true)
        statusLabel.text = "Aktualisiert gerade"
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    fileprivate func endRefresh() {
        refreshControl.endRefreshing()
        refreshControl.isEnabled = true
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

// MARK - segues

extension GradesController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showSetup") {
            let vc = segue.destination as! SettingsController
            vc.initialSetup = true
        }
        else if (segue.identifier == "showDetail") {
            let cell = sender as! UITableViewCell
            let indexPath = table.indexPath(for: cell)!
            
            let vc = segue.destination as! GradesDetailController
            
            vc.grade = grades[indexPath.section].1[indexPath.row]
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if (identifier == "showDetail") {
            let cell = sender as! UITableViewCell
            let indexPath = table.indexPath(for: cell)!
            
            if (grades[indexPath.section].1[indexPath.row].details != nil) {
                return true
            }
            else {
                table.deselectRow(at: indexPath, animated: false)
                return false
            }
        }
        return true
    }
}

// MARK - calculates and formats

extension GradesController {
    
    fileprivate func updateStatusLabel(text: String = "", animated: Bool = false) {
        var labelText = ""
        
        if (amount != -1) {
            labelText += "\(grades.count) Semester"
            labelText += " – \(amount) Einträge"
            
            let totalCps = self.calculateTotalCreditpoints()
            if (totalCps > 0) {
                labelText += " – \(self.format(cps: totalCps)) CP"
            }
            
            let totalAverageGrade = self.calculateTotalAverageGrade()
            if (!totalAverageGrade.isNaN && !totalAverageGrade.isInfinite && totalAverageGrade != 0) {
                labelText += " – ⌀ \(self.format(grade: totalAverageGrade, to: 2))"
            }
        }
        
        if (animated && text != "") {
            if (!statusLabelAnimated) {
                UIView.animate(withDuration: 4.0, animations: {
                    self.statusLabel.text = text
                    self.statusLabel.alpha = 0.0
                    self.statusLabelAnimated = true
                    }, completion: { (finished: Bool) in
                        self.statusLabel.text = labelText
                        self.statusLabel.alpha = 1.0
                        self.statusLabelAnimated = false
                })
            }
        }
        else if (text != "") {
            self.statusLabel.text = text
        }
        else {
            self.statusLabel.text = labelText
        }
    }
    
    fileprivate func calculateTotalCreditpoints(excludeZero: Bool = false) -> Double {
        var totalCps: Double = 0.0
        
        for (termIndex, _) in grades.enumerated() {
            for entry in grades[termIndex].1 {
                if (excludeZero && entry.grade == 0 || entry.grade == 5) {
                    continue
                }
                totalCps += entry.cp
            }
        }
        
        return totalCps
    }
    
    fileprivate func calculateCreditpoints(for termIndex: Int, excludeZero: Bool = false) -> Double {
        var cps: Double = 0.0
        
        for entry in grades[termIndex].1 {
            if (excludeZero && entry.grade == 0 || entry.grade == 5) {
                continue
            }
            cps += entry.cp
        }
        
        return cps
    }
    
    fileprivate func calculateTotalAverageGrade() -> Double {
        var totalCps: Double = 0

        if (settings[Setting.simpleAverageSwitch.rawValue] == false) {
            totalCps = calculateTotalCreditpoints(excludeZero: true)
        }

        var count: Int = 0
        var weighted: Double = 0.0
        
        for (termIndex, _) in grades.enumerated() {
            for entry in grades[termIndex].1 {
                if (entry.grade != 0 && entry.grade != 5) {
                    if (totalCps != 0) {
                        weighted += (entry.cp * entry.grade)
                    }
                    else {
                        count+=1
                        weighted += entry.grade
                    }
                }
            }
        }
        
        return (totalCps != 0) ? weighted/totalCps : weighted/Double(count)
    }
    
    fileprivate func calculateAverageGrade(for termIndex: Int) -> Double {
        var cps: Double = 0
        
        if (settings[Setting.simpleAverageSwitch.rawValue] == false) {
            cps = calculateCreditpoints(for: termIndex, excludeZero: true)
        }
        
        var count: Int = 0
        var weighted: Double = 0.0
        
        for entry in grades[termIndex].1 {
            if (entry.grade != 0 && entry.grade != 5) {
                if (cps != 0) {
                    weighted += (entry.cp * entry.grade)
                }
                else {
                    count+=1
                    weighted += entry.grade
                }
            }
        }
        
        return (cps != 0) ? weighted/cps : weighted/Double(count)
    }
    
    fileprivate func format(grade: Double, to precision: Int = 1) -> String {
        let format = "%.\(precision)f"
        
        return "\(String(format: format, grade))".replacingOccurrences(of: ".", with: ",")
    }
    
    fileprivate func format(cps: Double) -> String {
        var s: String
        
        if (cps.truncatingRemainder(dividingBy: 1) == 0) {
            s = "\(Int(cps))"
        }
        else {
            s = "\(cps)".replacingOccurrences(of: ".", with: ",")
        }
        
        return s
    }
}

