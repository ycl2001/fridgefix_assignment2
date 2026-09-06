//
//  CookingContext.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import Foundation

/// Captures the user's current cooking situation and meal preferences.
///
/// Dietary restrictions, maximum cooking time, and maximum difficulty are
/// hard constraints. Cuisine, taste, expiry usage, and nutrition influence
/// ranking among recipes that remain feasible.
struct CookingContext: Equatable, Codable {
    let maximumCookingTime: CookingTimeLimit
    let maximumDifficulty: CookingDifficulty
    let preferredCuisines: Set<Cuisine>
    let preferredTastes: Set<TastePreference>
    let dietaryRestrictions: Set<DietaryRestriction>
    let prioritisesExpiringIngredients: Bool
}
