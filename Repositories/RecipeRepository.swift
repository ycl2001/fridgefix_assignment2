//
//  RecipeRepository.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import Foundation

/// Provides FridgeFix with the recipes available for recommendation.
///
/// The MVP will use a local implementation containing curated recipe data.
/// The protocol keeps the Use Case independent from the storage method.
protocol RecipeRepository {
    func fetchRecipes() throws -> [Recipe]
}

/// Describes a domain failure when FridgeFix cannot obtain recipe information.
enum RecipeRepositoryError: Error {
    case recipeCatalogueUnavailable
}
