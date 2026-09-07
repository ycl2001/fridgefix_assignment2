//
//  MealPreferences.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import Foundation

/// Describes the broad cuisine style of a recipe or user preference.
enum Cuisine: String, CaseIterable, Codable, Hashable {
    case asian
    case italian
    case mexican
    case mediterranean
    case comfortFood
}

/// Describes the taste characteristics a user may prefer.
enum TastePreference: String, CaseIterable, Codable, Hashable {
    case savoury
    case spicy
    case fresh
    case mild
    case hearty
}

/// Represents a dietary restriction that FridgeFix must respect.
enum DietaryRestriction: String, CaseIterable, Codable, Hashable {
    case vegetarian
    case vegan
    case dairyFree
    case glutenFree
    case nutFree
}

/// Groups ingredients that may be valid substitutions for one another.
enum IngredientSubstitutionCategory: String, CaseIterable, Codable, Hashable {
    case leafyGreen
    case aromatic
    case protein
    case grain
    case cookingOil

    var displayName: String {
        switch self {
        case .leafyGreen:
            return "Leafy Green"
        case .aromatic:
            return "Aromatic"
        case .protein:
            return "Protein"
        case .grain:
            return "Grain"
        case .cookingOil:
            return "Cooking Oil"
        }
    }
}
