//
//  StateHistoryCollectionViewCell.swift
//  Meet
//
//  Created by Benjamin Encz on 12/1/15.
//  Copyright © 2015 DigiTales. All rights reserved.
//

import UIKit

class StateHistoryCollectionViewCell: UICollectionViewCell {

    var label: UILabel!
    var text: String = "" {
        didSet {
            label.text = text
            label.sizeToFit()
            label.center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        label = UILabel()
        label.font = label.font.withSize(18)
        addSubview(label)

        backgroundColor = UIColor.red
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
