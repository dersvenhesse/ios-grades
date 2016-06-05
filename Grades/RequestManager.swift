//
//  RequestManager.swift
//  grades
//
//  Created by Sven Hesse on 23.06.15.
//  Copyright (c) 2015 Sven Hesse. All rights reserved.
//

import Foundation
import Alamofire

class RequestManager {
    
    // singleton
    static let sharedInstance = RequestManager()
    
    // delete to attach details afterwards
    var delegate: GradeDetailDelegate?

    // alamofire manager to hold cookies
    var alamofireManager: Alamofire.Manager!
    
    // flag if refresh is currently in progress
    var refreshing = false
    
    // timestamp from last grade request
    var timestamp: NSDate?
    
    // grade texts to be excluded
    let excludetexts = ["Durchschnittsnote Deutschlandstipendium", "ECTS-Kontostand: (fortlaufende Ermittlung)"]

    // attempt amount for specific requests to repeat requests
    var attempts = [RequestAttemptType: [String: Int]]()

    var asi = ""
    var degree = ""

    /*
     * Initialise manager using alamofire.
     */
    private init() {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        config.HTTPCookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        config.timeoutIntervalForRequest = 10
        
        alamofireManager = Alamofire.Manager(configuration: config)
    }
    
    /*
     * Fetches grades and return them via callback (sub-ordered by term and including the amount).
     */
    internal func fetchGrades(callback: (RequestError, [(String, [Grade])], Int) -> Void) {
        self.timestamp = NSDate()
        attempts = [RequestAttemptType: [String: Int]]()
        
        self.navigate() { (error) in
            if (error.type != .None) {
                self.refreshing = false
                return callback(error, [], 0)
            }
            else {
                self.findList() { (error, gradelist) in
                    if (error.type != .None) {
                        self.refreshing = false
                        return callback(error, [], 0)
                    }
                    
                    self.refreshing = false
                    
                    return callback(RequestError(type: .None), self.orderGradelistByTerm(gradelist), gradelist.count)
                }
            }
        }
    }
    
    /*
     * Navigate to qis page, login user and find asi as well as degree.
     */
    private func navigate(callback: (error: RequestError) -> Void) {
        
        self.refreshing = true
        
        if (username == "" || password == "" || school.url == "") {
            return callback(error: RequestError(type: .SettingsError))
        }
        
        // call login page and set cookie (jsessionid)
        self.gotoQis() { (error) in
            if (error.type != .None) {
                return callback(error: error)
            }
            
            // login
            self.login(username, password: password) { (error) in
                if (error.type != .None && !testing) {
                    return callback(error: error)
                }
                
                // navigate to menu and find asi
                self.findAsi() { (error) in
                    if (error.type != .None) {
                        return callback(error: error)
                    }
                    
                    // navigate to find degree
                    self.findDegree() { (error) in
                        if (error.type != .None && !testing) {
                            return callback(error: error)
                        }
                        
                        return callback(error: RequestError(type: .None))
                    }
                }
            }
        }
    }
    
    /*
     * Open qis page.
     */
    private func gotoQis(callback: (error: RequestError) -> Void) {
        self.alamofireManager.request(.GET, "https://" + school.url + school.urlTrail + "user&type=0").responseString { response in
            
            if (!response.result.isSuccess) {
                return callback(error: RequestError(type: .QisError))
            }
            else if (response.response?.statusCode >= 500) {
                return callback(error: RequestError(type: .QisError))
            }
            else {
                return callback(error: RequestError(type: .None))
            }
        }
    }
    
