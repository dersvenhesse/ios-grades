//
//  DetailTableViewCell.swift
//  Grades
//
//  Created by Sven Hesse on 19.01.16.
//  Copyright © 2016 Sven Hesse. All rights reserved.
//

import Foundation
import UIKit

/*
 * Custom table cell for detail view.
 */
class DetailTableViewCell: UITableViewCell {
        
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
