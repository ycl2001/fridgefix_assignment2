//
//  RecipeRecommendation.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import Foundation

/// Represents a recipe selected and ordered for the user's current cooking context.
///
/// The position of a recommendation in the returned array represents its rank.
/// The recommendation also contains domain reasons that can be shown to the user.
struct RecipeRecommendation: Identifiable, Equatable {
    let suitability: RecipeSuitability
    let rankingReasons: [RecommendationReason]

    var id: RecipeID {
        suitability.recipe.id
    }

    var recipe: Recipe {
        suitability.recipe
    }
}

/// Explains the domain factors that contributed to a recipe's ranking.
enum RecommendationReason: String, Equatable, Hashable {
    case readyToCook
    case usesIngredientExpiringSoon
    case minimalShopping
    case matchesCuisinePreference
    case matchesTastePreference
    case suitableCookingTime
    case suitableDifficulty
    case balancedNutrition
    case strongPantryMatch

    var displayText: String {
        switch self {
        case .readyToCook:
            return "Ready with your pantry"
        case .usesIngredientExpiringSoon:
            return "Uses an ingredient expiring soon"
        case .minimalShopping:
            return "Requires minimal shopping"
        case .matchesCuisinePreference:
            return "Matches your cuisine preference"
        case .matchesTastePreference:
            return "Matches your taste preference"
        case .suitableCookingTime:
            return "Fits your available time"
        case .suitableDifficulty:
            return "Fits your cooking confidence"
        case .balancedNutrition:
            return "Offers a balanced meal"
        case .strongPantryMatch:
            return "Uses many ingredients you have"
        }
    }
}
