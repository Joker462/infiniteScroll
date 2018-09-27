//
//  RecipesTableViewCell.swift
//  InfiniteScroll
//
//  Created by Son HD on 9/6/18.
//  Copyright © 2018 joker. All rights reserved.
//

import UIKit

class RecipesTableViewCell: UITableViewCell {

    // IBOutlets
    @IBOutlet weak var titleLabel:          UILabel?
    @IBOutlet weak var pictureImageView:    UIImageView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        pictureImageView?.clipsToBounds = true
    }

    func configure(_ item: RecipeItemViewModel) {
        titleLabel?.text = item.title
        pictureImageView?.image = item.image
    }
}
