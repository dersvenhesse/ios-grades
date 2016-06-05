//
//  Request.swift
//  grades
//
//  Created by Sven Hesse on 13.02.16.
//  Copyright © 2016 Sven Hesse. All rights reserved.
//

import Foundation

/*
 * Error types which may occur during a request.
 */
enum RequestErrorType {
    case None
    case SettingsError
    case QisError, LoginError, AsiError, DegreeError, ListError
    case ScoreError
}

/*
 * Error with internal code to identify.
 */
class RequestError {
    var type: RequestErrorType
    var code: Int
    
    init(type: RequestErrorType, code: Int = 0) {
        self.type = type
        self.code = code
    }
}

/*
 * Error types whih may occur during a detail request.
 */
enum DetailRequestErrorType {
    case None
    case Error
}

/*
 * Error for detail request with internal code to identify.
 */
class DetailRequestError {
    var type: DetailRequestErrorType
    var code: Int
    
    init(type: DetailRequestErrorType, code: Int = 0) {
        self.type = type
        self.code = code
    }
}

/*
 * Types of request attempts.
 */
enum RequestAttemptType {
    case DegreeAttempt
    case ScoreListAttempt
}
