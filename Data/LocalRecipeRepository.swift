//
//  LocalRecipeRepository.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import Foundation

/// Provides the FridgeFix Use Cases with curated local recipe data.
///
/// This implementation is used by the MVP instead of an online recipe service.
struct LocalRecipeRepository: RecipeRepository {

    private let recipes: [Recipe]

    init(recipes: [Recipe] = SampleRecipeData.recipes) {
        self.recipes = recipes
    }

    func fetchRecipes() throws -> [Recipe] {
        guard !recipes.isEmpty else {
            throw RecipeRepositoryError.recipeCatalogueUnavailable
        }

        return recipes
    }
}
