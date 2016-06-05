//
//  Grade.swift
//  grades
//
//  Created by Sven Hesse on 17.01.16.
//  Copyright © 2016 Sven Hesse. All rights reserved.
//

import Foundation

/*
 * Object holding the grade data.
 */
class Grade: CustomStringConvertible {
    
    var lecture: String
    var term: String
    var grade: Double
    var cp: Double
    var state: String
    
    var details: GradeDetail?
    
    init(lecture: String, term: String, grade: Double, cp: Double, state: String) {
        self.lecture = lecture
        self.grade = grade
        self.term = term
        self.cp = cp
        self.state = state
    }
    
    convenience init() {
        self.init(lecture: "", term: "", grade: 0.0, cp: 0.0, state: "")
    }
    
    // to string
    var description: String {
        return "(\(lecture), \(term), \(grade), \(cp), \(state))"
    }
    
    func equals(grade: Grade) -> Bool {
        return
            self.lecture == grade.lecture &&
            self.term == grade.term &&
            self.grade == grade.grade &&
            self.cp == grade.cp &&
            self.state == grade.state
    }
}