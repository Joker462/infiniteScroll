//
//  RecipeItemViewModel.swift
//  InfiniteScroll
//
//  Created by Son HD on 9/18/18.
//  Copyright © 2018 joker. All rights reserved.
//

import UIKit

final class RecipeItemViewModel: PhotoCell {
    let id: String
    let title: String
    
    var imageURL: URL?
    var image = UIImage(color: .gray, size: CGSize(width: 400, height: 400))
    var state: PhotoState = .new
    
    init(recipeItem: RecipeItem) {
        id = recipeItem.recipe_id
        title = recipeItem.title
        imageURL = URL(string: recipeItem.image_url)
    }
}


extension UIImage {
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}