    /*
     * Login user into qis.
     */
    private func login(username: String, password: String, callback: (error: RequestError) -> Void) {
        self.alamofireManager.request(.POST, "https://" + school.url + school.urlTrail + "user&type=1&category=auth.login&startpage=portal.vm&breadCrumbSource=portal", parameters: [school.loginParameters.0: username, school.loginParameters.1: password, "submit": "Anmelden"]).responseString { response in
            
            let value = response.result.value
            
            if (!response.result.isSuccess) {
                return callback(error: RequestError(type: .LoginError, code: 314))
            }
            else if (value == nil) {
                return callback(error: RequestError(type: .LoginError, code: 361))
            }
            else if (value == "") {
                return callback(error: RequestError(type: .LoginError, code: 382))
            }
            else if (value!.rangeOfString("Anmeldung fehlgeschlagen") != nil) {
                return callback(error: RequestError(type: .LoginError, code: 349))
            }
            else {
                return callback(error: RequestError(type: .None))
            }
        }
    }
    
    /*
     * Find and stores current asi after user is logged in to enter asi protected area.
     */
    private func findAsi(callback: (error: RequestError) -> Void) {
        self.alamofireManager.request(.GET, "https://" + school.url + school.urlTrail + "change&type=1&moduleParameter=studyPOSMenu&next=menu.vm&xml=menu").responseString { response in
            
            var value = response.result.value
            
            if (testing) {
                value = self.loadTestingFile()
            }
            
            if (!response.result.isSuccess || value == nil || value == "") {
                return callback(error: RequestError(type: .AsiError, code: 481))
            }
            else {
                var matches = Functions.regexSearch(";asi=.*?[\"|&]", text: value!)
                
                // save first match as asi
                if (matches.count > 0 && matches[0].characters.count == 26) {
                    self.asi = (matches[0] as NSString).substringWithRange(NSMakeRange(5, 20))
                    return callback(error: RequestError(type: .None))
                }
                else {
                    return callback(error: RequestError(type: .AsiError, code: (500 + matches.count)))
                }
            }
        }
    }
    
    /*
     * Find and stores degree.
     */
    private func findDegree(callback: (error: RequestError) -> Void) {
        self.alamofireManager.request(.GET, "https://" + school.url + school.urlTrail + "notenspiegelStudent&next=tree.vm&nextdir=qispos/notenspiegel/student&menuid=notenspiegelStudent&breadcrumb=notenspiegel&breadCrumbSource=menu&asi=" + asi).responseString { response in
            
            let value = response.result.value
                        
            if (!response.result.isSuccess || value == nil || value == "") {
                return callback(error: RequestError(type: .DegreeError, code: 129))
            }
            else if (value!.rangeOfString("viele Klicks Warteseite") != nil) {
                return callback(error: RequestError(type: .DegreeError, code: 141))
            }
            else {
                var matches = Functions.regexSearch("Aabschl\\%3D[\\w]*", text: value!)
                
                if (matches.count > 0) {
                    let range = matches[0].rangeOfString("%3D")
                    let index = matches[0].startIndex.distanceTo(range!.endIndex)
                    
                    // save
                    self.degree = (matches[0] as NSString).substringFromIndex(index)
                    return callback(error: RequestError(type: .None))
                }
                else {
                    // retries when match is found even though it should be found
                    self.increaseAttempts(.DegreeAttempt, identifier: "")
                    if (self.attempts[.DegreeAttempt]![""] < 3) {
                        Functions.delay(2.0) {
                            self.findDegree(callback)
                        }
                    }
                    else {
                        return callback(error: RequestError(type: .DegreeError, code: 183))
                    }
                }
            }
        }
    }
    
