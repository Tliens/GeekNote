//
//  HomeNoteCollectionViewCell.swift
//  MarkupEditor
//
//  Created by mac on 2023/8/22.
//

import UIKit

class HomeNoteCollectionViewCell: UICollectionViewCell {
    override  func awakeFromNib() {
        contentView.layer.cornerRadius = 12
        contentView.layer.borderColor = UIColor.black.cgColor
        contentView.layer.borderWidth = 1
    }
}
