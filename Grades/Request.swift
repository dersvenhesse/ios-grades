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
    case none
    case settingsError
    case qisError, loginError, asiError, degreeError, listError
    case scoreError
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
    case none
    case error
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
    case degreeAttempt
    case scoreListAttempt
}
