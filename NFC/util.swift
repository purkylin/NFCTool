//
//  util.swift
//  NFC
//
//  Created by Purkylin King on 2019/10/11.
//  Copyright © 2019 Purkylin King. All rights reserved.
//

import Foundation
import UIKit

func createButton(title: String) -> UIButton {
    let btn = UIButton(type: .system)
    btn.setTitle(title, for: .normal)
    btn.setTitleColor(UIColor.white, for: .normal)
    btn.backgroundColor = UIColor.black
    btn.layer.cornerRadius = 6
    
    btn.translatesAutoresizingMaskIntoConstraints = false
    btn.heightAnchor.constraint(equalToConstant: 32).isActive = true
    return btn
}
