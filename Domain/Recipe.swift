//
//  Recipe.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import Foundation

/// Represents a meal that FridgeFix may recommend to a home cook.
///
/// A recipe contains the information needed to evaluate realistic suitability:
/// cooking requirements, preferences, ingredient requirements, and a simple
/// nutritional balance indicator.
struct Recipe: Identifiable, Equatable, Codable {
    let id: RecipeID
    let name: String
    let cuisine: Cuisine
    let tastePreferences: Set<TastePreference>
    let dietaryLabels: Set<DietaryRestriction>
    let totalCookingTimeInMinutes: Int
    let difficulty: CookingDifficulty
    let ingredientRequirements: [RecipeIngredientRequirement]
    let nutritionBalance: NutritionBalance
    let instructions: [String]
}

/// Describes one ingredient required by a recipe.
struct RecipeIngredientRequirement: Equatable, Codable {
    let ingredientName: String
    let isEssential: Bool
    let substitutionCategory: IngredientSubstitutionCategory?
}

/// Provides a lightweight, non-medical description of recipe balance.
enum NutritionBalance: String, CaseIterable, Codable {
    case balanced
    case partlyBalanced
    case limitedBalance
}
