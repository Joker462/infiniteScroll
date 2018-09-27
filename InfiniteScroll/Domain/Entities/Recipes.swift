//
//  Recipes.swift
//  InfiniteScroll
//
//  Created by Son HD on 9/7/18.
//  Copyright © 2018 joker. All rights reserved.
//

import Foundation

struct Recipes: Decodable {
    var recipeItems: [RecipeItem] = []
    
    private enum CodingKeys: String, CodingKey {
        case recipes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        recipeItems = try container.decode([RecipeItem].self, forKey: .recipes)
    }
}

enum PhotoState {
    case new, downloaded, filtered, failed
}

struct RecipeItem: Decodable {
    var recipe_id: String = ""
    var publisher: String = ""
    var image_url: String = ""
    var title: String = ""
}