    /*
     * Navigate to grade list (using degree and asi) and finally parse all grades.
     */
    private func findList(callback: (error: RequestError, list: [Grade]) -> Void) {
        self.alamofireManager.request(.GET, "https://" + school.url + school.urlTrail + "notenspiegelStudent&next=list.vm&nextdir=qispos/notenspiegel/student&createInfos=Y&struct=auswahlBaum&nodeID=auswahlBaum%7Cabschluss%3Aabschl%3D" + degree + "%2Cstgnr%3D1&expand=0&asi=" + asi).responseString { response in
            
            var value = response.result.value
            
            if (testing) {
                // use local file instead of web
                value = self.loadTestingFile()
            }
            
            if (!response.result.isSuccess || value == nil || value == "") {
                return callback(error: RequestError(type: .ListError, code: 612), list: [])
            }
            else {
                var gradelist: [Grade] = [Grade]()
                
                let matches = Functions.regexSearch("<tr>((?:(?!</tr>)[\\s\\S])*)</tr>", text: value!)
                
                if (matches.count == 0) {
                    return callback(error: RequestError(type: .ListError, code: 631), list: [])
                }
                
                // find table header for specific row and stores their indices
                
                if (school.gradelistIndices.count == 0) {
                    for match in matches {
                        var data = Functions.regexSearch("<th (class=\"tabelleheader\" )?align=\"[\\w]*\" width=\"[\\w%]*\" scope=\"col\"[\\s]?>((?:(?!</th>)[\\s\\S])*)</th>", text: match)
                        
                        if (data.count == 0) {
                            continue
                        }
                        
                        data = data.map {
                            Functions.stripHtml($0)
                        }
                        
                        self.createGradelistIndicesFromData(data)
                    }
                }
                
                if (school.gradelistIndices.count == 0) {
                    return callback(error: RequestError(type: .ListError, code: 676), list: [])
                }
                
                // show switch on settings page when details should be available
                self.configureDetailSwitch(value!)
                
                // count some special cases to prevent errors
                var countClassmatch = 0
                var countContinue = 0
                var countExcluded = 0
                
                // delay for loading details (to prevent "zu viele Klicks Warteseite")
                var delay: Double = 0
                
                for match in matches {
                    if (self.checkForClasses(match)) {
                        
                        var data = Functions.regexSearch("<td (nowrap=\"nowrap\" )?(class=\"[\\w]*\" )?valign=\"(top|center)\"[^>]*>((?:(?!</td>)[\\s\\S])*)</td>", text: match)
                        
                        if (data.count == 0) {
                            countContinue += 1
                            continue
                        }

                        data = data.map {
                            Functions.stripHtml($0)
                        }
                        
                        if !(school.gradelistIndices[.Lecture] == nil || school.gradelistIndices[.State] == nil || self.excludetexts.contains(data[school.gradelistIndices[.Lecture]!]) || data[school.gradelistIndices[.State]!] == "angemeldet" || data[school.gradelistIndices[.State]!] == "AN" || data[school.gradelistIndices[.State]!] == "Prüfung vorhanden") {
                            
                            // create object
                            let grade = Grade(
                                lecture: school.gradelistIndices[.Lecture] != nil ? data[school.gradelistIndices[.Lecture]!] : "",
                                term: school.gradelistIndices[.Term] != nil ? data[school.gradelistIndices[.Term]!] : "",
                                grade: school.gradelistIndices[.Grade] != nil ? ((data[school.gradelistIndices[.Grade]!]).stringByReplacingOccurrencesOfString(",", withString: ".") as NSString).doubleValue : 0.0,
                                cp: school.gradelistIndices[.CP] != nil ? ((data[school.gradelistIndices[.CP]!]).stringByReplacingOccurrencesOfString(",", withString: ".") as NSString).doubleValue : 0.0,
                                state: school.gradelistIndices[.State] != nil ? data[school.gradelistIndices[.State]!] : ""
                            )
                                                                                    
                            let hrefs = Functions.regexSearch("href=\"[^\"]*?asi.*?\"", text: match)

                            // find details link to fetch scores
                            if (hrefs.count > 0 && self.delegate != nil) {
                                if (settings[Setting.IncludeDetails.rawValue] != false) {
                                    var scoreLink = hrefs[0].substringWithRange(hrefs[0].startIndex.advancedBy(6) ..< hrefs[0].endIndex.advancedBy(-1))
                                    scoreLink = scoreLink.stringByReplacingOccurrencesOfString("&amp;", withString: "&")
                                    
                                    delay += 0.2
                                    
                                    // load score with minimal delay
                                    Functions.delay(delay) {
                                        self.loadScorelist(scoreLink, grade: grade)
                                    }
                                }
                            }

                            gradelist.append(grade)
                        }
                        else {
                            countExcluded += 1
                        }
                    }
                    else {
                        countClassmatch += 1
                    }
                }
                
                // check for special error possibilities
                if (countExcluded == matches.count) {
                    return callback(error: RequestError(type: .ListError, code: (700 + countClassmatch)), list: [])
                }
                if (countContinue == matches.count) {
                    return callback(error: RequestError(type: .ListError, code: (800 + countContinue)), list: [])
                }
                if (countExcluded == matches.count) {
                    return callback(error: RequestError(type: .ListError, code: (900 + countExcluded)), list: [])
                }
                
                if (gradelist.count == 0) {
                    return callback(error: RequestError(type: .ListError, code: 619), list: [])
                }
                else {
                    return callback(error: RequestError(type: .None), list: gradelist)
                }
            }
        }
    }
    
