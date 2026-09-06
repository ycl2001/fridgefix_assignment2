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
    /// - Parameter session: Optional active session feedback used to hide skipped
    /// recipes and adjust ordering during the current recommendation flow.
    /// - Returns: Suitable recipes ordered from highest to lowest priority.
    /// - Throws: `RecommendationGenerationError` when required data is unavailable
    /// or no recipe meets the user's hard constraints.
    func execute(
        context: CookingContext,
        session: RecommendationSession? = nil
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

        let recipesByID = Dictionary(
            uniqueKeysWithValues: recipes.map {
                ($0.id, $0)
            }
        )
        let sessionInfluence = SessionRecommendationInfluence(
            session: session,
            recipesByID: recipesByID
        )
        var recommendations: [RecipeRecommendation] = []

        for recipe in recipes {
            guard !sessionInfluence.excludes(recipe) else {
                continue
            }

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
                context: context,
                sessionInfluence: sessionInfluence
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
        context: CookingContext,
        sessionInfluence: SessionRecommendationInfluence
    ) -> Bool {
        let firstSuitability = first.suitability
        let secondSuitability = second.suitability

        let firstFeedbackRank = sessionInfluence.rank(
            firstSuitability
        )
        let secondFeedbackRank = sessionInfluence.rank(
            secondSuitability
        )

        if firstFeedbackRank != secondFeedbackRank {
            return firstFeedbackRank > secondFeedbackRank
        }

        if sessionInfluence.prefersShorterRecipes,
           firstSuitability.recipe.totalCookingTimeInMinutes !=
            secondSuitability.recipe.totalCookingTimeInMinutes {
            return firstSuitability.recipe.totalCookingTimeInMinutes <
                secondSuitability.recipe.totalCookingTimeInMinutes
        }

        if sessionInfluence.prefersEasierRecipes,
           firstSuitability.recipe.difficulty !=
            secondSuitability.recipe.difficulty {
            return firstSuitability.recipe.difficulty <
                secondSuitability.recipe.difficulty
        }

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

/// Captures deterministic, session-only effects from prior recipe feedback.
private struct SessionRecommendationInfluence {

    private let skippedRecipeIDs: Set<RecipeID>
    private let promotedCuisines: Set<Cuisine>
    private let promotedTastes: Set<TastePreference>
    private let deprioritisedCuisines: Set<Cuisine>
    private let deprioritisedTastes: Set<TastePreference>
    private let deprioritisesShopping: Bool
    private let difficultRecipeThreshold: CookingDifficulty?

    let prefersShorterRecipes: Bool
    let prefersEasierRecipes: Bool

    init(
        session: RecommendationSession?,
        recipesByID: [RecipeID: Recipe]
    ) {
        guard let session, session.isActive else {
            skippedRecipeIDs = []
            promotedCuisines = []
            promotedTastes = []
            deprioritisedCuisines = []
            deprioritisedTastes = []
            deprioritisesShopping = false
            difficultRecipeThreshold = nil
            prefersShorterRecipes = false
            prefersEasierRecipes = false
            return
        }

        var skippedRecipeIDs: Set<RecipeID> = []
        var promotedCuisines: Set<Cuisine> = []
        var promotedTastes: Set<TastePreference> = []
        var deprioritisedCuisines: Set<Cuisine> = []
        var deprioritisedTastes: Set<TastePreference> = []
        var deprioritisesShopping = false
        var difficultRecipeThreshold: CookingDifficulty?
        var prefersShorterRecipes = false
        var prefersEasierRecipes = false

        for (recipeID, action) in session.recordedFeedback {
            let recipe = recipesByID[recipeID]

            switch action {
            case .saved:
                if let recipe {
                    promotedCuisines.insert(recipe.cuisine)
                    promotedTastes.formUnion(recipe.tastePreferences)
                }

            case .skipped:
                skippedRecipeIDs.insert(recipeID)

            case .reported(let reason):
                switch reason {
                case .tooMuchShopping:
                    deprioritisesShopping = true

                case .takesTooLong:
                    prefersShorterRecipes = true

                case .tooDifficult:
                    prefersEasierRecipes = true

                    if let recipe {
                        difficultRecipeThreshold = min(
                            difficultRecipeThreshold ?? recipe.difficulty,
                            recipe.difficulty
                        )
                    }

                case .notMyTaste:
                    if let recipe {
                        deprioritisedCuisines.insert(recipe.cuisine)
                        deprioritisedTastes.formUnion(
                            recipe.tastePreferences
                        )
                    }
                }
            }
        }

        self.skippedRecipeIDs = skippedRecipeIDs
        self.promotedCuisines = promotedCuisines
        self.promotedTastes = promotedTastes
        self.deprioritisedCuisines = deprioritisedCuisines
        self.deprioritisedTastes = deprioritisedTastes
        self.deprioritisesShopping = deprioritisesShopping
        self.difficultRecipeThreshold = difficultRecipeThreshold
        self.prefersShorterRecipes = prefersShorterRecipes
        self.prefersEasierRecipes = prefersEasierRecipes
    }

    /// Returns true when session feedback should hide the recipe.
    func excludes(_ recipe: Recipe) -> Bool {
        skippedRecipeIDs.contains(recipe.id)
    }

    /// Returns a deterministic feedback rank for a suitable recipe.
    ///
    /// Higher values appear earlier. Negative feedback wins over saved
    /// similarity so current-session rejection remains visible in the ranking.
    func rank(_ suitability: RecipeSuitability) -> Int {
        if isDeprioritised(suitability) {
            return 0
        }

        if isPromoted(suitability.recipe) {
            return 2
        }

        return 1
    }

    private func isPromoted(_ recipe: Recipe) -> Bool {
        promotedCuisines.contains(recipe.cuisine) ||
        !promotedTastes.isDisjoint(with: recipe.tastePreferences)
    }

    private func isDeprioritised(
        _ suitability: RecipeSuitability
    ) -> Bool {
        if deprioritisesShopping &&
            suitability.readiness == .needsOneToTwoIngredients {
            return true
        }

        if let difficultRecipeThreshold,
           suitability.recipe.difficulty >= difficultRecipeThreshold {
            return true
        }

        if deprioritisedCuisines.contains(suitability.recipe.cuisine) ||
            !deprioritisedTastes.isDisjoint(
                with: suitability.recipe.tastePreferences
            ) {
            return true
        }

        return false
    }
}

/// Describes failures that prevent FridgeFix from generating recommendations.

enum RecommendationGenerationError: Error {
    case pantryInformationUnavailable
    case pantryNeedsIngredients
    case recipeCatalogueUnavailable
    case noRecipesMeetCookingContext
}
