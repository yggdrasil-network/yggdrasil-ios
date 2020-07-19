//
//  SplitViewController.swift
//  YggdrasilNetwork
//
//  Created by Neil Alexander on 02/01/2019.
//

import UIKit

class SplitViewController: UISplitViewController, UISplitViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.preferredDisplayMode = .allVisible
    }

}
