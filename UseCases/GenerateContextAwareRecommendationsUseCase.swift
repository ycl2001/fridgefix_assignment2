//
//  GenerateContextAwareRecommendationsUseCase.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import Foundation

/// Generates explainable meal recommendations for the user's current situation.
///
/// This Use Case retrieves pantry and recipe information, evaluates each recipe,
/// removes unsuitable recipes, and orders the remaining recipes according to
/// FridgeFix's domain rules.
struct GenerateContextAwareRecommendationsUseCase {

    let recipeRepository: any RecipeRepository
    let pantryRepository: any PantryRepository
    let suitabilityEvaluator: EvaluateRecipeSuitabilityUseCase

    init(
        recipeRepository: any RecipeRepository,
        pantryRepository: any PantryRepository,
        suitabilityEvaluator: EvaluateRecipeSuitabilityUseCase =
            EvaluateRecipeSuitabilityUseCase()
    ) {
        self.recipeRepository = recipeRepository
        self.pantryRepository = pantryRepository
        self.suitabilityEvaluator = suitabilityEvaluator
    }

    /// Generates ranked recommendations for the supplied cooking context.
    ///
    /// - Parameter context: The user's current cooking limits and preferences.
    /// - Returns: Suitable recipes ordered from highest to lowest priority.
    /// - Throws: `RecommendationGenerationError` when required data is unavailable
    /// or no recipe meets the user's hard constraints.
    func execute(
        context: CookingContext
    ) throws -> [RecipeRecommendation] {

        let pantry: [PantryIngredient]

        do {
            pantry = try pantryRepository.fetchPantryIngredients()
        } catch {
            throw RecommendationGenerationError.pantryInformationUnavailable
        }

        guard !pantry.isEmpty else {
            throw RecommendationGenerationError.pantryNeedsIngredients
        }

        let recipes: [Recipe]

        do {
            recipes = try recipeRepository.fetchRecipes()
        } catch {
            throw RecommendationGenerationError.recipeCatalogueUnavailable
        }

        var recommendations: [RecipeRecommendation] = []

        for recipe in recipes {
            let outcome = suitabilityEvaluator.execute(
                recipe: recipe,
                pantry: pantry,
                context: context
            )

            guard case .suitable(let suitability) = outcome else {
                continue
            }

            recommendations.append(
                RecipeRecommendation(
                    suitability: suitability,
                    rankingReasons: rankingReasons(
                        for: suitability,
                        context: context
                    )
                )
            )
        }

        guard !recommendations.isEmpty else {
            throw RecommendationGenerationError.noRecipesMeetCookingContext
        }

        return recommendations.sorted {
            isHigherPriority(
                $0,
                than: $1,
                context: context
            )
        }
    }

    private func rankingReasons(
        for suitability: RecipeSuitability,
        context: CookingContext
    ) -> [RecommendationReason] {
        var reasons: [RecommendationReason] = []

        if suitability.readiness == .readyToCook {
            reasons.append(.readyToCook)
        }

        if context.prioritisesExpiringIngredients &&
            suitability.usesUrgentIngredient {
            reasons.append(.usesIngredientExpiringSoon)
        }

        if suitability.missingIngredients.count <= 1 {
            reasons.append(.minimalShopping)
        }

        if context.preferredCuisines.contains(
            suitability.recipe.cuisine
        ) {
            reasons.append(.matchesCuisinePreference)
        }

        if !context.preferredTastes.isDisjoint(
            with: suitability.recipe.tastePreferences
        ) {
            reasons.append(.matchesTastePreference)
        }

        if suitability.recipe.nutritionBalance == .balanced {
            reasons.append(.balancedNutrition)
        }

        if suitability.pantryMatchPercentage >= 80 {
            reasons.append(.strongPantryMatch)
        }

        return reasons
    }

    private func isHigherPriority(
        _ first: RecipeRecommendation,
        than second: RecipeRecommendation,
        context: CookingContext
    ) -> Bool {
        let firstSuitability = first.suitability
        let secondSuitability = second.suitability

        // A minimally inconvenient urgent recipe may beat a ready recipe.
        if context.prioritisesExpiringIngredients {
            if firstSuitability.readiness == .almostReady &&
                firstSuitability.usesUrgentIngredient &&
                secondSuitability.readiness == .readyToCook &&
                !secondSuitability.usesUrgentIngredient {
                return true
            }

            if secondSuitability.readiness == .almostReady &&
                secondSuitability.usesUrgentIngredient &&
                firstSuitability.readiness == .readyToCook &&
                !firstSuitability.usesUrgentIngredient {
                return false
            }

            if firstSuitability.usesUrgentIngredient !=
                secondSuitability.usesUrgentIngredient {
                return firstSuitability.usesUrgentIngredient
            }
        }

        let firstReadiness = readinessRank(firstSuitability.readiness)
        let secondReadiness = readinessRank(secondSuitability.readiness)

        if firstReadiness != secondReadiness {
            return firstReadiness > secondReadiness
        }

        if firstSuitability.missingIngredients.count !=
            secondSuitability.missingIngredients.count {
            return firstSuitability.missingIngredients.count <
                secondSuitability.missingIngredients.count
        }

        let firstCuisineMatch = context.preferredCuisines.contains(
            firstSuitability.recipe.cuisine
        )

        let secondCuisineMatch = context.preferredCuisines.contains(
            secondSuitability.recipe.cuisine
        )

        if firstCuisineMatch != secondCuisineMatch {
            return firstCuisineMatch
        }

        let firstTasteMatch = !context.preferredTastes.isDisjoint(
            with: firstSuitability.recipe.tastePreferences
        )

        let secondTasteMatch = !context.preferredTastes.isDisjoint(
            with: secondSuitability.recipe.tastePreferences
        )

        if firstTasteMatch != secondTasteMatch {
            return firstTasteMatch
        }

        if firstSuitability.recipe.totalCookingTimeInMinutes !=
            secondSuitability.recipe.totalCookingTimeInMinutes {
            return firstSuitability.recipe.totalCookingTimeInMinutes <
                secondSuitability.recipe.totalCookingTimeInMinutes
        }

        if firstSuitability.recipe.nutritionBalance !=
            secondSuitability.recipe.nutritionBalance {
            return nutritionRank(
                firstSuitability.recipe.nutritionBalance
            ) > nutritionRank(
                secondSuitability.recipe.nutritionBalance
            )
        }

        return firstSuitability.pantryMatchPercentage >
            secondSuitability.pantryMatchPercentage
    }

    private func readinessRank(
        _ readiness: RecipeReadiness
    ) -> Int {
        switch readiness {
        case .readyToCook:
            return 3
        case .almostReady:
            return 2
        case .needsOneToTwoIngredients:
            return 1
        }
    }

    private func nutritionRank(
        _ nutritionBalance: NutritionBalance
    ) -> Int {
        switch nutritionBalance {
        case .balanced:
            return 3
        case .partlyBalanced:
            return 2
        case .limitedBalance:
            return 1
        }
    }
}

/// Describes failures that prevent FridgeFix from generating recommendations.

enum RecommendationGenerationError: Error {
    case pantryInformationUnavailable
    case pantryNeedsIngredients
    case recipeCatalogueUnavailable
    case noRecipesMeetCookingContext
}