    /*
     * Load grade details including the scores.
     */
    private func loadScorelist(scoreLink: String, grade: Grade) {
        self.alamofireManager.request(.GET, scoreLink).responseString { response in
            
            if(response.result.error != nil || response.result.isFailure) {
                self.delegate?.attachDetail(DetailRequestError(type: .Error, code: 1134), grade: grade, detail: nil)
                return
            }
            
            let value = response.result.value
                        
            if (!response.result.isSuccess || value == nil || value == "") {
                self.delegate?.attachDetail(DetailRequestError(type: .Error, code: 1198), grade: grade, detail: nil)
                return
            }
            else if (value!.rangeOfString("de.his.exceptions.AsiException") != nil) {
                self.delegate?.attachDetail(DetailRequestError(type: .Error, code: 1132), grade: grade, detail: nil)
                return
            }
            else if (value!.rangeOfString("viele Klicks Warteseite") != nil) {
                // some retries when qis denies quick navigation
                self.increaseAttempts(.ScoreListAttempt, identifier: grade.lecture)
                if (self.attempts[.ScoreListAttempt]![grade.lecture] < 3) {
                    Functions.delay(2.0) {
                        self.loadScorelist(scoreLink, grade: grade)
                    }
                }
                else {
                    self.delegate?.attachDetail(DetailRequestError(type: .Error, code: 1161), grade: grade, detail: nil)
                }
                return
            }
            else {
                
                let detail = GradeDetail()
                
                if (value!.rangeOfString("zu wenige Leistungen vorliegen") != nil) {
                    detail.scoresStatus = .NotEnoughParticipants
                }
                
                // find score list
                
                var matches = Functions.regexSearch("<td class=\"tabelle1\" valign=\"top\" align=\"right\"[\\s]?>((?:(?!</td>)[\\s\\S])*)</td>", text: value!)

                if (matches.count > 2) {
                    
                    matches = matches.map {
                        Functions.stripHtml($0)
                    }
                    
                    for (index, _) in matches.enumerate() {
                        if (index % 2 == 0 && index != matches.count - 2) {
                            
                            let next = matches[index+1]
                            
                            var amount: Int
                            var isOwn: Bool
                            if (next.rangeOfString("inklusive Ihrer Leistung") != nil) {
                                amount = Int(next.stringByReplacingOccurrencesOfString(" (inklusive Ihrer Leistung)", withString: ""))!
                                isOwn = true
                            }
                            else {
                                isOwn = false
                                amount = Int(next) ?? 0
                            }
                            
                            let score = Score(text: matches[index], amount: amount, isOwn: isOwn)
                            detail.scores.append(score)
                        }
                    }
                    detail.scoresStatus = .Available
                    
                    detail.average = matches[matches.count - 1]
                    detail.participants = Int(matches[matches.count - 2]) ?? 0

                    // attach to already listed grade via delegate
                    self.delegate?.attachDetail(DetailRequestError(type: .None), grade: grade, detail: detail)
                    return

                }
                else if (matches.count == 0) {
                    return
                }
                else {
                    // attach as error to already listet grade
                    self.delegate?.attachDetail(DetailRequestError(type: .Error, code: (1200 + matches.count)), grade: grade, detail: nil)
                    return
                }
            }
        }
    }
    
