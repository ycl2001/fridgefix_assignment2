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

    var displayName: String {
        switch self {
        case .asian:
            return "Asian"
        case .italian:
            return "Italian"
        case .mexican:
            return "Mexican"
        case .mediterranean:
            return "Mediterranean"
        case .comfortFood:
            return "Comfort Food"
        }
    }
}

/// Describes the taste characteristics a user may prefer.
enum TastePreference: String, CaseIterable, Codable, Hashable {
    case savoury
    case spicy
    case fresh
    case mild
    case hearty

    var displayName: String {
        switch self {
        case .savoury:
            return "Savoury"
        case .spicy:
            return "Spicy"
        case .fresh:
            return "Fresh"
        case .mild:
            return "Mild"
        case .hearty:
            return "Hearty"
        }
    }
}

/// Represents a dietary restriction that FridgeFix must respect.
enum DietaryRestriction: String, CaseIterable, Codable, Hashable {
    case vegetarian
    case vegan
    case dairyFree
    case glutenFree
    case nutFree

    var displayName: String {
        switch self {
        case .vegetarian:
            return "Vegetarian"
        case .vegan:
            return "Vegan"
        case .dairyFree:
            return "Dairy Free"
        case .glutenFree:
            return "Gluten Free"
        case .nutFree:
            return "Nut Free"
        }
    }
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
