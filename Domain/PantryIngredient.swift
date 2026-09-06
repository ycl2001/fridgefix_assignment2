//
//  PantryIngredient.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import Foundation

/// Groups ingredients that may be valid substitutions for one another.
enum IngredientSubstitutionCategory: String, CaseIterable, Codable, Hashable {
    case leafyGreen
    case aromatic
    case protein
    case grain
    case cookingOil
}

/// Represents an ingredient currently available in the user's pantry.
///
/// The MVP records ingredient availability and optional expiry information.
/// It does not track quantities. Ingredients expiring today or within the
/// next two days are treated as expiring soon.
struct PantryIngredient: Identifiable, Equatable, Codable {
    let id: IngredientID
    let name: String
    let substitutionCategory: IngredientSubstitutionCategory
    var expiresAt: Date?

    var isExpiringSoon: Bool {
        isExpiringSoon(on: Date())
    }

    func isExpiringSoon(on date: Date) -> Bool {
        guard let expiresAt else {
            return false
        }

        let calendar = Calendar.current
        let currentDay = calendar.startOfDay(for: date)
        let expiryDay = calendar.startOfDay(for: expiresAt)

        let daysUntilExpiry = calendar.dateComponents(
            [.day],
            from: currentDay,
            to: expiryDay
        ).day ?? 0

        return (0...2).contains(daysUntilExpiry)
    }
}
