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
    
    // outlets
    
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    // variables
    
    var alertController: UIAlertController?
    let refreshControl = UIRefreshControl()
    
    var statusLabelAnimated: Bool = false
    
    // view functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSUserDefaults.standardUserDefaults().setValue(version, forKey: "version")

        settingsButton.title = "⚙\u{0000FE0E}"

        self.table.delegate = self
        self.table.dataSource = self
        
        refreshControl.addTarget(self, action: #selector(GradesController.refresh(_:)), forControlEvents: .ValueChanged)
        table.addSubview(refreshControl)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GradesController.applicationWillEnterForeground), name:
            UIApplicationWillEnterForegroundNotification, object: nil)

    }
    
    override func viewDidAppear(animated: Bool) {
        updateView()
    }
    
    override func viewWillAppear(animated: Bool) {
        if ((table.indexPathForSelectedRow) != nil) {
            table.deselectRowAtIndexPath(table.indexPathForSelectedRow!, animated: false)
        }
    }
    
    func applicationWillEnterForeground() {
        updateView()
    }
    
    // helper
    
    private func updateView() {
        
        // dismiss old alerts
        if (alertController != nil) {
            alertController!.dismissViewControllerAnimated(false, completion: nil)
        }
        
        if (grades.count == 0) {
            table.reloadData()
        }
        
        // get settings
        readSettings()
        
        if (username == "" && (school.name == "" || school.url == "")) {
            self.table.reloadData()
            performSegueWithIdentifier("showSetup", sender: nil)
        }
        else {
            
            // get gradelist an show them or error popup
            let rm = RequestManager.sharedInstance
            rm.delegate = self
            
            if (rm.getRefreshing() == false && ((rm.timestamp == nil || NSDate().timeIntervalSinceDate(rm.timestamp!) > 60) || lastErrorType != .none)) {
                
                beginRefresh()
                
                rm.fetchGrades() { (error, gradelist, count) in
                    
                    self.refreshControl.attributedTitle = NSAttributedString(string: "Zuletzt aktualisiert am \(Functions.formatTimestamp(rm.timestamp!))")
                    
                    lastErrorType = error.type
                    
                    if (error.type == .none) {
                        grades = gradelist
                        amount = count
                        
                        self.table.reloadData()
                        self.updateStatusLabelText()
                    }
                    else {
                        
                        // alert only when view is visible
                        if (self.isViewLoaded() && self.view.window != nil) {
                            
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
                                self.updateStatusLabelText("\(title) am \(Functions.formatTimestamp(rm.timestamp!))")
                            }
                            
                            // prepare and show alert
                            self.alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
                            
                            self.alertController!.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                            
                            if (self.presentedViewController == nil) {
                                self.presentViewController(self.alertController!, animated: true, completion: nil)
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
    
    private func readSettings() {
        
        let defaults = NSUserDefaults.standardUserDefaults()
        
        // school-key
        if (defaults.valueForKey("key") != nil) {
            for s in schools {
                if s.key == defaults.stringForKey("key")! {
                    school = s
                }
            }
        }
        
        // username
        if (defaults.valueForKey("username") != nil) {
            username = defaults.stringForKey("username")!
        }
        
        // password
        if (keychain["password"] != nil) {
            try! password = keychain.getString("password")!
        }
        
        // settings
        if (defaults.valueForKey("settings") != nil) {
            settings = defaults.objectForKey("settings")! as! [String: Bool]
        }
        
        // grades amount
        if (defaults.valueForKey("amount") != nil) {
            amount = defaults.integerForKey("amount")
        }
    }
}

// MARK - detail

extension GradesController: GradeDetailDelegate {
    func attachDetail(error: DetailRequestError, grade: Grade, detail: GradeDetail?) {
        if (error.type == .none && detail != nil) {
            outer: for (termIndex, _) in grades.enumerate() {
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
            self.updateStatusLabelText("Fehlercode: \(error.code)", animated: true)
        }
    }
}

// MARK - table

extension GradesController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return grades.count
    }
    
    func tableView(tableView : UITableView, titleForHeaderInSection section: Int) -> String? {
        
        var key = grades[section].0
        
        // update strings for view
        key = key.stringByReplacingOccurrencesOfString("SoSe", withString: "Sommersemester")
        key = key.stringByReplacingOccurrencesOfString("WiSe", withString: "Wintersemester")
        
        if (key == "") {
            key = "Verschiedene Semester"
        }
        
        let cps = calculateCreditpoints(section)
        if (cps > 0) {
            key += " – \(formatCreditpoints(cps)) CP"
        }
        
        let averageGrade = calculateAverageGrade(section)
        if (!averageGrade.isNaN && !averageGrade.isInfinite && averageGrade != 0) {
            key += " – ⌀ \(self.formatGrade(averageGrade, precision: 2))"
        }
        
        return key
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return grades[section].1.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let entry = grades[indexPath.section].1[indexPath.row]
        
        // update strings for view
        let lecture = entry.lecture
        let cp = entry.cp
        let state = entry.state
        let grade = entry.grade
        
        var gradeString = grade == 0 ? state : formatGrade(grade)
        if (gradeString == "bestanden" || gradeString == "BE") {
            gradeString = "✓"
        }
        else if (gradeString == "nicht bestanden" || gradeString == "NB") {
            gradeString = "✗"
        }
        
        // create cell
        let identifier = "gradeCell"
        
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as! GradeTableViewCell
        
        if (settings[Setting.includeDetails.rawValue]!) {
            if (entry.details != nil) {
                cell.accessoryView = nil
                cell.accessoryType = .DisclosureIndicator
            }
            else {
                cell.accessoryView = UIView()
                cell.accessoryView!.frame = CGRectMake(0.0, 0.0, 18.0, 0.0)
            }
        }
        else {
            cell.accessoryView = UIView()
            cell.accessoryView!.frame = CGRectMake(0.0, 0.0, 0.0, 0.0)
        }
        
        cell.lectureLabel.text = "\(lecture)"
        cell.cpLabel.text = cp > 0 ? "\(formatCreditpoints(cp)) CP" : "\(state)"
        cell.gradeLabel.text = "\(gradeString)"
        
        return cell
    }
}

// MARK - refresh control

extension GradesController {
    
    func refresh(refreshControl: UIRefreshControl) {
        updateView()
    }
    
    private func beginRefresh() {
        
        let rm = RequestManager.sharedInstance
        if (rm.timestamp != nil) {
            refreshControl.attributedTitle = NSAttributedString(string: "Zuletzt aktualisiert am \(Functions.formatTimestamp(rm.timestamp!))")
        }
        
        refreshControl.beginRefreshing()
        refreshControl.enabled = false
        
        table.scrollRectToVisible(CGRectMake(0, 0, 1, 1), animated: true)
        statusLabel.text = "Aktualisiert gerade"
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    private func endRefresh() {
        refreshControl.endRefreshing()
        refreshControl.enabled = true
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
}

// MARK - segues

extension GradesController {
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showSetup") {
            let vc = segue.destinationViewController as! SettingsController
            vc.initialSetup = true
        }
        else if (segue.identifier == "showDetail") {
            let vc = segue.destinationViewController as! GradesDetailController
            
            let indexPath = table.indexPathForSelectedRow
            vc.grade = grades[indexPath!.section].1[indexPath!.row]
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if (identifier == "showDetail") {
            let indexPath = table.indexPathForSelectedRow
            
            if (grades[indexPath!.section].1[indexPath!.row].details != nil) {
                return true
            }
            else {
                table.deselectRowAtIndexPath(table.indexPathForSelectedRow!, animated: false)
                return false
            }
        }
        return true
    }
}

// MARK - calculates and formats

extension GradesController {
    
    private func updateStatusLabelText(text: String = "", animated: Bool = false) {
        var labelText = ""
        
        if (amount != -1) {
            labelText += "\(grades.count) Semester"
            labelText += " – \(amount) Einträge"
            
            let totalCps = self.calculateTotalCreditpoints()
            if (totalCps > 0) {
                labelText += " – \(self.formatCreditpoints(totalCps)) CP"
            }
            
            let totalAverageGrade = self.calculateTotalAverageGrade()
            if (!totalAverageGrade.isNaN && !totalAverageGrade.isInfinite && totalAverageGrade != 0) {
                labelText += " – ⌀ \(self.formatGrade(totalAverageGrade, precision: 2))"
            }
        }
        
        if (animated && text != "") {
            if (!statusLabelAnimated) {
                UIView.animateWithDuration(4.0, animations: {
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
    
    private func calculateTotalCreditpoints() -> Double {
        var totalCps: Double = 0.0
        
        for (termIndex, _) in grades.enumerate() {
            for entry in grades[termIndex].1 {
                totalCps += entry.cp
            }
        }
        
        return totalCps
    }
    
    private func calculateCreditpoints(termIndex: Int) -> Double {
        var cps: Double = 0.0
        
        for entry in grades[termIndex].1 {
            cps += entry.cp
        }
        
        return cps
    }
    
    private func calculateTotalAverageGrade() -> Double {
        let totalCps = calculateTotalCreditpoints()
        
        var count: Int = 0
        var weighted: Double = 0.0
        
        for (termIndex, _) in grades.enumerate() {
            for entry in grades[termIndex].1 {
                if (entry.grade != 0) {
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
    
    private func calculateAverageGrade(termIndex: Int) -> Double {
        let cps = calculateCreditpoints(termIndex)
        
        var count: Int = 0
        var weighted: Double = 0.0
        
        for entry in grades[termIndex].1 {
            if (entry.grade != 0) {
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
    
    private func formatGrade(grade: Double, precision: Int = 1) -> String {
        let format = "%.\(precision)f"
        
        return "\(String(format: format, grade))".stringByReplacingOccurrencesOfString(".", withString: ",")
    }
    
    private func formatCreditpoints(cps: Double) -> String {
        var s: String
        
        if (cps % 1 == 0) {
            s = "\(Int(cps))"
        }
        else {
            s = "\(cps)".stringByReplacingOccurrencesOfString(".", withString: ",")
        }
        
        return s
    }
}

