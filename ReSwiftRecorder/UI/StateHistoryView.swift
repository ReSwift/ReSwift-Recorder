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

    fileprivate let collectionView: UICollectionView
    fileprivate let collectionViewCellReuseIdentifier = "StateCell"

    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        collectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.green
        collectionView.register(StateHistoryCollectionViewCell.self,
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

    func collectionView(_ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: collectionViewCellReuseIdentifier, for: indexPath) as! StateHistoryCollectionViewCell

        cell.text = "\((indexPath as NSIndexPath).row + 1)"

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {

        return CGSize(width: frame.size.height, height: frame.size.height)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return statesCount
    }

    func collectionView(_ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath) {

        cellSelectionCallback?((indexPath as NSIndexPath).row + 1)
    }

}
