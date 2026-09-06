//
//  EvaluateRecipeSuitabilityUseCase.swift.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import Foundation

/// Evaluates whether one recipe is realistically cookable for the user.
///
/// This Use Case protects FridgeFix's main business rules:
/// dietary compatibility, available time, cooking difficulty, ingredient
/// availability, substitutions, shopping effort, expiry priority, and
/// nutritional suitability.

struct EvaluateRecipeSuitabilityUseCase {

    /// Evaluates one recipe against the current pantry and cooking context.
    ///
    /// - Parameters:
    ///   - recipe: The meal being evaluated.
    ///   - pantry: Ingredients currently available to the user.
    ///   - context: The user's current cooking limits and preferences.
    ///   - today: The date used to evaluate expiry urgency.
    /// - Returns: A suitable recipe result or a domain-specific exclusion reason.
    func execute(
        recipe: Recipe,
        pantry: [PantryIngredient],
        context: CookingContext,
        today: Date = Date()
    ) -> RecipeSuitabilityOutcome {

        if !context.dietaryRestrictions.isSubset(of: recipe.dietaryLabels) {
            return .excluded(.dietaryRestrictionConflict)
        }

        if recipe.totalCookingTimeInMinutes > context.maximumCookingTime.rawValue {
            return .excluded(.cookingTimeExceedsLimit)
        }

        if recipe.difficulty > context.maximumDifficulty {
            return .excluded(.difficultyExceedsLimit)
        }

        var matchedIngredientCount = 0
        var missingIngredients: [String] = []
        var substitutions: [IngredientSubstitution] = []
        var usesUrgentIngredient = false
        var substitutedMinorIngredient = false

        for requirement in recipe.ingredientRequirements {
            let directIngredient = pantry.first {
                normalise($0.name) == normalise(requirement.ingredientName)
            }

            if let directIngredient {
                matchedIngredientCount += 1

                if directIngredient.isExpiringSoon(on: today) {
                    usesUrgentIngredient = true
                }

                continue
            }

            if let substitutionCategory = requirement.substitutionCategory,
               let substitute = pantry.first(where: {
                   $0.substitutionCategory == substitutionCategory
               }) {
                matchedIngredientCount += 1

                substitutions.append(
                    IngredientSubstitution(
                        requiredIngredient: requirement.ingredientName,
                        availableIngredient: substitute.name,
                        category: substitutionCategory
                    )
                )

                if substitute.isExpiringSoon(on: today) {
                    usesUrgentIngredient = true
                }

                if !requirement.isEssential {
                    substitutedMinorIngredient = true
                }

                continue
            }

            if requirement.isEssential {
                return .excluded(.essentialIngredientUnavailable)
            }

            missingIngredients.append(requirement.ingredientName)
        }

        if missingIngredients.count > 2 {
            return .excluded(.requiresMoreThanTwoIngredients)
        }

        let readiness: RecipeReadiness

        if substitutedMinorIngredient {
            readiness = .almostReady
        } else if missingIngredients.isEmpty {
            readiness = .readyToCook
        } else {
            readiness = .needsOneToTwoIngredients
        }

        let pantryMatchPercentage = calculatePantryMatch(
            matchedIngredientCount: matchedIngredientCount,
            totalIngredientCount: recipe.ingredientRequirements.count
        )

        let explanation = createExplanation(
            recipe: recipe,
            readiness: readiness,
            missingIngredients: missingIngredients,
            substitutions: substitutions,
            usesUrgentIngredient: usesUrgentIngredient
        )

        return .suitable(
            RecipeSuitability(
                recipe: recipe,
                readiness: readiness,
                pantryMatchPercentage: pantryMatchPercentage,
                missingIngredients: missingIngredients,
                substitutions: substitutions,
                usesUrgentIngredient: usesUrgentIngredient,
                explanation: explanation
            )
        )
    }

    private func normalise(_ ingredientName: String) -> String {
        ingredientName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func calculatePantryMatch(
        matchedIngredientCount: Int,
        totalIngredientCount: Int
    ) -> Int {
        guard totalIngredientCount > 0 else {
            return 0
        }

        return Int(
            (Double(matchedIngredientCount) / Double(totalIngredientCount)) * 100
        )
    }

    private func createExplanation(
        recipe: Recipe,
        readiness: RecipeReadiness,
        missingIngredients: [String],
        substitutions: [IngredientSubstitution],
        usesUrgentIngredient: Bool
    ) -> String {
        var reasons: [String] = []

        switch readiness {
        case .readyToCook:
            reasons.append("You have the essential ingredients")

        case .almostReady:
            reasons.append("A minor ingredient can be substituted")

        case .needsOneToTwoIngredients:
            reasons.append("You only need \(missingIngredients.count) more ingredient(s)")
        }

        if usesUrgentIngredient {
            reasons.append("it uses an ingredient expiring soon")
        }

        if !substitutions.isEmpty {
            reasons.append("an available substitution keeps it practical")
        }

        return reasons.joined(separator: " and ").capitalized + "."
    }
}
