//
//  GradeDetailDelegate.swift
//  grades
//
//  Created by Sven Hesse on 20.02.16.
//  Copyright © 2016 Sven Hesse. All rights reserved.
//

import Foundation

/*
 * Protocol to attach details to a given grade.
 */
protocol GradeDetailDelegate {
    func attachDetail(error: DetailRequestError, grade: Grade, detail: GradeDetail?)
}
