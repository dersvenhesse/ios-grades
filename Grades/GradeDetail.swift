//
//  GradeDetail.swift
//  grades
//
//  Created by Sven Hesse on 22.02.16.
//  Copyright © 2016 Sven Hesse. All rights reserved.
//

import Foundation

/*
 * Types for detail (score) status.
 */
enum ScoresStatusType {
    case Available
    case NotAvailable
    case NotEnoughParticipants
}

/*
 * Object holding detail data, like the score list.
 */
class GradeDetail {
    var participants: Int = 0
    var average: String = ""
    
    var scoresStatus: ScoresStatusType = .NotAvailable
    var scores: [Score] = [Score]()
}

/*
 * Object holding specific score data.
 */
class Score : CustomStringConvertible {
    var text: String
    var amount: Int
    var isOwn: Bool
    
    init(text: String, amount: Int = 0, isOwn: Bool = false) {
        self.text = text
        self.amount = amount
        self.isOwn = isOwn
    }
    
    convenience init() {
        self.init(text: "", amount: 0, isOwn: false)
    }
    
    // to string
    var description: String {
        return "(\(text), \(amount), \(isOwn))"
    }
}
