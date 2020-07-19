//
//  ToggleTableViewCell.swift
//  YggdrasilNetwork
//
//  Created by Neil Alexander on 07/01/2019.
//

import UIKit

class ToggleTableViewCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var toggle: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
