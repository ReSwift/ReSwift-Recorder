//
//  StateHistoryView.swift
//  Meet
//
//  Created by Benjamin Encz on 12/1/15.
//  Copyright © 2015 DigiTales. All rights reserved.
//

import UIKit

class StateHistoryView: UIView {

    var statesCount: Int = 0 {
        didSet {
            collectionView.reloadData()
        }
    }

    var cellSelectionCallback: ((Int) -> Void)?

    private let collectionView: UICollectionView
    private let collectionViewCellReuseIdentifier = "StateCell"

    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .Horizontal
        collectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.greenColor()
        collectionView.registerClass(StateHistoryCollectionViewCell.self,
            forCellWithReuseIdentifier: collectionViewCellReuseIdentifier)

        super.init(frame: frame)

        collectionView.dataSource = self
        collectionView.delegate = self

        addSubview(collectionView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension StateHistoryView: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(
            collectionViewCellReuseIdentifier, forIndexPath: indexPath) as! StateHistoryCollectionViewCell

        cell.text = "\(indexPath.row + 1)"

        return cell
    }

    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {

        return CGSize(width: frame.size.height, height: frame.size.height)
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return statesCount
    }

    func collectionView(collectionView: UICollectionView,
        didSelectItemAtIndexPath indexPath: NSIndexPath) {

        cellSelectionCallback?(indexPath.row + 1)
    }

}