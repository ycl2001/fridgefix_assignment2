//
//  RecipeSuitability.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import Foundation

/// Describes how close a recipe is to being practically cookable.
enum RecipeReadiness: String, Codable, Equatable, Hashable {
    case readyToCook
    case almostReady
    case needsOneToTwoIngredients

    var displayName: String {
        switch self {
        case .readyToCook:
            return "Ready to Cook"
        case .almostReady:
            return "Almost Ready"
        case .needsOneToTwoIngredients:
            return "Needs 1–2 Ingredients"
        }
    }
}

/// Records a substitution accepted by a recipe's ingredient category.
struct IngredientSubstitution: Equatable, Codable, Hashable {
    let requiredIngredient: String
    let availableIngredient: String
    let category: IngredientSubstitutionCategory
}

/// Explains how realistically a recipe can be prepared in the current context.
struct RecipeSuitability: Equatable {
    let recipe: Recipe
    let readiness: RecipeReadiness
    let pantryMatchPercentage: Int
    let missingIngredients: [String]
    let substitutions: [IngredientSubstitution]
    let usesUrgentIngredient: Bool
    let explanation: String
}

/// Describes why a recipe cannot currently be recommended.
enum RecipeExclusionReason: Error, Equatable {
    case dietaryRestrictionConflict
    case cookingTimeExceedsLimit
    case difficultyExceedsLimit
    case essentialIngredientUnavailable
    case requiresMoreThanTwoIngredients
}

/// Represents the complete outcome of evaluating a recipe.
enum RecipeSuitabilityOutcome: Equatable {
    case suitable(RecipeSuitability)
    case excluded(RecipeExclusionReason)
}
