//
//  Extensions.swift
//  grades
//
//  Created by Sven Hesse on 31.08.16.
//  Copyright © 2016 Sven Hesse. All rights reserved.
//

import Foundation

// https://github.com/ankurp/Cent/blob/master/Sources/Dictionary.swift
extension Dictionary {
    mutating func merge<K, V>(dict: [K: V]){
        for (k, v) in dict {
            self.updateValue(v as! Value, forKey: k as! Key)
        }
    }
}

// comparable < for optionals
func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// comparable >= for optionals
func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l >= r
    default:
        return !(lhs < rhs)
    }
}
