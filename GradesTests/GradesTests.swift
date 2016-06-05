//
//  GradesTests.swift
//  GradesTests
//
//  Created by Sven Hesse on 23.06.15.
//  Copyright (c) 2015 Sven Hesse. All rights reserved.
//

import UIKit
import XCTest

@testable import grades

class GradesTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    /*
     * Checks whether the school keys are unique.
     */
    func testSchoolKeyUniqueness() {
        var keys = [String]()
        var isUnique = true
        
        for s in schools {
            if (keys.contains(s.key)) {
                isUnique = false
            }
            keys.append(s.key)
        }
        
        XCTAssertTrue(isUnique)
    }
}