    /*
     * Get current refreshing status.
     */
    internal func getRefreshing() -> Bool {
        return self.refreshing
    }
    
    /*
     * Sub-orders all grades by their term descending.
     */
    private func orderGradelistByTerm(gradelist: [Grade]) -> [(String, [Grade])] {

        var dict = [String: [Grade]]()
        
        for entry in gradelist {
            let term = entry.term
            
            if (dict[term] == nil) {
                dict[term] = [entry]
            }
            else {
                dict[term]!.append(entry)
            }
        }

        return dict.sort { self.valueForTerm($0.0) > self.valueForTerm($1.0) }

    }
    
    /*
     * Calculates a value for a term to order them properly.
     */
    private func valueForTerm(term: String) -> Double {
        
        if (term == "") {
            return 0
        }
        
        var parts = term.characters.split {$0 == " "}.map { String($0) }
        
        // get year from strings like 14/15 or 15
        let year: String = (parts[1].rangeOfString("/") != nil) ? parts[1].characters.split { $0 == "/"}.map { String($0) }[1] : parts[1]
        
        var value = 0.0
        
        // assume sommer to be bigger than winter
        if (parts[0] == "SoSe") {
            value = Double(year)! + 0.5
        }
        else if (parts[0] == "WiSe") {
            value = Double(year)!
        }
        
        return value
    }
    
    /*
     * Check if html string contains a specific class.
     */
    private func checkForClasses(string: String) -> Bool {
        for e in school.gradelistClasses {
            if ((string as NSString).containsString(e)) {
                return true
            }
        }
        return false
    }
    
    
    /*
     * Save row indices for specific table headers.
     */
    private func createGradelistIndicesFromData(data: [String]) {
        school.gradelistIndices[.Lecture] = data.indexOf("Prüfungstext")!
        school.gradelistIndices[.Term] = data.indexOf("Semester")!
        school.gradelistIndices[.Grade] = data.indexOf("Note")!
        school.gradelistIndices[.State] = data.indexOf("Status")!
        if (data.contains("Credit Points")) {
            school.gradelistIndices[.CP] = data.indexOf("Credit Points")!
        }
        else if (data.contains("CP")) {
            school.gradelistIndices[.CP] = data.indexOf("CP")!
        }
        else if (data.contains("ECTS")) {
            school.gradelistIndices[.CP] = data.indexOf("ECTS")!
        }
        else if (data.contains("Bonus")) {
            school.gradelistIndices[.CP] = data.indexOf("Bonus")!
        }
    }
    
    /*
     * Increase attempt account for a request type.
     */
    private func increaseAttempts(type: RequestAttemptType, identifier: String) {
        if (attempts[type] == nil) {
            attempts[type] = [String: Int]()
        }
        
        attempts[type]![identifier] = attempts[type]![identifier] == nil ? 0 : attempts[type]![identifier]! + 1
    }
    
    /*
     * Check html whether details should be available.
     */
    private func configureDetailSwitch(html: String) {
        let tables = Functions.regexSearch("<table[\\s\\S]*?>((?:(?!</table>)[\\s\\S])*)</table>", text: html)
        let links = Functions.regexSearch("href=\"[^\"]*?asi.*?\"", text: tables[1])
        
        settings[Setting.ShowDetailSwitch.rawValue] = links.count > 0 ? true : false
        
        if (settings[Setting.ShowDetailSwitch.rawValue] == false) {
            settings[Setting.IncludeDetails.rawValue] = false
        }
        
        NSUserDefaults.standardUserDefaults().setObject(settings, forKey: "settings")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    /*
     * Open local html file.
     */
    private func loadTestingFile() -> String {
        return try! String(contentsOfFile: NSBundle.mainBundle().pathForResource("\(school.key)", ofType: "html")!)
    }
}