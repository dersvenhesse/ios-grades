//
//  GradeTableViewCell.swift
//  Grades
//
//  Created by Sven Hesse on 17.01.16.
//  Copyright © 2016 Sven Hesse. All rights reserved.
//

import Foundation
import UIKit

/*
 * Custom table cell for grade list.
 */
class GradeTableViewCell: UITableViewCell {

    @IBOutlet weak var lectureLabel: UILabel!
    @IBOutlet weak var gradeLabel: UILabel!
    @IBOutlet weak var cpLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
