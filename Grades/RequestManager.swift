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

    // alamofire session manager to hold cookies
    var alamofireManager: Alamofire.SessionManager
    
    // flag if refresh is currently in progress
    var refreshing = false
    
    // timestamp from last grade request
    var timestamp: Date?
    
    // grade texts to be excluded
    let excludetexts = ["Durchschnittsnote Deutschlandstipendium", "ECTS-Kontostand: (fortlaufende Ermittlung)", "Kontostand: ECTS (fortlaufende Ermittlung)"]

    // attempt amount for specific requests to repeat requests
    var attempts = [RequestAttemptType: [String: Int]]()

    var asi = ""
    var degree = ""

    /*
     * Initialise manager using alamofire.
     */
    fileprivate init() {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.timeoutIntervalForRequest = 10
        
        alamofireManager = Alamofire.SessionManager(configuration: config)
    }
    
    /*
     * Fetches grades and return them via callback (sub-ordered by term and including the amount).
     */
    internal func fetchGrades(callback: @escaping (RequestError, [(String, [Grade])], Int) -> Void) {
        self.timestamp = Date()
        attempts = [RequestAttemptType: [String: Int]]()
        
        self.navigate() { (error) in
            if (error.type != .none) {
                self.refreshing = false
                return callback(error, [], 0)
            }
            else {
                self.findList() { (error, gradelist) in
                    if (error.type != .none) {
                        self.refreshing = false
                        return callback(error, [], 0)
                    }
                    
                    self.refreshing = false
                    
                    return callback(RequestError(type: .none), self.orderGradelistByTerm(gradelist: gradelist), gradelist.count)
                }
            }
        }
    }
    
    /*
     * Navigate to qis page, login user and find asi as well as degree.
     */
    fileprivate func navigate(callback: @escaping (_ error: RequestError) -> Void) {
        
        self.refreshing = true
        
        if (username == "" || password == "" || school.url == "") {
            return callback(RequestError(type: .settingsError))
        }
        
        // call login page and set cookie (jsessionid)
        self.gotoQis() { (error) in
            if (error.type != .none) {
                return callback(error)
            }
            
            // login
            self.login(username: username, password: password) { (error) in
                if (error.type != .none && !testing) {
                    return callback(error)
                }
                
                // navigate to menu and find asi
                self.findAsi() { (error) in
                    if (error.type != .none) {
                        return callback(error)
                    }
                    
                    // navigate to find degree
                    self.findDegree() { (error) in
                        if (error.type != .none && !testing) {
                            return callback(error)
                        }
                        
                        return callback(RequestError(type: .none))
                    }
                }
            }
        }
    }
    
    /*
     * Open qis page.
     */
    fileprivate func gotoQis(callback: @escaping (_ error: RequestError) -> Void) {
        self.alamofireManager.request("https://" + school.url + school.urlTrail + "user&type=0").responseString { response in
            
            if (!response.result.isSuccess) {
                return callback(RequestError(type: .qisError))
            }
            else if (response.response?.statusCode >= 500) {
                return callback(RequestError(type: .qisError))
            }
            else {
                return callback(RequestError(type: .none))
            }
        }
    }
    
    /*
     * Login user into qis.
     */
    fileprivate func login(username: String, password: String, callback: @escaping (_ error: RequestError) -> Void) {
        self.alamofireManager.request("https://" + school.url + school.urlTrail + "user&type=1&category=auth.login&startpage=portal.vm&breadCrumbSource=portal", method: .post, parameters: [school.loginParameters.0: username, school.loginParameters.1: password, "submit": "Anmelden"]).responseString { response in
            
            let value = response.result.value
            
            if (!response.result.isSuccess) {
                return callback(RequestError(type: .loginError, code: 314))
            }
            else if (value == nil) {
                return callback(RequestError(type: .loginError, code: 361))
            }
            else if (value == "") {
                return callback(RequestError(type: .loginError, code: 382))
            }
            else if (value!.range(of: "Anmeldung fehlgeschlagen") != nil) {
                return callback(RequestError(type: .loginError, code: 349))
            }
            else {
                return callback(RequestError(type: .none))
            }
        }
    }
    
    /*
     * Find and stores current asi after user is logged in to enter asi protected area.
     */
    fileprivate func findAsi(callback: @escaping (_ error: RequestError) -> Void) {
        self.alamofireManager.request("https://" + school.url + school.urlTrail + "change&type=1&moduleParameter=studyPOSMenu&next=menu.vm&xml=menu").responseString { response in
            
            var value = response.result.value
            
            if (testing) {
                value = self.loadTestingFile()
            }
            
            if (!response.result.isSuccess || value == nil || value == "") {
                return callback(RequestError(type: .asiError, code: 481))
            }
            else {
                var matches = Functions.regexSearch(regex: ";asi=.*?[\"|&]", text: value!)
                
                // save first match as asi
                if (matches.count > 0 && matches[0].characters.count == 26) {
                    self.asi = (matches[0] as NSString).substring(with: NSMakeRange(5, 20))
                    return callback(RequestError(type: .none))
                }
                else {
                    return callback(RequestError(type: .asiError, code: (500 + matches.count)))
                }
            }
        }
    }
    
    /*
     * Find and stores degree.
     */
    fileprivate func findDegree(callback: @escaping (_ error: RequestError) -> Void) {
        self.alamofireManager.request("https://" + school.url + school.urlTrail + "notenspiegelStudent&next=tree.vm&nextdir=qispos/notenspiegel/student&menuid=notenspiegelStudent&breadcrumb=notenspiegel&breadCrumbSource=menu&asi=" + asi).responseString { response in
            
            let value = response.result.value
                        
            if (!response.result.isSuccess || value == nil || value == "") {
                return callback(RequestError(type: .degreeError, code: 129))
            }
            else if (value!.range(of: "viele Klicks Warteseite") != nil) {
                return callback(RequestError(type: .degreeError, code: 141))
            }
            else {
                var matches = Functions.regexSearch(regex: "Aabschl\\%3D[\\w]*", text: value!)
                
                if (matches.count > 0) {
                    let range = matches[0].range(of: "%3D")
                    let index = matches[0].characters.distance(from: matches[0].startIndex, to: range!.upperBound)
                    
                    // save
                    self.degree = (matches[0] as NSString).substring(from: index)
                    return callback(RequestError(type: .none))
                }
                else {
                    // retries when match is found even though it should be found
                    self.increaseAttempts(type: .degreeAttempt, identifier: "")
                    if (self.attempts[.degreeAttempt]![""] < 3) {
                        Functions.delay(delay: 2.0) {
                            self.findDegree(callback: callback)
                        }
                    }
                    else {
                        return callback(RequestError(type: .degreeError, code: 183))
                    }
                }
            }
        }
    }
    
    /*
     * Navigate to grade list (using degree and asi) and finally parse all grades.
     */
    fileprivate func findList(callback: @escaping (_ error: RequestError, _ list: [Grade]) -> Void) {
        var full_url: String = "https://" + school.url + school.urlTrail + "notenspiegelStudent&next=list.vm&nextdir=qispos/notenspiegel/student&createInfos=Y&struct=auswahlBaum&nodeID=auswahlBaum%7Cabschluss%3Aabschl%3D" + degree
        
        if (school.key == "tukl")
            full_url += "%7Cstudiengang%3Astg%3DA44&expand=0&asi=" + asi
        else
            full_url += "%7Cstudiengang%3Astg%3DA44&expand=0&asi=" + asi
      
        self.alamofireManager.request(full_url).responseString { response in
            
            var value = response.result.value
            
            if (testing) {
                // use local file instead of web
                value = self.loadTestingFile()
            }
            
            if (!response.result.isSuccess || value == nil || value == "") {
                return callback(RequestError(type: .listError, code: 612), [])
            }
            else {
                var gradelist: [Grade] = [Grade]()
                
                let matches = Functions.regexSearch(regex: "<tr>((?:(?!</tr>)[\\s\\S])*)</tr>", text: value!)
                
                if (matches.count == 0) {
                    return callback(RequestError(type: .listError, code: 631), [])
                }
                
                // find table header for specific row and stores their indices
                
                if (school.gradelistIndices.count == 0) {
                    for match in matches {
                        var data = Functions.regexSearch(regex: "<th (class=\"tabelleheader\")?(\\s)*align=\"[\\w]*\"(\\s)*(width=\"[\\w%]*\")?(\\s)*scope=\"col\"[\\s]?>((?:(?!</th>)[\\s\\S])*)</th>", text: match)
                        
                        if (data.count == 0) {
                            continue
                        }
                        
                        data = data.map {
                            Functions.stripHtml(string: $0)
                        }
                        
                        self.createGradelistIndicesFromData(data: data)
                    }
                }
                
                if (school.gradelistIndices.count == 0) {
                    return callback(RequestError(type: .listError, code: 676), [])
                }
                
                // show switch on settings page when details should be available
                self.configureDetailSwitch(html: value!)
                
                // count some special cases to prevent errors
                var countClassmatch = 0
                var countContinue = 0
                var countExcluded = 0
                
                // delay for loading details (to prevent "zu viele Klicks Warteseite")
                var delay: Double = 0
                
                for match in matches {
                    if (self.checkForClasses(string: match)) {
                        
                        var data = Functions.regexSearch(regex: "<td (nowrap=\"nowrap\" )?(class=\"[\\w]*\" )?valign=\"(top|center)\"[^>]*>((?:(?!</td>)[\\s\\S])*)</td>", text: match)
                        
                        if (data.count == 0) {
                            countContinue += 1
                            continue
                        }

                        data = data.map {
                            Functions.stripHtml(string: $0)
                        }
                        
                        if !(school.gradelistIndices[.lecture] == nil || school.gradelistIndices[.state] == nil || self.excludetexts.contains(data[school.gradelistIndices[.lecture]!]) || data[school.gradelistIndices[.state]!] == "angemeldet" || data[school.gradelistIndices[.state]!] == "AN" || data[school.gradelistIndices[.state]!] == "Prüfung vorhanden") {
                            
                            // create object
                            let grade = Grade(
                                lecture: school.gradelistIndices[.lecture] != nil ? data[school.gradelistIndices[.lecture]!] : "",
                                term: school.gradelistIndices[.term] != nil ? data[school.gradelistIndices[.term]!] : "",
                                grade: school.gradelistIndices[.grade] != nil ? ((data[school.gradelistIndices[.grade]!]).replacingOccurrences(of: ",", with: ".") as NSString).doubleValue : 0.0,
                                cp: school.gradelistIndices[.cp] != nil ? ((data[school.gradelistIndices[.cp]!]).replacingOccurrences(of: ",", with: ".") as NSString).doubleValue : 0.0,
                                state: school.gradelistIndices[.state] != nil ? data[school.gradelistIndices[.state]!] : ""
                            )
                                                                                    
                            let hrefs = Functions.regexSearch(regex: "href=\"[^\"]*?asi.*?\"", text: match)

                            // find details link to fetch scores
                            if (hrefs.count > 0 && self.delegate != nil) {
                                if (settings[Setting.includeDetails.rawValue] != false) {
                                    var scoreLink = hrefs[0].substring(with: hrefs[0].characters.index(hrefs[0].startIndex, offsetBy: 6) ..< hrefs[0].characters.index(hrefs[0].endIndex, offsetBy: -1))
                                    scoreLink = scoreLink.replacingOccurrences(of: "&amp;", with: "&")
                                    
                                    delay += 0.2
                                    
                                    // load score with minimal delay
                                    Functions.delay(delay: delay) {
                                        self.loadScorelist(scoreLink: scoreLink, grade: grade)
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
                    return callback(RequestError(type: .listError, code: (700 + countClassmatch)), [])
                }
                if (countContinue == matches.count) {
                    return callback(RequestError(type: .listError, code: (800 + countContinue)), [])
                }
                if (countExcluded == matches.count) {
                    return callback(RequestError(type: .listError, code: (900 + countExcluded)), [])
                }
                
                if (gradelist.count == 0) {
                    return callback(RequestError(type: .listError, code: 619), [])
                }
                else {
                    return callback(RequestError(type: .none), gradelist)
                }
            }
        }
    }
    
    /*
     * Load grade details including the scores.
     */
    fileprivate func loadScorelist(scoreLink: String, grade: Grade) {
        self.alamofireManager.request(scoreLink).responseString { response in
            
            if(response.result.error != nil || response.result.isFailure) {
                self.delegate?.attachDetail(error: DetailRequestError(type: .error, code: 1134), grade: grade, detail: nil)
                return
            }
            
            let value = response.result.value
                        
            if (!response.result.isSuccess || value == nil || value == "") {
                self.delegate?.attachDetail(error: DetailRequestError(type: .error, code: 1198), grade: grade, detail: nil)
                return
            }
            else if (value!.range(of: "de.his.exceptions.AsiException") != nil) {
                self.delegate?.attachDetail(error: DetailRequestError(type: .error, code: 1132), grade: grade, detail: nil)
                return
            }
            else if (value!.range(of: "viele Klicks Warteseite") != nil) {
                // some retries when qis denies quick navigation
                self.increaseAttempts(type: .scoreListAttempt, identifier: grade.lecture)
                if (self.attempts[.scoreListAttempt]![grade.lecture] < 3) {
                    Functions.delay(delay: 2.0) {
                        self.loadScorelist(scoreLink: scoreLink, grade: grade)
                    }
                }
                else {
                    self.delegate?.attachDetail(error: DetailRequestError(type: .error, code: 1161), grade: grade, detail: nil)
                }
                return
            }
            else {
                
                let detail = GradeDetail()
                
                if (value!.range(of: "zu wenige Leistungen vorliegen") != nil) {
                    detail.scoresStatus = .notEnoughParticipants
                }
                
                // find score list
                
                var matches = Functions.regexSearch(regex: "<td class=\"tabelle1\" valign=\"top\" align=\"right\"[\\s]?>((?:(?!</td>)[\\s\\S])*)</td>", text: value!)

                if (matches.count > 2) {
                    
                    matches = matches.map {
                        Functions.stripHtml(string: $0)
                    }
                    
                    for (index, _) in matches.enumerated() {
                        if (index % 2 == 0 && index != matches.count - 2) {
                            
                            let next = matches[index+1]
                            
                            var amount: Int
                            var isOwn: Bool
                            if (next.range(of: "inklusive Ihrer Leistung") != nil) {
                                amount = Int(next.replacingOccurrences(of: " (inklusive Ihrer Leistung)", with: ""))!
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
                    detail.scoresStatus = .available
                    
                    detail.average = matches[matches.count - 1]
                    detail.participants = Int(matches[matches.count - 2]) ?? 0

                    // attach to already listed grade via delegate
                    self.delegate?.attachDetail(error: DetailRequestError(type: .none), grade: grade, detail: detail)
                    return

                }
                else if (matches.count == 0) {
                    return
                }
                else {
                    // attach as error to already listet grade
                    self.delegate?.attachDetail(error: DetailRequestError(type: .error, code: (1200 + matches.count)), grade: grade, detail: nil)
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
    fileprivate func orderGradelistByTerm(gradelist: [Grade]) -> [(String, [Grade])] {

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

        return dict.sorted { self.valueForTerm(term: $0.0) > self.valueForTerm(term: $1.0) }

    }
    
    /*
     * Calculates a value for a term to order them properly.
     */
    fileprivate func valueForTerm(term: String) -> Double {
        
        if (term == "") {
            return 0
        }
        
        var parts = term.characters.split {$0 == " "}.map { String($0) }
        
        // get year from strings like 14/15 or 15
        let year: String = (parts[1].range(of: "/") != nil) ? parts[1].characters.split { $0 == "/"}.map { String($0) }[1] : parts[1]
        
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
    fileprivate func checkForClasses(string: String) -> Bool {
        for e in school.gradelistClasses {
            if ((string as NSString).contains(e)) {
                return true
            }
        }
        return false
    }
    
    
    /*
     * Save row indices for specific table headers.
     */
    fileprivate func createGradelistIndicesFromData(data: [String]) {
        if (data.contains("Prüfungstext")) {
            school.gradelistIndices[.lecture] = data.index(of: "Prüfungstext")!
        }
        
        if (data.contains("Semester")) {
            school.gradelistIndices[.term] = data.index(of: "Semester")!
        }
        
        if (data.contains("Note")) {
            school.gradelistIndices[.grade] = data.index(of: "Note")!
        }
        
        if (data.contains("Status")) {
            school.gradelistIndices[.state] = data.index(of: "Status")!
        }
        
        if (data.contains("Credit Points")) {
            school.gradelistIndices[.cp] = data.index(of: "Credit Points")!
        }
        else if (data.contains("CP")) {
            school.gradelistIndices[.cp] = data.index(of: "CP")!
        }
        else if (data.contains("ECTS")) {
            school.gradelistIndices[.cp] = data.index(of: "ECTS")!
        }
        else if (data.contains("Bonus")) {
            school.gradelistIndices[.cp] = data.index(of: "Bonus")!
        }
    }
    
    /*
     * Increase attempt account for a request type.
     */
    fileprivate func increaseAttempts(type: RequestAttemptType, identifier: String) {
        if (attempts[type] == nil) {
            attempts[type] = [String: Int]()
        }
        
        attempts[type]![identifier] = attempts[type]![identifier] == nil ? 0 : attempts[type]![identifier]! + 1
    }
    
    /*
     * Check html whether details should be available.
     */
    fileprivate func configureDetailSwitch(html: String) {
        let tables = Functions.regexSearch(regex: "<table[\\s\\S]*?>((?:(?!</table>)[\\s\\S])*)</table>", text: html)
        let links = Functions.regexSearch(regex: "href=\"[^\"]*?asi.*?\"", text: tables[1])
        
        settings[Setting.showDetailSwitch.rawValue] = links.count > 0 ? true : false
        
        if (settings[Setting.showDetailSwitch.rawValue] == false) {
            settings[Setting.includeDetails.rawValue] = false
        }
        
        UserDefaults.standard.set(settings, forKey: "settings")
        UserDefaults.standard.synchronize()
    }
    
    /*
     * Open local html file.
     */
    fileprivate func loadTestingFile() -> String {
        return try! String(contentsOfFile: Bundle.main.path(forResource: "\(school.key)", ofType: "html")!)
    }
}
